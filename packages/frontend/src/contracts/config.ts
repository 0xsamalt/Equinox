import { type Address } from 'viem'

export interface ContractConfig {
  address: Address
  abi: any[]
}

export interface Contracts {
  Equinox: ContractConfig
  PremiumVault: ContractConfig
  Oracle: ContractConfig
  MockUSDC: ContractConfig
}

// These addresses will be populated later
export const contractAddresses: { [key: string]: Address } = {
  Equinox: '0x0000000000000000000000000000000000000000' as Address,
  PremiumVault: '0x0000000000000000000000000000000000000000' as Address,
  Oracle: '0x0000000000000000000000000000000000000000' as Address,
  MockUSDC: '0x0000000000000000000000000000000000000000' as Address,
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