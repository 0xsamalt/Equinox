# DeRisk Protocol - Decentralized Insurance dApp

A futuristic, glass-morphism web3 interface for the DeRisk Protocol - a decentralized, non-custodial insurance protocol that allows users to hedge against DeFi protocol risk with automatic, ZK-oracle-based payouts.

## 🌟 Features

- **Buy Policy**: Purchase insurance policies for DeFi protocols (Aave, Compound, Morpho, Euler, Spark)
- **My Policies**: View and manage your active policies, claim payouts when eligible
- **Oracle Dashboard**: Real-time protocol health scores powered by RISC Zero proofs
- **Web3 Wallet Integration**: Connect with RainbowKit and Wagmi v2
- **Glass-Morphism Design**: Futuristic UI with frosted glass panels, neon gradients, and smooth animations

## 🎨 Design System

- **Color Palette**: Deep space gradients with neon cyan, purple, and pink accents
- **Glass Effects**: Backdrop blur with semi-transparent panels and glowing borders
- **Animations**: Framer Motion for smooth transitions, floating orbs, and interactive hover effects
- **Typography**: Clean, modern fonts with gradient text effects

## 🛠️ Tech Stack

- **React 18** + **TypeScript**
- **Vite** - Fast build tool
- **Wagmi v2** + **RainbowKit** - Web3 wallet connection
- **Framer Motion** - Smooth animations
- **TailwindCSS** - Utility-first styling
- **ShadCN/UI** - High-quality React components
- **Viem** - Ethereum interactions

## 📦 Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## ⚙️ Configuration

### 1. WalletConnect Project ID

Update `src/config/wagmi.ts` with your WalletConnect project ID:

```typescript
projectId: 'YOUR_PROJECT_ID', // Get from cloud.walletconnect.com
```

### 2. Contract Addresses

Update `src/config/contracts.ts` with deployed contract addresses:

```typescript
export const CONTRACTS = {
  DeRiskProtocol: '0x...', // Deployed DeRiskProtocol address
  DeRiskOracle: '0x...', // Deployed DeRiskOracle address
  PremiumVault: '0x...', // Deployed PremiumVault address
  USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // Mainnet USDC
};
```

### 3. Network Configuration

Currently configured for Mainnet and Sepolia. Update `src/config/wagmi.ts` to add more networks.

## 📖 Smart Contract Integration

The dApp integrates with three main contracts:

### DeRiskProtocol.sol
- `buyPolicy(protocol, strikeScore, expiry)` - Purchase insurance policy
- `claimPayout(policyId)` - Claim payout for eligible policies
- `getUserPolicies(address)` - Get user's policy IDs
- `policies(policyId)` - Get policy details

### DeRiskOracle.sol
- `safetyScores(protocol)` - Get current safety score for a protocol
- `updateScore(protocol, journal, seal)` - Update score with ZK proof (admin only)

### USDC (ERC-20)
- `approve(spender, amount)` - Approve protocol to spend USDC for premiums

## 🎯 How It Works

### 1. Buy Policy
1. Connect your wallet
2. Select a DeFi protocol to insure (e.g., Aave)
3. Set strike score (payout triggers if safety score drops below this)
4. Set expiry duration (in days)
5. Approve USDC spending
6. Buy policy (receive ERC-1155 NFT)

### 2. Monitor Health
- View real-time safety scores for all protocols
- Scores are updated via zero-knowledge proofs every 15 minutes
- Visual indicators show protocol health (Excellent, Good, Fair, At Risk)

### 3. Claim Payout
- If a protocol's safety score drops below your strike score
- Your policy becomes "in-the-money"
- Click "Claim Payout" to receive your coverage

## 🔒 Security Features

- **Non-Custodial**: Users maintain full control of their assets
- **ZK-Oracle**: Safety scores verified via zero-knowledge proofs
- **Automated Payouts**: No manual claims process or committees
- **Transparent**: All data on-chain and publicly verifiable

## 🚀 Deployment

The app is optimized for deployment to:
- Vercel
- Netlify
- IPFS
- Any static hosting service

Build command: `npm run build`
Output directory: `dist`

## 📱 Responsive Design

Fully responsive across:
- Desktop (1920px+)
- Laptop (1280px+)
- Tablet (768px+)
- Mobile (320px+)

## 🎨 Customization

### Colors
Edit `src/index.css` to customize the color palette:
```css
:root {
  --primary: 180 100% 50%; /* Neon cyan */
  --secondary: 280 70% 60%; /* Purple */
  --accent: 330 100% 60%; /* Pink */
}
```

### Animations
Edit `tailwind.config.ts` to customize animations:
```typescript
animation: {
  'float': 'float 6s ease-in-out infinite',
  'glow': 'glow 3s ease-in-out infinite',
}
```

## 📄 License

MIT License - feel free to use this project as a template for your own dApps!

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.

## 📞 Support

For questions or support, please refer to the DeRisk Protocol documentation.

---

Built with ❤️ using Lovable.dev
