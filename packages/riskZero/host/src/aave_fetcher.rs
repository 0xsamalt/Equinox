// Aave Data Fetcher
// Connects to Ethereum RPC and fetches all reserve data from Aave Protocol

use alloy::{
    providers::ProviderBuilder,
    primitives::{Address, U256},
    sol,
    transports::http::reqwest::Url,
};
use derisk_type::{AaveInput, AaveReserveData};
use eyre::{Result, eyre};

// Define Aave Pool contract interface using Alloy's sol! macro
sol! {
    #[sol(rpc)]
    interface IAavePool {
        function getReservesList() external view returns (address[] memory);
        
        struct ReserveData {
            uint256 configuration;
            uint128 liquidityIndex;
            uint128 currentLiquidityRate;
            uint128 variableBorrowIndex;
            uint128 currentVariableBorrowRate;
            uint128 currentStableBorrowRate;
            uint40 lastUpdateTimestamp;
            uint16 id;
            address aTokenAddress;
            address stableDebtTokenAddress;
            address variableDebtTokenAddress;
            address interestRateStrategyAddress;
            uint128 accruedToTreasury;
            uint128 unbacked;
            uint128 isolationModeTotalDebt;
        }
        
        function getReserveData(address asset) external view returns (ReserveData memory);
    }
}

// Define Aave Price Oracle interface
sol! {
    #[sol(rpc)]
    interface IAavePriceOracle {
        function getAssetPrice(address asset) external view returns (uint256);
    }
}

// Define ERC20 interface to get decimals and balances
sol! {
    #[sol(rpc)]
    interface IERC20 {
        function decimals() external view returns (uint8);
        function totalSupply() external view returns (uint256);
    }
}

// Define AToken interface (extends ERC20)
sol! {
    #[sol(rpc)]
    interface IAToken {
        function totalSupply() external view returns (uint256);
        function decimals() external view returns (uint8);
    }
}

// Define Debt Token interface
sol! {
    #[sol(rpc)]
    interface IDebtToken {
        function totalSupply() external view returns (uint256);
    }
}

/// Aave protocol addresses for different networks
#[derive(Debug, Clone)]
pub struct AaveAddresses {
    pub pool: Address,
    pub price_oracle: Address,
}

impl AaveAddresses {
    /// Aave V3 on Ethereum Mainnet
    pub fn mainnet() -> Self {
        Self {
            pool: "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2".parse().unwrap(),
            price_oracle: "0x54586bE62E3c3580375aE3723C145253060Ca0C2".parse().unwrap(),
        }
    }

    /// Aave V3 on Sepolia Testnet
    pub fn sepolia() -> Self {
        Self {
            pool: "0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951".parse().unwrap(),
            price_oracle: "0x2da88497588bf89281816106C7259e31AF45a663".parse().unwrap(),
        }
    }
}

/// Main struct for fetching Aave data
pub struct AaveFetcher {
    pool_address: Address,
    oracle_address: Address,
    rpc_url: String,
}

impl AaveFetcher {
    pub fn new(addresses: AaveAddresses, rpc_url: String) -> Self {
        Self {
            pool_address: addresses.pool,
            oracle_address: addresses.price_oracle,
            rpc_url,
        }
    }

    /// Fetch all reserve data from Aave and prepare it for the zkVM
    pub async fn fetch_reserves(&self) -> Result<AaveInput> {
        println!(" Connecting to Aave Pool at: {}", self.pool_address);
        println!(" Using RPC endpoint: {}", self.rpc_url);

        // Create provider
        let url = Url::parse(&self.rpc_url)?;
        let provider = ProviderBuilder::new().on_http(url);

        // Create contract instances
        let pool = IAavePool::new(self.pool_address, &provider);
        let oracle = IAavePriceOracle::new(self.oracle_address, &provider);

        // Step 1: Get list of all reserves
        println!("\n Fetching reserve list...");
        let reserves_list = pool.getReservesList().call().await?._0;
        println!("✓ Found {} reserves", reserves_list.len());

        // Step 2: Fetch data for each reserve
        let mut reserves_data = Vec::new();
        
        for (index, asset_address) in reserves_list.iter().enumerate() {
            println!("\n--- Processing reserve {}/{}: {} ---", 
                index + 1, reserves_list.len(), asset_address);

            // Fetch reserve data inline to avoid complex generic issues
            let result = async {
                let reserve_data = pool.getReserveData(*asset_address).call().await?._0;
                
                let asset = IERC20::new(*asset_address, &provider);
                let decimals = asset.decimals().call().await?._0;
                
                let atoken = IAToken::new(reserve_data.aTokenAddress, &provider);
                let total_atoken = atoken.totalSupply().call().await?._0;
                
                let stable_debt = IDebtToken::new(reserve_data.stableDebtTokenAddress, &provider);
                let total_stable_debt = stable_debt.totalSupply().call().await?._0;
                
                let variable_debt = IDebtToken::new(reserve_data.variableDebtTokenAddress, &provider);
                let total_variable_debt = variable_debt.totalSupply().call().await?._0;
                
                let price = oracle.getAssetPrice(*asset_address).call().await?._0;
                
                Ok::<AaveReserveData, eyre::Report>(AaveReserveData {
                    token_address: format!("{:?}", asset_address),
                    total_atoken: u256_to_u128(total_atoken)?,
                    total_stable_debt: u256_to_u128(total_stable_debt)?,
                    total_variable_debt: u256_to_u128(total_variable_debt)?,
                    price_usd: u256_to_u128(price)?,
                    decimals,
                })
            }.await;

            match result {
                Ok(reserve) => {
                    println!("  ✓ Total aToken: {}", reserve.total_atoken);
                    println!("  ✓ Total Debt: {}", reserve.total_stable_debt + reserve.total_variable_debt);
                    println!("  ✓ Price: ${:.2}", reserve.price_usd as f64 / 1e8);
                    reserves_data.push(reserve);
                }
                Err(e) => {
                    println!("  ⚠ Warning: Failed to fetch data for {}: {}", asset_address, e);
                    println!("  Skipping this reserve...");
                    continue;
                }
            }
        }

        if reserves_data.is_empty() {
            return Err(eyre!("No reserve data could be fetched"));
        }

        println!("\n✓ Successfully fetched {} out of {} reserves", 
            reserves_data.len(), reserves_list.len());

        // Create input structure
        let input = AaveInput {
            reserves: reserves_data,
            protocol_name: "Aave V3".to_string(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)?
                .as_secs(),
        };

        Ok(input)
    }
}

/// Convert U256 to u128, checking for overflow
fn u256_to_u128(value: U256) -> Result<u128> {
    value.try_into()
        .map_err(|_| eyre!("Value {} too large for u128", value))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore] // Run with: cargo test -- --ignored --nocapture
    async fn test_fetch_aave_mainnet() {
        // This test requires a valid RPC endpoint
        let rpc_url = std::env::var("ETH_RPC_URL")
            .unwrap_or_else(|_| "https://eth.llamarpc.com".to_string());

        let fetcher = AaveFetcher::new(AaveAddresses::mainnet(), rpc_url);
        
        let result = fetcher.fetch_reserves().await;
        assert!(result.is_ok(), "Failed to fetch reserves: {:?}", result.err());
        
        let input = result.unwrap();
        assert!(!input.reserves.is_empty(), "No reserves fetched");
        println!("Successfully fetched {} reserves", input.reserves.len());
    }
}
