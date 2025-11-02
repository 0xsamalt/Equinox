#![no_main]

use risc0_zkvm::guest::env;
use derisk_core::types::{SafetyScoreJournal, GuestInput};

risc0_zkvm::guest::entry!(main);

fn main() {
    // 1. Read input from host
    let input: GuestInput = env::read();
    
    // 2. Fetch data from blockchain via RPC
    let data = fetch_protocol_data(&input);
    
    // 3. Compute safety score (PROTOCOL-SPECIFIC LOGIC HERE)
    let safety_score = compute_safety_score(&data);
    
    // 4. Build standardized journal
    let journal = SafetyScoreJournal {
        protocol_address: input.protocol_address,
        protocol_type: PROTOCOL_TYPE_ID,  // Constant per protocol
        safety_score,
        total_assets_usd: data.total_assets,
        total_liabilities_usd: data.total_liabilities,
        timestamp: data.timestamp,
        block_number: input.block_number,
    };
    
    // 5. Commit to public journal
    env::commit(&journal);
}

// PROTOCOL-SPECIFIC IMPLEMENTATIONS
fn fetch_protocol_data(input: &GuestInput) -> ProtocolData {
    // Each protocol implements this differently
    todo!("Implement for specific protocol")
}

fn compute_safety_score(data: &ProtocolData) -> u64 {
    // Each protocol implements this differently
    todo!("Implement for specific protocol")
}