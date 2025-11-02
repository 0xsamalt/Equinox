# 🛡️ Equinox

<h4 align="center">
  A Decentralized Insurance Protocol
</h4>

🏗️ Equinox is a comprehensive decentralized insurance protocol built on Ethereum, combining robust smart contracts with multiple frontend implementations and advanced risk assessment capabilities.

⚙️ Built using:

- Smart Contracts: Solidity, Foundry
- Frontend: React/Vite, Next.js, TypeScript
- Risk Assessment: Rust
- Tools: Wagmi, Viem, RainbowKit

## 🌟 Features

- 📜 **Smart Insurance Contracts**: Robust and auditable insurance policies powered by Solidity
- 💰 **Premium Management**: Advanced vault system for premium calculations and management
- 🔮 **Oracle Integration**: Real-time data feeds for accurate risk assessment
- 🎨 **Multiple Frontend Options**: Choose between Vite-based React or Next.js implementations
- 🛠️ **Risk Assessment Engine**: Powered by Rust for high-performance risk calculations
- � **Secure Wallet Integration**: Seamless connection with various wallet providers
- � **Policy Management Dashboard**: User-friendly interface for managing insurance policies

## 📁 Project Structure

The project is organized into several key packages:

### 🏗️ Foundry Package (`/packages/foundry`)

- Smart contract development and testing environment
- Core contracts including:
  - `Equinox.sol`: Main protocol contract
  - `PremiumVault.sol`: Insurance premium management
  - `Oracle.sol`: Price feed and data oracle
- Testing and deployment scripts

### 🎨 Frontend Package (`/packages/frontend`)

- Modern React frontend built with Vite
- Features:
  - Policy management interface
  - Real-time premium calculations
  - Wallet integration
  - Responsive design with Tailwind CSS

### ⚡ Next.js Package (`/packages/nextjs`)

- Alternative frontend implementation using Next.js
- Includes:
  - Block explorer integration
  - Debug interface
  - Scaffold-ETH components
  - Web3 service integrations

### 🔒 RiskZero Package (`/packages/riskZero`)

- Risk assessment and verification system
- Built with Rust
- Includes minimal verification contracts

## 🚀 Getting Started

### Prerequisites

- Node.js (>= v20.18.3)
- Yarn (v1 or v2+)
- Rust toolchain
- Foundry for smart contract development

### Installation

1. Clone the repository:

```bash
git clone https://github.com/0xsamalt/Equinox.git
cd Equinox
```

2. Install dependencies for all packages:

```bash
# Install root dependencies
yarn install

# Install Foundry dependencies
cd packages/foundry
forge install

# Install frontend dependencies
cd ../frontend
yarn install

# Install Next.js dependencies
cd ../nextjs
yarn install
```

3. Set up environment variables:

- Copy `.env.example` to `.env` in relevant packages
- Configure your environment variables

### Development

#### Smart Contracts (Foundry)

```bash
cd packages/foundry
forge build
forge test
```

#### Frontend (Vite)

```bash
cd packages/frontend
yarn dev
```

#### Next.js Frontend

```bash
cd packages/nextjs
yarn dev
```

## 📖 Documentation

Detailed documentation for each component can be found in their respective directories:

- Smart Contracts: See `packages/foundry/README.md`
- Frontend: See `packages/frontend/README.md`
- Next.js: See `packages/nextjs/README.md`
- Risk Assessment: See `packages/riskZero/ARCHITECTURE.md`

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📜 License

This project is licensed under the terms of the license file in the root directory.

## 🔗 Links

- [GitHub Repository](https://github.com/0xsamalt/Equinox)
- [Architecture Overview](packages/riskZero/ARCHITECTURE.md)
