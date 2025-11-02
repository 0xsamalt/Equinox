// Oracle Submitter
// Handles submission of ZK proofs to the DeRiskOracle smart contract

use alloy::{
    providers::ProviderBuilder,
    primitives::{Address, Bytes, TxHash},
    sol,
    transports::http::reqwest::Url,
    signers::local::PrivateKeySigner,
    network::EthereumWallet,
};
use eyre::Result;

// Define DeRiskOracle contract interface
sol! {
    #[sol(rpc)]
    interface IDeRiskOracle {
        function updateScore(
            address protocol,
            bytes calldata journal,
            bytes calldata seal
        ) external;
        
        function safetyScores(address protocol) external view returns (uint256);
        
        event ScoreUpdated(address indexed protocol, uint256 newScore);
    }
}

/// Handles submission of proofs to the on-chain oracle
pub struct OracleSubmitter {
    rpc_url: String,
    private_key: String,
    oracle_address: Address,
    protocol_address: Address,
}

impl OracleSubmitter {
    pub fn new(
        rpc_url: String,
        private_key: String,
        oracle_address: Address,
        protocol_address: Address,
    ) -> Self {
        Self {
            rpc_url,
            private_key,
            oracle_address,
            protocol_address,
        }
    }

    /// Submit a proof to the DeRiskOracle contract
    pub async fn submit_proof(
        &self,
        journal: Vec<u8>,
        seal: Vec<u8>,
    ) -> Result<TxHash> {
        println!(" Connecting to RPC: {}", self.rpc_url);
        println!(" Oracle contract: {}", self.oracle_address);
        println!(" Protocol address: {}", self.protocol_address);

        // Create signer from private key
        let signer: PrivateKeySigner = self.private_key.parse()?;
        let wallet = EthereumWallet::from(signer);

        // Create provider with wallet
        let url = Url::parse(&self.rpc_url)?;
        let provider = ProviderBuilder::new()
            .with_recommended_fillers()
            .wallet(wallet)
            .on_http(url);

        // Create contract instance
        let oracle = IDeRiskOracle::new(self.oracle_address, &provider);

        println!("\n📤 Preparing transaction...");
        println!("  - Journal size: {} bytes", journal.len());
        println!("  - Seal size: {} bytes", seal.len());

        // Call updateScore
        let tx = oracle
            .updateScore(
                self.protocol_address,
                Bytes::from(journal),
                Bytes::from(seal),
            )
            .send()
            .await?;

        println!("⏳ Transaction sent, waiting for confirmation...");
        
        let receipt = tx.get_receipt().await?;
        let tx_hash = receipt.transaction_hash;

        println!("✓ Transaction confirmed!");
        println!("  - Block: {}", receipt.block_number.unwrap_or_default());
        println!("  - Gas used: {}", receipt.gas_used);

        Ok(tx_hash)
    }

    /// Read the current safety score from the oracle
    pub async fn get_current_score(&self) -> Result<u64> {
        let url = Url::parse(&self.rpc_url)?;
        let provider = ProviderBuilder::new().on_http(url);

        let oracle = IDeRiskOracle::new(self.oracle_address, &provider);
        
        let score = oracle.safetyScores(self.protocol_address).call().await?._0;
        
        Ok(score.try_into()?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore] // Run with: cargo test -- --ignored --nocapture
    async fn test_read_score() {
        // This test requires a deployed oracle contract
        let submitter = OracleSubmitter::new(
            std::env::var("ETH_RPC_URL").unwrap(),
            "0x0000000000000000000000000000000000000000000000000000000000000001".to_string(),
            "0x0000000000000000000000000000000000000000".parse().unwrap(),
            "0x0000000000000000000000000000000000000000".parse().unwrap(),
        );

        // This will fail if contract doesn't exist, but tests the interface
        let _ = submitter.get_current_score().await;
    }
}
