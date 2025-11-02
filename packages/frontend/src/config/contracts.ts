// Contract addresses (update with deployed addresses)
export const CONTRACTS = {
  DeRiskProtocol: '0x0000000000000000000000000000000000000000',
  DeRiskOracle: '0x0000000000000000000000000000000000000000',
  PremiumVault: '0x0000000000000000000000000000000000000000',
  USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // Mainnet USDC
} as const;

// Supported protocols
export const PROTOCOLS = [
  { value: 'aave', label: 'Aave' },
  { value: 'compound', label: 'Compound' },
  { value: 'morpho', label: 'Morpho' },
  { value: 'euler', label: 'Euler' },
  { value: 'spark', label: 'Spark' },
] as const;
