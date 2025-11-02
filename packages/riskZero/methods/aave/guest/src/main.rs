// Aave Safety Score Calculator - Guest Program
// This program runs inside the RISC Zero zkVM to compute Aave's safety score
// The computation is proven cryptographically, making it trustless

use risc0_zkvm::guest::env;
use derisk_type::{AaveInput, SafetyScoreOutput, normalize_amount};

fn main() {
    // ========================================================================
    // STEP 1: Read input data from the host
    // ========================================================================
    // The host has fetched all Aave reserve data and serialized it
    // We deserialize it here inside the zkVM
    let input: AaveInput = env::read();

    // Log basic info (visible in zkVM execution logs)
    eprintln!("=== Aave Safety Score Calculation ===");
    eprintln!("Protocol: {}", input.protocol_name);
    eprintln!("Number of reserves: {}", input.reserves.len());
    eprintln!("Timestamp: {}", input.timestamp);

    // ========================================================================
    // STEP 2: Calculate total assets and liabilities in USD
    // ========================================================================
    let mut total_assets_usd: u128 = 0;
    let mut total_liabilities_usd: u128 = 0;

    // Loop through each reserve (USDC, WETH, DAI, etc.)
    for (index, reserve) in input.reserves.iter().enumerate() {
        eprintln!("\n--- Reserve #{}: {} ---", index + 1, reserve.token_address);
        
        // Calculate asset value (total supplied by users)
        // Assets = aToken balance (what users have deposited)
        let asset_value_usd = normalize_amount(
            reserve.total_atoken,
            reserve.decimals,
            reserve.price_usd,
        );
        
        // Calculate liability value (total borrowed by users)
        // Liabilities = stable debt + variable debt
        let total_debt = reserve.total_stable_debt + reserve.total_variable_debt;
        let liability_value_usd = normalize_amount(
            total_debt,
            reserve.decimals,
            reserve.price_usd,
        );

        eprintln!("  Total aToken: {}", reserve.total_atoken);
        eprintln!("  Total Stable Debt: {}", reserve.total_stable_debt);
        eprintln!("  Total Variable Debt: {}", reserve.total_variable_debt);
        eprintln!("  Price (USD, 1e8): {}", reserve.price_usd);
        eprintln!("  Asset Value (USD, 1e8): {}", asset_value_usd);
        eprintln!("  Liability Value (USD, 1e8): {}", liability_value_usd);

        // Accumulate totals
        total_assets_usd += asset_value_usd;
        total_liabilities_usd += liability_value_usd;
    }

    eprintln!("\n=== Totals ===");
    eprintln!("Total Assets (USD, 1e8): {}", total_assets_usd);
    eprintln!("Total Liabilities (USD, 1e8): {}", total_liabilities_usd);

    // ========================================================================
    // STEP 3: Calculate the safety score
    // ========================================================================
    // Safety Score = (Buffer / Total Assets) * 100
    // Where Buffer = Total Assets - Total Liabilities
    //
    // This represents what percentage of assets are "safe" (not owed to borrowers)
    //
    // Examples:
    // - Score = 100% → No debt, fully safe
    // - Score = 95% → Protocol has 5% buffer
    // - Score = 0% → Protocol is insolvent (liabilities >= assets)

    let safety_score = if total_assets_usd == 0 {
        // Edge case: no assets = unsafe
        0u64
    } else if total_liabilities_usd >= total_assets_usd {
        // Insolvent: liabilities exceed assets
        0u64
    } else {
        // Normal case: calculate buffer percentage
        let buffer = total_assets_usd - total_liabilities_usd;
        
        // Scale to 1e4 for precision (e.g., 98.5% = 985000)
        // Formula: (buffer * 1e4 * 100) / total_assets
        // The 100 converts to percentage, 1e4 gives us 2 decimal places
        let score = (buffer * 1_000_000) / total_assets_usd;
        
        // Cap at 100% (1_000_000 in our scale)
        if score > 1_000_000 {
            1_000_000u64
        } else {
            score as u64
        }
    };

    eprintln!("\n=== Final Safety Score ===");
    eprintln!("Safety Score (scaled 1e4): {}", safety_score);
    eprintln!("Safety Score (percentage): {:.2}%", safety_score as f64 / 10_000.0);

    // ========================================================================
    // STEP 4: Commit the result to the public journal
    // ========================================================================
    // This is the ONLY data that becomes public and goes on-chain
    // The zkVM will generate a proof that this output was computed correctly
    let output = SafetyScoreOutput::new(
        safety_score,
        total_assets_usd,
        total_liabilities_usd,
        input.timestamp,
    );

    // Commit to journal - this is what the on-chain verifier will see
    env::commit(&output);

    eprintln!("\n✓ Safety score calculation complete!");
    eprintln!("✓ Output committed to journal");
}
