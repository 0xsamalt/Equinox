import { useContractRead, useContractWrite, usePrepareContractWrite } from 'wagmi'
import { contracts } from '../../contracts/config'

// Equinox Contract Hooks
export function useEquinoxRead(functionName: string, args?: any[]) {
  return useContractRead({
    address: contracts.Equinox.address,
    abi: contracts.Equinox.abi,
    functionName,
    args,
  })
}

export function useEquinoxWrite(functionName: string, args?: any[]) {
  const { config } = usePrepareContractWrite({
    address: contracts.Equinox.address,
    abi: contracts.Equinox.abi,
    functionName,
    args,
  })
  
  return useContractWrite(config)
}

// PremiumVault Contract Hooks
export function usePremiumVaultRead(functionName: string, args?: any[]) {
  return useContractRead({
    address: contracts.PremiumVault.address,
    abi: contracts.PremiumVault.abi,
    functionName,
    args,
  })
}

export function usePremiumVaultWrite(functionName: string, args?: any[]) {
  const { config } = usePrepareContractWrite({
    address: contracts.PremiumVault.address,
    abi: contracts.PremiumVault.abi,
    functionName,
    args,
  })
  
  return useContractWrite(config)
}

// Oracle Contract Hooks
export function useOracleRead(functionName: string, args?: any[]) {
  return useContractRead({
    address: contracts.Oracle.address,
    abi: contracts.Oracle.abi,
    functionName,
    args,
  })
}

// USDC Contract Hooks
export function useUSDCRead(functionName: string, args?: any[]) {
  return useContractRead({
    address: contracts.MockUSDC.address,
    abi: contracts.MockUSDC.abi,
    functionName,
    args,
  })
}

export function useUSDCWrite(functionName: string, args?: any[]) {
  const { config } = usePrepareContractWrite({
    address: contracts.MockUSDC.address,
    abi: contracts.MockUSDC.abi,
    functionName,
    args,
  })
  
  return useContractWrite(config)
}