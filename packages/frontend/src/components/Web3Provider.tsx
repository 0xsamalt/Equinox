import { WagmiConfig } from 'wagmi'
import { config } from '../lib/web3/config'

interface Web3ProviderProps {
  children: React.ReactNode
}

export function Web3Provider({ children }: Web3ProviderProps) {
  return (
    <WagmiConfig config={config}>
      {children}
    </WagmiConfig>
  )
}