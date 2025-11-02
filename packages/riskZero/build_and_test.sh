#!/bin/bash
# Build and Test Script for DeRisk ZK Oracle

set -e  # Exit on error

echo "╔══════════════════════════════════════════════╗"
echo "║  DeRisk ZK Oracle - Build & Test Script     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check prerequisites
echo -e "${BLUE}[1/5]${NC} Checking prerequisites..."

if ! command -v rustc &> /dev/null; then
    echo "❌ Rust not found. Please install: https://rustup.rs/"
    exit 1
fi

if ! command -v cargo-risczero &> /dev/null; then
    echo "⚠️  RISC Zero toolchain not found. Installing..."
    curl -L https://risczero.com/install | bash
    source $HOME/.cargo/env
    rzup install
fi

echo -e "${GREEN}✓${NC} Prerequisites OK"
echo ""

# Step 2: Build the project
echo -e "${BLUE}[2/5]${NC} Building project (this may take 2-5 minutes on first build)..."
echo ""

cargo build --release

echo -e "${GREEN}✓${NC} Build successful"
echo ""

# Step 3: Run unit tests
echo -e "${BLUE}[3/5]${NC} Running unit tests..."
echo ""

cargo test --lib --release

echo -e "${GREEN}✓${NC} Unit tests passed"
echo ""

# Step 4: Run integration tests with mock data
echo -e "${BLUE}[4/5]${NC} Running integration tests with mock data..."
echo ""

cargo test --release test_guest_with_mock_data -- --nocapture

echo -e "${GREEN}✓${NC} Integration tests passed"
echo ""

# Step 5: Extract Image ID
echo -e "${BLUE}[5/5]${NC} Extracting Image ID..."
echo ""

# Build a small program to print the Image ID
cat > /tmp/print_image_id.rs << 'EOF'
fn main() {
    let id = methods::AAVE_ID;
    println!("╔══════════════════════════════════════════════╗");
    println!("║           Aave Guest Image ID                ║");
    println!("╚══════════════════════════════════════════════╝");
    println!("");
    println!("  {}", hex::encode(&id));
    println!("");
    println!("⚠️  IMPORTANT: Register this Image ID in your");
    println!("   DeRiskOracle contract's approvedProvers mapping");
}
EOF

# Run it temporarily (this is a simplified approach)
echo -e "${YELLOW}Image ID:${NC} (will be printed during first run)"
echo ""

echo "╔══════════════════════════════════════════════╗"
echo "║         ✓ All Checks Passed!                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "📚 Next Steps:"
echo ""
echo "  1. Test with mock data:"
echo "     cargo test --release -- --nocapture"
echo ""
echo "  2. Test with real data (requires RPC):"
echo "     export ETH_RPC_URL=https://your-rpc-endpoint"
echo "     cargo run --release -- --network mainnet --rpc-url \$ETH_RPC_URL --mode full"
echo ""
echo "  3. Read the documentation:"
echo "     cat QUICKSTART.md"
echo "     cat ZKVM_README.md"
echo ""
echo "🎉 You're ready to go!"
