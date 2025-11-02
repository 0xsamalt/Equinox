// Core types shared between guest (zkVM) and host programs
// These types MUST be identical on both sides for serialization to work

use serde::{Deserialize, Serialize};

/// Represents a single reserve (asset) in the Aave protocol
/// Contains all data needed to calculate that asset's contribution to the safety score
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AaveReserveData {
    /// The token address (e.g., USDC, WETH, DAI)
    pub token_address: String,
    
    /// Total amount supplied by users (in token's native decimals)
    /// This is the balance of the aToken (e.g., aUSDC)
    pub total_atoken: u128,
    
    /// Total amount borrowed at stable interest rate (in token's native decimals)
    pub total_stable_debt: u128,
    
    /// Total amount borrowed at variable interest rate (in token's native decimals)
    pub total_variable_debt: u128,
    
    /// Price of the asset in USD, scaled by 1e8
    /// Example: If 1 WETH = $2000, this would be 200000000000 (2000 * 1e8)
    pub price_usd: u128,
    
    /// Number of decimals for this token (e.g., 6 for USDC, 18 for WETH)
    pub decimals: u8,
}

/// Input structure sent from host to guest
/// This is what gets serialized and passed into the zkVM
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AaveInput {
    /// Vector of all reserves to analyze
    pub reserves: Vec<AaveReserveData>,
    
    /// Protocol identifier (for logging/debugging)
    pub protocol_name: String,
    
    /// Timestamp of data snapshot (for auditing)
    pub timestamp: u64,
}

/// Output structure committed to the zkVM journal
/// This is the PUBLIC output that goes on-chain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SafetyScoreOutput {
    /// The calculated safety score (scaled by 1e4)
    /// Example: 98.5% = 985000 (98.5 * 1e4)
    /// Range: 0 to 1000000 (0% to 100%)
    pub safety_score: u64,
    
    /// Total assets in USD (scaled by 1e8)
    pub total_assets_usd: u128,
    
    /// Total liabilities in USD (scaled by 1e8)
    pub total_liabilities_usd: u128,
    
    /// Timestamp when this was calculated
    pub timestamp: u64,
}

impl SafetyScoreOutput {
    /// Helper to create a new output
    pub fn new(
        safety_score: u64,
        total_assets_usd: u128,
        total_liabilities_usd: u128,
        timestamp: u64,
    ) -> Self {
        Self {
            safety_score,
            total_assets_usd,
            total_liabilities_usd,
            timestamp,
        }
    }
    
    /// Convert safety score to human-readable percentage
    /// Example: 985000 -> 98.50%
    pub fn to_percentage(&self) -> f64 {
        self.safety_score as f64 / 10000.0
    }
}

/// Helper function to normalize token amounts to USD
/// Handles different token decimals properly
pub fn normalize_amount(amount: u128, decimals: u8, price_usd: u128) -> u128 {
    // amount is in token's native decimals
    // price_usd is scaled by 1e8
    // We want to return USD value scaled by 1e8
    
    // Convert amount to 18 decimals first for precision
    let amount_normalized = if decimals < 18 {
        amount * 10u128.pow((18 - decimals) as u32)
    } else if decimals > 18 {
        amount / 10u128.pow((decimals - 18) as u32)
    } else {
        amount
    };
    
    // Multiply by price (which is already in 1e8 scale)
    // Result should be in 1e8 scale
    // amount_normalized is 1e18, price is 1e8, so result is 1e26
    // We need to divide by 1e18 to get back to 1e8 scale
    (amount_normalized * price_usd) / 10u128.pow(18)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_amount() {
        // Test USDC (6 decimals) at $1
        // 1000 USDC = 1000 * 1e6 = 1_000_000_000
        // Price = $1 = 1e8 = 100_000_000
        let usdc_amount = 1_000_000_000u128; // 1000 USDC
        let usdc_price = 100_000_000u128; // $1
        let result = normalize_amount(usdc_amount, 6, usdc_price);
        assert_eq!(result, 100_000_000_000u128); // $1000 in 1e8 scale

        // Test WETH (18 decimals) at $2000
        // 1 WETH = 1e18
        // Price = $2000 = 2000 * 1e8 = 200_000_000_000
        let weth_amount = 1_000_000_000_000_000_000u128; // 1 WETH
        let weth_price = 200_000_000_000u128; // $2000
        let result = normalize_amount(weth_amount, 18, weth_price);
        assert_eq!(result, 200_000_000_000u128); // $2000 in 1e8 scale
    }

    #[test]
    fn test_safety_score_percentage() {
        let output = SafetyScoreOutput::new(
            985000, // 98.5%
            1_000_000_000_000u128,
            900_000_000_000u128,
            1234567890,
        );
        
        assert_eq!(output.to_percentage(), 98.5);
    }
}
