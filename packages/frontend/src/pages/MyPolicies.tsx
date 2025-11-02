import { useEffect } from 'react';
import { GlassContainer } from '@/components/GlassContainer';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CONTRACTS } from '@/config/contracts';
import { DeRiskProtocolABI } from '@/config/abis';
import { useAccount, useReadContract, useWriteContract } from 'wagmi';
import { toast } from 'sonner';
import { Shield, Calendar, TrendingDown, CheckCircle2, XCircle, Clock } from 'lucide-react';
import { motion } from 'framer-motion';
import { Skeleton } from '@/components/ui/skeleton';

export const MyPolicies = () => {
  const { address } = useAccount();
  
  const { data: policyIds, isLoading } = useReadContract({
    address: CONTRACTS.DeRiskProtocol as `0x${string}`,
    abi: DeRiskProtocolABI,
    functionName: 'getUserPolicies',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  } as any);

  const { writeContract: claimPayout, isPending: isClaiming, isSuccess: claimSuccess } = useWriteContract();

  useEffect(() => {
    if (claimSuccess) {
      toast.success('Payout claimed successfully!');
    }
  }, [claimSuccess]);

  const handleClaim = (policyId: bigint) => {
    try {
      claimPayout({
        address: CONTRACTS.DeRiskProtocol as `0x${string}`,
        abi: DeRiskProtocolABI,
        functionName: 'claimPayout',
        args: [policyId],
      } as any);
    } catch (error) {
      toast.error('Claim failed');
    }
  };

  if (!address) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <GlassContainer className="p-12 text-center">
          <Shield className="w-16 h-16 mx-auto mb-4 text-primary" />
          <h3 className="text-xl font-semibold mb-2">Connect Your Wallet</h3>
          <p className="text-muted-foreground">
            Please connect your wallet to view your policies
          </p>
        </GlassContainer>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <h2 className="text-4xl font-bold text-center bg-gradient-primary bg-clip-text text-transparent">
          My Policies
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => (
            <GlassContainer key={i} className="p-6">
              <Skeleton className="h-32 w-full" />
            </GlassContainer>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-2"
      >
        <h2 className="text-4xl font-bold bg-gradient-primary bg-clip-text text-transparent">
          My Policies
        </h2>
        <p className="text-muted-foreground">
          Manage and claim your insurance policies
        </p>
      </motion.div>

      {!policyIds || (policyIds as any[]).length === 0 ? (
        <GlassContainer className="p-12 text-center">
          <Shield className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
          <h3 className="text-xl font-semibold mb-2">No Policies Yet</h3>
          <p className="text-muted-foreground mb-4">
            You haven't purchased any insurance policies yet
          </p>
          <Button className="bg-gradient-primary">
            Buy Your First Policy
          </Button>
        </GlassContainer>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {(policyIds as any[]).map((policyId: any, index: number) => (
            <PolicyCard
              key={policyId.toString()}
              policyId={policyId}
              onClaim={handleClaim}
              isClaiming={isClaiming}
              index={index}
            />
          ))}
        </div>
      )}
    </div>
  );
};

const PolicyCard = ({
  policyId,
  onClaim,
  isClaiming,
  index,
}: {
  policyId: bigint;
  onClaim: (id: bigint) => void;
  isClaiming: boolean;
  index: number;
}) => {
  const { data: policy } = useReadContract({
    address: CONTRACTS.DeRiskProtocol as `0x${string}`,
    abi: DeRiskProtocolABI,
    functionName: 'policies',
    args: [policyId],
  } as any);

  if (!policy) return null;

  const [owner, protocol, strikeScore, expiry, premium, claimed] = policy as any[];
  const expiryDate = new Date(Number(expiry) * 1000);
  const isExpired = expiryDate < new Date();
  const isActive = !claimed && !isExpired;

  const getStatusBadge = () => {
    if (claimed) {
      return <Badge className="bg-accent/20 text-accent border-accent/30"><CheckCircle2 className="w-3 h-3 mr-1" />Claimed</Badge>;
    }
    if (isExpired) {
      return <Badge className="bg-destructive/20 text-destructive border-destructive/30"><XCircle className="w-3 h-3 mr-1" />Expired</Badge>;
    }
    return <Badge className="bg-primary/20 text-primary border-primary/30"><Clock className="w-3 h-3 mr-1" />Active</Badge>;
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1 }}
    >
      <GlassContainer hover className="p-6 space-y-4">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <Shield className="w-5 h-5 text-primary" />
            <h3 className="font-semibold capitalize">{protocol}</h3>
          </div>
          {getStatusBadge()}
        </div>

        <div className="space-y-3">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground flex items-center gap-2">
              <TrendingDown className="w-4 h-4" />
              Strike Score
            </span>
            <span className="font-semibold text-secondary">{strikeScore.toString()}</span>
          </div>

          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              Expiry
            </span>
            <span className="font-semibold">{expiryDate.toLocaleDateString()}</span>
          </div>

          <div className="pt-3 border-t border-white/10">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Premium Paid</span>
              <span className="font-bold text-primary">
                {(Number(premium) / 1e6).toFixed(2)} USDC
              </span>
            </div>
          </div>
        </div>

        {isActive && (
          <Button
            onClick={() => onClaim(policyId)}
            disabled={isClaiming}
            className="w-full bg-gradient-accent hover:opacity-90"
          >
            {isClaiming ? 'Claiming...' : 'Claim Payout'}
          </Button>
        )}
      </GlassContainer>
    </motion.div>
  );
};
