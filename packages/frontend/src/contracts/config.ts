import { type Address, type Abi } from 'viem'

export interface ContractConfig {
  address: Address
  abi: Abi
}

export interface Contracts {
  Equinox: ContractConfig
  PremiumVault: ContractConfig
  Oracle: ContractConfig
  MockUSDC: ContractConfig
}

// These addresses will be populated later
import { type Address, type Abi } from 'viem'

export interface ContractConfig {
  address: Address
  abi: Abi
}

export interface Contracts {
  Equinox: ContractConfig
  PremiumVault: ContractConfig
  Oracle: ContractConfig
  MockUSDC: ContractConfig
}

// Contract addresses
export const contractAddresses = {
  Equinox: '0x0000000000000000000000000000000000000000' as const,
  PremiumVault: '0x0000000000000000000000000000000000000000' as const,
  Oracle: '0x0000000000000000000000000000000000000000' as const,
  MockUSDC: '0x0000000000000000000000000000000000000000' as const,
} as const;

// ABIs are dynamically imported to avoid bundling issues
export const getContractAbis = async () => {
  const [
    EquinoxArtifact,
    PremiumVaultArtifact,
    OracleArtifact,
    MockUSDCArtifact
  ] = await Promise.all([
    import('../../foundry/out/Equinox.sol/Equinox.json'),
    import('../../foundry/out/PremiumVault.sol/PremiumVault.json'),
    import('../../foundry/out/Oracle.sol/Oracle.json'),
    import('../../foundry/out/MockUSDC.sol/MockUSDC.json')
  ]);

  return {
    Equinox: EquinoxArtifact.default.abi as Abi,
    PremiumVault: PremiumVaultArtifact.default.abi as Abi,
    Oracle: OracleArtifact.default.abi as Abi,
    MockUSDC: MockUSDCArtifact.default.abi as Abi
  };
}

// Initialize contracts
export const initializeContracts = async (): Promise<Contracts> => {
  const abis = await getContractAbis();
  
  return {
    Equinox: {
      address: contractAddresses.Equinox,
      abi: abis.Equinox,
    },
    PremiumVault: {
      address: contractAddresses.PremiumVault,
      abi: abis.PremiumVault,
    },
    Oracle: {
      address: contractAddresses.Oracle,
      abi: abis.Oracle,
    },
    MockUSDC: {
      address: contractAddresses.MockUSDC,
      abi: abis.MockUSDC,
    },
  };
}

// Import ABIs from the foundry build artifacts
export const contractAbis = {
  Equinox: require('../../foundry/out/Equinox.sol/Equinox.json').abi,
  PremiumVault: require('../../foundry/out/PremiumVault.sol/PremiumVault.json').abi,
  Oracle: require('../../foundry/out/Oracle.sol/Oracle.json').abi,
  MockUSDC: require('../../foundry/out/MockUSDC.sol/MockUSDC.json').abi,
}

export const contracts: Contracts = {
  Equinox: {
    address: contractAddresses.Equinox,
    abi: contractAbis.Equinox,
  },
  PremiumVault: {
    address: contractAddresses.PremiumVault,
    abi: contractAbis.PremiumVault,
  },
  Oracle: {
    address: contractAddresses.Oracle,
    abi: contractAbis.Oracle,
  },
  MockUSDC: {
    address: contractAddresses.MockUSDC,
    abi: contractAbis.MockUSDC,
  },
}