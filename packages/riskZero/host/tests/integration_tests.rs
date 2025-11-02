// Integration tests for the DeRisk Oracle system

use derisk_type::{AaveInput, AaveReserveData, SafetyScoreOutput};
use methods::{AAVE_ELF, AAVE_ID};
use risc0_zkvm::{default_prover, ExecutorEnv};

/// Test the guest program with mock data
#[test]
fn test_guest_with_mock_data() {
    // Create mock Aave data
    let mock_input = create_mock_aave_input();

    // Build executor environment
    let env = ExecutorEnv::builder()
        .write(&mock_input)
        .expect("Failed to write input")
        .build()
        .expect("Failed to build env");

    // Execute guest program
    let prover = default_prover();
    let prove_info = prover
        .prove(env, AAVE_ELF)
        .expect("Failed to prove");

    // Decode output
    let output: SafetyScoreOutput = prove_info.receipt.journal
        .decode()
        .expect("Failed to decode output");

    // Verify the calculation
    println!("Safety Score: {:.2}%", output.to_percentage());
    println!("Total Assets: ${}", output.total_assets_usd as f64 / 1e8);
    println!("Total Liabilities: ${}", output.total_liabilities_usd as f64 / 1e8);

    // Basic sanity checks
    assert!(output.safety_score > 0, "Safety score should be positive");
    assert!(output.safety_score <= 1_000_000, "Safety score should be <= 100%");
    assert!(output.total_assets_usd >= output.total_liabilities_usd, 
        "Assets should be >= liabilities for a healthy protocol");
}

/// Test with edge case: empty reserves
#[test]
fn test_empty_reserves() {
    let input = AaveInput {
        reserves: vec![],
        protocol_name: "Empty Test".to_string(),
        timestamp: 1234567890,
    };

    let env = ExecutorEnv::builder()
        .write(&input)
        .expect("Failed to write input")
        .build()
        .expect("Failed to build env");

    let prover = default_prover();
    let prove_info = prover
        .prove(env, AAVE_ELF)
        .expect("Failed to prove");

    let output: SafetyScoreOutput = prove_info.receipt.journal
        .decode()
        .expect("Failed to decode output");

    // With no reserves, safety score should be 0 or 100% (implementation dependent)
    assert_eq!(output.total_assets_usd, 0);
    assert_eq!(output.total_liabilities_usd, 0);
}

/// Test with insolvent protocol (liabilities > assets)
#[test]
fn test_insolvent_protocol() {
    let reserves = vec![
        AaveReserveData {
            token_address: "0xUSDC".to_string(),
            total_atoken: 1_000_000_000_000,      // $1,000 supplied
            total_stable_debt: 800_000_000_000,   // $800 borrowed stable
            total_variable_debt: 400_000_000_000, // $400 borrowed variable
            price_usd: 100_000_000,                // $1.00
            decimals: 6,
        },
    ];

    let input = AaveInput {
        reserves,
        protocol_name: "Insolvent Test".to_string(),
        timestamp: 1234567890,
    };

    let env = ExecutorEnv::builder()
        .write(&input)
        .expect("Failed to write input")
        .build()
        .expect("Failed to build env");

    let prover = default_prover();
    let prove_info = prover
        .prove(env, AAVE_ELF)
        .expect("Failed to prove");

    let output: SafetyScoreOutput = prove_info.receipt.journal
        .decode()
        .expect("Failed to decode output");

    println!("Insolvent protocol safety score: {:.2}%", output.to_percentage());
    
    // Safety score should be 0 for insolvent protocol
    assert_eq!(output.safety_score, 0);
}

/// Test with multiple reserves of different decimals
#[test]
fn test_multiple_reserves_different_decimals() {
    let reserves = vec![
        // USDC (6 decimals)
        AaveReserveData {
            token_address: "0xUSDC".to_string(),
            total_atoken: 1_000_000_000_000,      // 1,000,000 USDC
            total_stable_debt: 500_000_000_000,   // 500,000 USDC
            total_variable_debt: 200_000_000_000, // 200,000 USDC
            price_usd: 100_000_000,                // $1.00
            decimals: 6,
        },
        // WETH (18 decimals)
        AaveReserveData {
            token_address: "0xWETH".to_string(),
            total_atoken: 1_000_000_000_000_000_000, // 1 WETH
            total_stable_debt: 500_000_000_000_000_000, // 0.5 WETH
            total_variable_debt: 0,
            price_usd: 200_000_000_000,            // $2000.00
            decimals: 18,
        },
        // DAI (18 decimals)
        AaveReserveData {
            token_address: "0xDAI".to_string(),
            total_atoken: 500_000_000_000_000_000_000, // 500 DAI
            total_stable_debt: 100_000_000_000_000_000_000, // 100 DAI
            total_variable_debt: 50_000_000_000_000_000_000, // 50 DAI
            price_usd: 100_000_000,                // $1.00
            decimals: 18,
        },
    ];

    let input = AaveInput {
        reserves,
        protocol_name: "Multi-Reserve Test".to_string(),
        timestamp: 1234567890,
    };

    let env = ExecutorEnv::builder()
        .write(&input)
        .expect("Failed to write input")
        .build()
        .expect("Failed to build env");

    let prover = default_prover();
    let prove_info = prover
        .prove(env, AAVE_ELF)
        .expect("Failed to prove");

    let output: SafetyScoreOutput = prove_info.receipt.journal
        .decode()
        .expect("Failed to decode output");

    println!("\n=== Multi-Reserve Test Results ===");
    println!("Safety Score: {:.4}%", output.to_percentage());
    println!("Total Assets: ${:.2}", output.total_assets_usd as f64 / 1e8);
    println!("Total Liabilities: ${:.2}", output.total_liabilities_usd as f64 / 1e8);
    
    // Expected calculation:
    // USDC: Assets = $1M, Liabilities = $700K
    // WETH: Assets = $2000, Liabilities = $1000
    // DAI: Assets = $500, Liabilities = $150
    // Total Assets = $1,002,500
    // Total Liabilities = $701,150
    // Safety Score = (301,350 / 1,002,500) * 100 = ~30.05%

    assert!(output.safety_score > 0);
    assert!(output.total_assets_usd > output.total_liabilities_usd);
}

/// Helper function to create mock Aave input data
fn create_mock_aave_input() -> AaveInput {
    let reserves = vec![
        // USDC reserve
        AaveReserveData {
            token_address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48".to_string(),
            total_atoken: 100_000_000_000_000,    // 100M USDC (6 decimals)
            total_stable_debt: 20_000_000_000_000, // 20M USDC
            total_variable_debt: 30_000_000_000_000, // 30M USDC
            price_usd: 100_000_000,                 // $1.00 (scaled by 1e8)
            decimals: 6,
        },
        // WETH reserve
        AaveReserveData {
            token_address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2".to_string(),
            total_atoken: 50_000_000_000_000_000_000_000, // 50,000 WETH (18 decimals)
            total_stable_debt: 10_000_000_000_000_000_000_000, // 10,000 WETH
            total_variable_debt: 15_000_000_000_000_000_000_000, // 15,000 WETH
            price_usd: 200_000_000_000,             // $2000.00 (scaled by 1e8)
            decimals: 18,
        },
        // DAI reserve
        AaveReserveData {
            token_address: "0x6B175474E89094C44Da98b954EedeAC495271d0F".to_string(),
            total_atoken: 80_000_000_000_000_000_000_000_000, // 80M DAI (18 decimals)
            total_stable_debt: 30_000_000_000_000_000_000_000_000, // 30M DAI
            total_variable_debt: 20_000_000_000_000_000_000_000_000, // 20M DAI
            price_usd: 100_000_000,                 // $1.00 (scaled by 1e8)
            decimals: 18,
        },
    ];

    AaveInput {
        reserves,
        protocol_name: "Aave V3 Mock".to_string(),
        timestamp: 1234567890,
    }
}

/// Test Image ID is correctly generated
#[test]
fn test_image_id_exists() {
    println!("Aave Guest Image ID: {:?}", AAVE_ID);
    assert_eq!(AAVE_ID.len(), 8, "Image ID should be 8 u32 values");
}

/// Test serialization/deserialization of types
#[test]
fn test_serialization() {
    let input = create_mock_aave_input();
    
    // Serialize
    let serialized = serde_json::to_string(&input)
        .expect("Failed to serialize");
    
    // Deserialize
    let deserialized: AaveInput = serde_json::from_str(&serialized)
        .expect("Failed to deserialize");
    
    assert_eq!(input.reserves.len(), deserialized.reserves.len());
    assert_eq!(input.protocol_name, deserialized.protocol_name);
    assert_eq!(input.timestamp, deserialized.timestamp);
}
