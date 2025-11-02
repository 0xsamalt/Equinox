// DeRisk Oracle - Host Program
// This orchestrates the entire zkVM workflow:
// 1. Fetch Aave data from blockchain
// 2. Execute guest program in zkVM to compute safety score
// 3. Extract proof and journal
// 4. Submit to on-chain oracle (future)

mod aave_fetcher;
mod oracle_submitter;

use aave_fetcher::{AaveFetcher, AaveAddresses};
use oracle_submitter::OracleSubmitter;
use methods::{AAVE_ELF, AAVE_ID};
use risc0_zkvm::{default_prover, ExecutorEnv};
use risc0_groth16::{Prover as Groth16Prover, ProverOpts};
use derisk_type::SafetyScoreOutput;
use clap::Parser;
use eyre::Result;

/// DeRisk Oracle CLI
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Network to use (mainnet, sepolia)
    #[arg(short, long, default_value = "mainnet")]
    network: String,

    /// RPC endpoint URL
    #[arg(short, long, default_value = "https://eth.llamarpc.com")]
    rpc_url: String,

    /// Mode: fetch-only, prove-only, or full
    #[arg(short, long, default_value = "full")]
    mode: String,

    /// Input file (for prove-only mode)
    #[arg(short, long)]
    input_file: Option<String>,

    /// Output directory for proof artifacts
    #[arg(short, long, default_value = "./output")]
    output_dir: String,

    /// Submit proof to on-chain oracle
    #[arg(long, default_value = "false")]
    submit: bool,

    /// Private key for on-chain submission
    #[arg(long)]
    private_key: Option<String>,

    /// DeRiskOracle contract address
    #[arg(long)]
    oracle_address: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::filter::EnvFilter::from_default_env())
        .init();

    // Load environment variables from .env file
    dotenv::dotenv().ok();

    // Parse CLI arguments
    let args = Args::parse();

    println!("╔════════════════════════════════════════╗");
    println!("║   DeRisk Protocol - ZK Oracle Host    ║");
    println!("╚════════════════════════════════════════╝\n");

    // Determine network addresses
    let aave_addresses = match args.network.as_str() {
        "mainnet" => AaveAddresses::mainnet(),
        "sepolia" => AaveAddresses::sepolia(),
        _ => {
            eprintln!("Error: Unknown network '{}'. Use 'mainnet' or 'sepolia'", args.network);
            std::process::exit(1);
        }
    };

    println!("Network: {}", args.network);
    println!("RPC URL: {}", args.rpc_url);
    println!("Mode: {}\n", args.mode);

    // ========================================================================
    // STEP 1: Fetch Aave Data (or load from file)
    // ========================================================================
    let aave_input = if args.mode == "prove-only" {
        // Load from file
        let input_file = args.input_file.expect("--input-file required for prove-only mode");
        println!(" Loading data from file: {}", input_file);
        let json = std::fs::read_to_string(input_file)?;
        serde_json::from_str(&json)?
    } else {
        // Fetch from blockchain
        println!("═══════════════════════════════════════");
        println!("  STEP 1: Fetching Aave Reserve Data");
        println!("═══════════════════════════════════════\n");

        let fetcher = AaveFetcher::new(aave_addresses.clone(), args.rpc_url.clone());
        let input = fetcher.fetch_reserves().await?;

        // Save to file for future prove-only runs
        let output_path = format!("{}/aave_input.json", args.output_dir);
        std::fs::create_dir_all(&args.output_dir)?;
        std::fs::write(&output_path, serde_json::to_string_pretty(&input)?)?;
        println!("\n💾 Saved input data to: {}", output_path);

        if args.mode == "fetch-only" {
            println!("\n✓ Fetch complete. Exiting (fetch-only mode).");
            return Ok(());
        }

        input
    };

    println!("\n📊 Input Summary:");
    println!("  - Protocol: {}", aave_input.protocol_name);
    println!("  - Reserves: {}", aave_input.reserves.len());
    println!("  - Timestamp: {}", aave_input.timestamp);

    // ========================================================================
    // STEP 2: Execute Guest Program in zkVM
    // ========================================================================
    println!("\n═══════════════════════════════════════");
    println!("  STEP 2: Executing zkVM Guest Program");
    println!("═══════════════════════════════════════\n");

    println!("🔧 Building ExecutorEnv with input data...");
    let env = ExecutorEnv::builder()
        .write(&aave_input)
        .map_err(|e| eyre::eyre!("Failed to write input: {}", e))?
        .build()
        .map_err(|e| eyre::eyre!("Failed to build env: {}", e))?;

    println!("✓ ExecutorEnv ready");
    println!("\n🚀 Starting zkVM execution with Groth16...");
    println!("⏳ This will take 5-10 minutes for Groth16 proving (grab a coffee ☕)...\n");

    let prover = default_prover();
    
    // Step 1: Generate STARK proof first
    println!("📝 Step 1/2: Generating STARK proof...");
    let prove_info = prover
        .prove(env, AAVE_ELF)
        .map_err(|e| eyre::eyre!("Failed to prove: {}", e))?;

    println!("✓ STARK proof complete!");
    println!("  - Cycles: {}", prove_info.stats.total_cycles);
    println!("  - Segments: {}", prove_info.stats.segments);
    
    // Step 2: Convert to Groth16
    println!("\n📝 Step 2/2: Converting to Groth16 (this is the slow part)...");
    let stark_receipt = prove_info.receipt;
    
    let groth16_prover = Groth16Prover::new();
    let receipt = groth16_prover
        .prove(&stark_receipt)
        .map_err(|e| eyre::eyre!("Failed to convert to Groth16: {}", e))?;

    println!("✅ Groth16 conversion complete!");

    // ========================================================================
    // STEP 3: Extract Proof and Journal
    // ========================================================================
    println!("\n═══════════════════════════════════════");
    println!("  STEP 3: Extracting Proof & Journal");
    println!("═══════════════════════════════════════\n");

    // Decode the journal to get the SafetyScoreOutput
    let output: SafetyScoreOutput = receipt.journal.decode()?;

    println!("📊 Safety Score Result:");
    println!("  - Safety Score: {:.4}%", output.to_percentage());
    println!("  - Total Assets: ${:.2}", output.total_assets_usd as f64 / 1e8);
    println!("  - Total Liabilities: ${:.2}", output.total_liabilities_usd as f64 / 1e8);
    println!("  - Buffer: ${:.2}", 
        (output.total_assets_usd - output.total_liabilities_usd) as f64 / 1e8);

    // Extract the Groth16 seal and journal
    let journal_bytes = receipt.journal.bytes.clone();
    
    // Extract the Groth16 seal from the receipt's inner structure
    // Groth16 seals are MUCH smaller than STARK seals (~300-400 bytes vs ~250KB!)
    let seal_bytes = bincode::serialize(&receipt.inner)
        .map_err(|e| eyre::eyre!("Failed to serialize Groth16 seal: {}", e))?;
    
    // Also save the full receipt for reference
    let receipt_bytes = bincode::serialize(&receipt)?;

    println!("\n🔐 Groth16 Proof Artifacts:");
    println!("  - Proof type: Groth16 ✨");
    println!("  - Journal size: {} bytes", journal_bytes.len());
    println!("  - Groth16 Seal size: {} bytes ({:.2} KB)", seal_bytes.len(), seal_bytes.len() as f64 / 1024.0);
    println!("  - Receipt size: {} bytes", receipt_bytes.len());
    println!("  - Reduction: {}x smaller than STARK!", 250_000 / seal_bytes.len().max(1));
    println!("  - Image ID: {:?}", AAVE_ID);
    
    // Sanity check - Groth16 seals should be small
    if seal_bytes.len() > 10_000 {
        println!("\n⚠️  Warning: Seal larger than expected for Groth16 ({} bytes)", seal_bytes.len());
        println!("    Expected: 200-1000 bytes. Got: {}", seal_bytes.len());
    } else {
        println!("\n✅ Seal size looks good for Groth16!");
    }

    // Save artifacts
    let journal_path = format!("{}/proof_journal.bin", args.output_dir);
    let seal_path = format!("{}/proof_seal.bin", args.output_dir);
    let receipt_path = format!("{}/proof_receipt.bin", args.output_dir);
    let output_path = format!("{}/safety_score_output.json", args.output_dir);

    std::fs::write(&journal_path, &journal_bytes)?;
    std::fs::write(&seal_path, &seal_bytes)?;
    std::fs::write(&receipt_path, &receipt_bytes)?;
    std::fs::write(&output_path, serde_json::to_string_pretty(&output)?)?;

    println!("\n💾 Saved proof artifacts:");
    println!("  - Journal: {}", journal_path);
    println!("  - Seal: {}", seal_path);
    println!("  - Receipt: {}", receipt_path);
    println!("  - Output: {}", output_path);

    // ========================================================================
    // STEP 4: Submit to On-Chain Oracle (Optional)
    // ========================================================================
    if args.submit {
        println!("\n═══════════════════════════════════════");
        println!("  STEP 4: Submitting to On-Chain Oracle");
        println!("═══════════════════════════════════════\n");

        let private_key = args.private_key
            .expect("--private-key or PRIVATE_KEY env var required for submission");
        let oracle_address = args.oracle_address
            .expect("--oracle-address or ORACLE_ADDRESS env var required for submission");

        let submitter = OracleSubmitter::new(
            args.rpc_url,
            private_key,
            oracle_address.parse()?,
            aave_addresses.pool,
        );

        let tx_hash = submitter.submit_proof(journal_bytes, vec![]).await?;
        
        println!("\n✓ Proof submitted successfully!");
        println!("  - Transaction: {}", tx_hash);
    } else {
        println!("\n💡 To submit to on-chain oracle, run with --submit flag");
    }

    println!("\n╔════════════════════════════════════════╗");
    println!("║        ✓ All Steps Complete!          ║");
    println!("╚════════════════════════════════════════╝\n");

    Ok(())
}
