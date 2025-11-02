# DeRisk ZK-Oracle Architecture Diagram

## System Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           ETHEREUM BLOCKCHAIN                                 │
│                                                                               │
│  ┌─────────────────────┐  ┌──────────────────┐  ┌──────────────────────┐   │
│  │   Aave Protocol     │  │  RISC Zero       │  │  DeRiskOracle.sol    │   │
│  │                     │  │  Verifier        │  │                      │   │
│  │  - Pool.sol         │  │                  │  │  approvedProvers[]   │   │
│  │  - PriceOracle.sol  │  │  verify(seal,    │  │  safetyScores[]      │   │
│  │  - Reserve Data     │  │    imageId,      │  │                      │   │
│  │                     │  │    journal)      │  │  updateScore()       │   │
│  └─────────────────────┘  └──────────────────┘  └──────────────────────┘   │
│           ▲                         ▲                      ▲                 │
└───────────┼─────────────────────────┼──────────────────────┼─────────────────┘
            │                         │                      │
            │ (1) RPC: Read           │                      │ (4) Submit
            │     Reserve Data        │                      │     Proof
            │                         │                      │
            │                         │                      │
┌───────────┼─────────────────────────┼──────────────────────┼─────────────────┐
│           │          HOST PROGRAM (Off-Chain Server)       │                 │
│           │                                                 │                 │
│  ┌────────┴──────────┐      ┌──────────────┐      ┌───────┴──────────┐     │
│  │  AaveFetcher      │      │  zkVM        │      │  OracleSubmitter │     │
│  │                   │      │  Executor    │      │                  │     │
│  │  - Connect RPC    │─(2)─▶│              │─(3)─▶│  - Build TX      │     │
│  │  - Get reserves   │      │  Execute     │      │  - Sign & Send   │     │
│  │  - Get prices     │      │  Guest       │      │                  │     │
│  │  - Build input    │      │              │      │                  │     │
│  └───────────────────┘      └──────────────┘      └──────────────────┘     │
│                                     │                                        │
│                                     │ Pass Input                             │
│                                     ▼                                        │
│                        ┌──────────────────────────┐                         │
│                        │   RISC Zero zkVM         │                         │
│                        │   (Sandboxed Execution)  │                         │
│                        │                          │                         │
│                        │  ┌────────────────────┐  │                         │
│                        │  │  GUEST PROGRAM     │  │                         │
│                        │  │  (Aave Safety      │  │                         │
│                        │  │   Score Logic)     │  │                         │
│                        │  │                    │  │                         │
│                        │  │  1. Read input     │  │                         │
│                        │  │  2. Loop reserves  │  │                         │
│                        │  │  3. Calculate      │  │                         │
│                        │  │     assets/debts   │  │                         │
│                        │  │  4. Compute score  │  │                         │
│                        │  │  5. Commit result  │  │                         │
│                        │  └────────────────────┘  │                         │
│                        │            │              │                         │
│                        │            ▼              │                         │
│                        │  ┌────────────────────┐  │                         │
│                        │  │  ZK Proof Engine   │  │                         │
│                        │  │  (Auto-generated)  │  │                         │
│                        │  │                    │  │                         │
│                        │  │  Generates:        │  │                         │
│                        │  │  - Seal (proof)    │  │                         │
│                        │  │  - Journal (output)│  │                         │
│                        │  └────────────────────┘  │                         │
│                        └──────────────────────────┘                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
[1] FETCH DATA
────────────────
Host → Aave Pool: getReservesList()
  ← [USDC, WETH, DAI, ...]

For each reserve:
  Host → Aave Pool: getReserveData(token)
    ← { aToken, stableDebt, variableDebt }
  Host → Price Oracle: getAssetPrice(token)
    ← price (in USD, 1e8 scaled)

Result: AaveInput {
  reserves: [
    { token: USDC, aToken: 100M, debt: 50M, price: $1 },
    { token: WETH, aToken: 50K, debt: 25K, price: $2000 },
    ...
  ]
}


[2] COMPUTE IN ZKVM
───────────────────
Host → zkVM: Execute guest with input

zkVM executes:
  total_assets = 0
  total_liabilities = 0
  
  for reserve in reserves:
    asset_value = normalize(reserve.aToken * reserve.price)
    liability_value = normalize(reserve.debt * reserve.price)
    total_assets += asset_value
    total_liabilities += liability_value
  
  buffer = total_assets - total_liabilities
  safety_score = (buffer / total_assets) * 100
  
  commit(safety_score)

zkVM generates:
  - Journal: SafetyScoreOutput { score: 98.5%, assets: $1.2B, liabilities: $1.18B }
  - Seal: ZK-STARK proof (200KB binary)


[3] EXTRACT PROOF
─────────────────
Host receives from zkVM:
  - receipt.journal.bytes (public output)
  - receipt.seal (cryptographic proof)

Host decodes journal:
  output = decode(journal)
  print("Safety Score: {}", output.safety_score)

Host saves artifacts:
  - output/proof_seal.bin
  - output/proof_journal.bin
  - output/safety_score_output.json


[4] SUBMIT ON-CHAIN
───────────────────
Host → DeRiskOracle: updateScore(AAVE_ADDRESS, journal, seal)

DeRiskOracle executes:
  1. imageId = approvedProvers[AAVE_ADDRESS]
  2. require(imageId != 0, "Protocol not approved")
  3. RiscZeroVerifier.verify(seal, imageId, sha256(journal))
  4. if valid:
       newScore = decode(journal).safety_score
       safetyScores[AAVE_ADDRESS] = newScore
       emit ScoreUpdated(AAVE_ADDRESS, newScore)
  5. else:
       revert("Invalid proof")

Result: On-chain safety score updated with cryptographic guarantee of correctness
```

## Trust Model

```
┌───────────────────────────────────────────────────────────────────┐
│                    WHO DO YOU TRUST?                              │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Traditional Oracle (Chainlink, etc.):                           │
│  ├─ ✓ Trust: Decentralized network of nodes                     │
│  ├─ ✗ But: Nodes could collude or be compromised                │
│  └─ ✗ And: You trust their off-chain computation is correct     │
│                                                                   │
│  Centralized Oracle:                                             │
│  ├─ ✗ Trust: Single company/server                              │
│  ├─ ✗ But: Could be hacked, go offline, or act maliciously      │
│  └─ ✗ And: No way to verify their computation                   │
│                                                                   │
│  ZK-Oracle (DeRisk):                                             │
│  ├─ ✓ Trust: ONLY the math (cryptography)                       │
│  ├─ ✓ Zero trust in the prover/host                             │
│  ├─ ✓ Zero trust in off-chain computation                       │
│  └─ ✓ On-chain contract verifies proof cryptographically        │
│                                                                   │
│  The prover could:                                               │
│  ├─ ✗ Try to submit fake data → Proof won't verify              │
│  ├─ ✗ Run wrong program → Image ID mismatch                     │
│  ├─ ✗ Manipulate computation → Proof invalid                    │
│  └─ ✓ Only valid proofs from approved program pass verification │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Security Properties

```
┌─────────────────────────────────────────────────────────────────────┐
│  Property               │  How It's Guaranteed                      │
├─────────────────────────┼───────────────────────────────────────────┤
│  Correctness            │  ZK proof verifies computation is correct │
│  Determinism            │  Guest always produces same output for    │
│                         │  same input (zkVM enforces)               │
│  Integrity              │  Prover can't manipulate result without   │
│                         │  proof verification failing               │
│  Program Authenticity   │  Image ID ensures only DAO-approved       │
│                         │  programs can update scores               │
│  Non-repudiation        │  Proof is cryptographically binding       │
│  Transparency           │  Guest program source code is public      │
│  Decentralization       │  Anyone can run prover (permissionless)   │
└─────────────────────────────────────────────────────────────────────┘
```

## Scalability Path

```
Phase 1 (Current):
┌─────────────┐
│  You run    │──▶ Aave ──▶ On-chain
│  host       │
└─────────────┘
Single prover, single protocol


Phase 2 (Multi-Protocol):
┌─────────────┐
│  You run    │──▶ Aave ────▶│
│  host       │──▶ Compound ─▶│──▶ On-chain (registry)
│             │──▶ Morpho ───▶│
└─────────────┘
Single prover, multiple protocols, DAO-approved Image IDs


Phase 3 (Decentralized):
┌─────────────┐              │
│  Prover 1   │──▶ Aave ────▶│
├─────────────┤              │
│  Prover 2   │──▶ Compound ─▶│──▶ On-chain (registry)
├─────────────┤              │
│  Prover 3   │──▶ Morpho ───▶│
└─────────────┘              │
Chainlink Functions, competitive proving


Phase 4 (Cross-Chain):
┌─────────────┐              
│  Prover     │──▶ Aave (Arbitrum) ──▶ CCIP ──▶ Ethereum Oracle
│  (Arbitrum) │
└─────────────┘
┌─────────────┐
│  Prover     │──▶ Aave (Polygon) ───▶ CCIP ──▶ Ethereum Oracle
│  (Polygon)  │
└─────────────┘
Cross-chain proving with Chainlink CCIP
```

## File Structure Map

```
derisk-oracle/
│
├── core/                           [Shared Types]
│   ├── src/lib.rs                 ├─▶ AaveReserveData
│   └── Cargo.toml                 ├─▶ AaveInput
│                                  ├─▶ SafetyScoreOutput
│                                  └─▶ normalize_amount()
│
├── methods/                        [Guest Programs]
│   ├── aave/guest/
│   │   ├── src/main.rs            ├─▶ Safety score calculation
│   │   └── Cargo.toml             └─▶ RISC Zero guest dependencies
│   ├── build.rs                   ├─▶ Compiles guest → ELF + Image ID
│   ├── src/lib.rs                 └─▶ Exports AAVE_ELF, AAVE_ID
│   └── Cargo.toml
│
├── host/                           [Orchestrator]
│   ├── src/
│   │   ├── main.rs                ├─▶ CLI, orchestration, zkVM execution
│   │   ├── aave_fetcher.rs        ├─▶ RPC calls, data fetching
│   │   └── oracle_submitter.rs    └─▶ On-chain submission
│   ├── tests/
│   │   └── integration_tests.rs   └─▶ End-to-end tests
│   └── Cargo.toml
│
├── output/                         [Generated Artifacts]
│   ├── aave_input.json            ├─▶ Fetched data
│   ├── proof_seal.bin             ├─▶ ZK proof (~200KB)
│   ├── proof_journal.bin          ├─▶ Public output
│   └── safety_score_output.json   └─▶ Human-readable result
│
├── docs/
│   ├── ZKVM_README.md             ├─▶ Full technical documentation
│   ├── QUICKSTART.md              ├─▶ 10-minute guide
│   ├── IMPLEMENTATION_SUMMARY.md  ├─▶ This document
│   └── ARCHITECTURE.md            └─▶ Current file
│
├── .env.example                    └─▶ Configuration template
├── build_and_test.sh               └─▶ Automated build script
└── Cargo.toml                      └─▶ Workspace manifest
```

---

**Legend**:
- `▶` Data flow
- `┌─┐` Component boundary
- `│` Connection
- `[...]` Category/Module
- `├─▶` Provides/Exports
- `└─▶` Connects to
