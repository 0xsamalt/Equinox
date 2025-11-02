import { useState, useEffect } from 'react';
import { GlassContainer } from '@/components/GlassContainer';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { PROTOCOLS, CONTRACTS } from '@/config/contracts';
import { DeRiskProtocolABI, USDCABI } from '@/config/abis';
import { useAccount, useWriteContract } from 'wagmi';
import { parseUnits } from 'viem';
import { toast } from 'sonner';
import { Shield, DollarSign, Calendar, TrendingDown } from 'lucide-react';
import { motion } from 'framer-motion';

export const BuyPolicy = () => {
  const { address } = useAccount();
  const [protocol, setProtocol] = useState('');
  const [strikeScore, setStrikeScore] = useState('');
  const [expiry, setExpiry] = useState('');
  
  const { writeContract: approveUSDC, isPending: isApproving, isSuccess: approveSuccess } = useWriteContract();
  const { writeContract: buyPolicy, isPending: isBuying, isSuccess: buySuccess } = useWriteContract();

  // Calculate premium: (100 - strikeScore) * expiry_duration * some multiplier
  const calculatePremium = () => {
    if (!strikeScore || !expiry) return 0;
    const score = parseInt(strikeScore);
    const duration = parseInt(expiry);
    if (score < 0 || score > 100) return 0;
    
    // Formula: (100 - strikeScore) * days * 0.01 USDC
    const premium = (100 - score) * duration * 0.01;
    return premium;
  };

  const premium = calculatePremium();

  useEffect(() => {
    if (approveSuccess) {
      toast.success('USDC approved successfully!');
    }
  }, [approveSuccess]);

  useEffect(() => {
    if (buySuccess) {
      toast.success('Policy purchased successfully!');
      setProtocol('');
      setStrikeScore('');
      setExpiry('');
    }
  }, [buySuccess]);

  const handleApprove = async () => {
    if (!address) {
      toast.error('Please connect your wallet');
      return;
    }

    try {
      const premiumWei = parseUnits(premium.toFixed(6), 6); // USDC has 6 decimals
      
      approveUSDC({
        address: CONTRACTS.USDC as `0x${string}`,
        abi: USDCABI,
        functionName: 'approve',
        args: [CONTRACTS.DeRiskProtocol as `0x${string}`, premiumWei],
      } as any);
    } catch (error) {
      console.error('Approval error:', error);
      toast.error('Approval failed');
    }
  };

  const handleBuyPolicy = async () => {
    if (!address || !protocol || !strikeScore || !expiry) {
      toast.error('Please fill all fields');
      return;
    }

    try {
      const score = BigInt(strikeScore);
      const expiryTimestamp = BigInt(Math.floor(Date.now() / 1000) + parseInt(expiry) * 86400);
      
      buyPolicy({
        address: CONTRACTS.DeRiskProtocol as `0x${string}`,
        abi: DeRiskProtocolABI,
        functionName: 'buyPolicy',
        args: [protocol, score, expiryTimestamp],
      } as any);
    } catch (error) {
      console.error('Buy policy error:', error);
      toast.error('Purchase failed');
    }
  };

  return (
    <div className="space-y-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-2"
      >
        <h2 className="text-4xl font-bold bg-gradient-primary bg-clip-text text-transparent">
          Buy Insurance Policy
        </h2>
        <p className="text-muted-foreground">
          Protect your DeFi investments with automated, trustless coverage
        </p>
      </motion.div>

      <GlassContainer className="p-8">
        <div className="space-y-6">
          {/* Protocol Selection */}
          <div className="space-y-2">
            <Label className="flex items-center gap-2 text-foreground">
              <Shield className="w-4 h-4 text-primary" />
              Select Protocol
            </Label>
            <Select value={protocol} onValueChange={setProtocol}>
              <SelectTrigger className="bg-muted/50 border-white/10">
                <SelectValue placeholder="Choose a protocol to insure" />
              </SelectTrigger>
              <SelectContent className="bg-popover border-white/10">
                {PROTOCOLS.map((p) => (
                  <SelectItem key={p.value} value={p.value}>
                    {p.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Strike Score */}
          <div className="space-y-2">
            <Label className="flex items-center gap-2 text-foreground">
              <TrendingDown className="w-4 h-4 text-secondary" />
              Strike Score (0-100)
            </Label>
            <Input
              type="number"
              placeholder="e.g., 70"
              value={strikeScore}
              onChange={(e) => setStrikeScore(e.target.value)}
              min="0"
              max="100"
              className="bg-muted/50 border-white/10"
            />
            <p className="text-xs text-muted-foreground">
              Payout triggers if protocol safety score falls below this value
            </p>
          </div>

          {/* Expiry */}
          <div className="space-y-2">
            <Label className="flex items-center gap-2 text-foreground">
              <Calendar className="w-4 h-4 text-accent" />
              Expiry (days)
            </Label>
            <Input
              type="number"
              placeholder="e.g., 30"
              value={expiry}
              onChange={(e) => setExpiry(e.target.value)}
              min="1"
              className="bg-muted/50 border-white/10"
            />
          </div>

          {/* Premium Display */}
          <motion.div
            initial={{ scale: 0.95 }}
            animate={{ scale: 1 }}
            className="p-6 rounded-lg bg-gradient-primary/10 border border-primary/20"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <DollarSign className="w-5 h-5 text-primary" />
                <span className="text-sm text-muted-foreground">Premium</span>
              </div>
              <div className="text-right">
                <div className="text-3xl font-bold text-primary">
                  {premium.toFixed(2)}
                </div>
                <div className="text-xs text-muted-foreground">USDC</div>
              </div>
            </div>
          </motion.div>

          {/* Action Buttons */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button
              onClick={handleApprove}
              disabled={!address || !premium || isApproving}
              size="lg"
              variant="secondary"
              className="w-full"
            >
              {isApproving ? 'Approving...' : 'Approve USDC'}
            </Button>
            <Button
              onClick={handleBuyPolicy}
              disabled={!address || !protocol || !premium || isBuying}
              size="lg"
              className="w-full bg-gradient-primary hover:opacity-90"
            >
              {isBuying ? 'Buying...' : 'Buy Policy'}
            </Button>
          </div>
        </div>
      </GlassContainer>
    </div>
  );
};
