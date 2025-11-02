// Simplified ABIs for DeRisk Protocol contracts
export const DeRiskProtocolABI = [
  {
    inputs: [
      { name: 'protocol', type: 'string' },
      { name: 'strikeScore', type: 'uint256' },
      { name: 'expiry', type: 'uint256' },
    ],
    name: 'buyPolicy',
    outputs: [{ name: 'policyId', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'policyId', type: 'uint256' }],
    name: 'claimPayout',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'user', type: 'address' }],
    name: 'getUserPolicies',
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'policyId', type: 'uint256' }],
    name: 'policies',
    outputs: [
      { name: 'owner', type: 'address' },
      { name: 'protocol', type: 'string' },
      { name: 'strikeScore', type: 'uint256' },
      { name: 'expiry', type: 'uint256' },
      { name: 'premium', type: 'uint256' },
      { name: 'claimed', type: 'bool' },
    ],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export const DeRiskOracleABI = [
  {
    inputs: [{ name: 'protocol', type: 'string' }],
    name: 'safetyScores',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'protocol', type: 'string' },
      { name: 'journal', type: 'bytes' },
      { name: 'seal', type: 'bytes' },
    ],
    name: 'updateScore',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const;

export const USDCABI = [
  {
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    name: 'approve',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
    ],
    name: 'allowance',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;
