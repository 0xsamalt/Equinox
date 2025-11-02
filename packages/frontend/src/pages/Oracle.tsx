import { GlassContainer } from '@/components/GlassContainer';
import { CircularProgress } from '@/components/CircularProgress';
import { CONTRACTS, PROTOCOLS } from '@/config/contracts';
import { DeRiskOracleABI } from '@/config/abis';
import { useReadContract } from 'wagmi';
import { Activity, TrendingUp } from 'lucide-react';
import { motion } from 'framer-motion';
import { Skeleton } from '@/components/ui/skeleton';

export const Oracle = () => {
  return (
    <div className="space-y-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center space-y-2"
      >
        <h2 className="text-4xl font-bold bg-gradient-primary bg-clip-text text-transparent">
          Protocol Health Oracle
        </h2>
        <p className="text-muted-foreground">
          Real-time safety scores powered by zero-knowledge proofs
        </p>
      </motion.div>

      <GlassContainer className="p-8 mb-6">
        <div className="flex items-center gap-4">
          <div className="p-3 rounded-lg bg-primary/10 border border-primary/20">
            <Activity className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h3 className="text-lg font-semibold">ZK-Oracle Status</h3>
            <p className="text-sm text-muted-foreground">
              Scores are updated every 15 minutes via RISC Zero proofs
            </p>
          </div>
          <div className="ml-auto">
            <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/30">
              <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
              <span className="text-sm font-medium text-primary">Live</span>
            </div>
          </div>
        </div>
      </GlassContainer>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {PROTOCOLS.map((protocol, index) => (
          <ProtocolScoreCard
            key={protocol.value}
            protocol={protocol.value}
            label={protocol.label}
            index={index}
          />
        ))}
      </div>
    </div>
  );
};

const ProtocolScoreCard = ({
  protocol,
  label,
  index,
}: {
  protocol: string;
  label: string;
  index: number;
}) => {
  const { data: score, isLoading } = useReadContract({
    address: CONTRACTS.DeRiskOracle as `0x${string}`,
    abi: DeRiskOracleABI,
    functionName: 'safetyScores',
    args: [protocol],
  } as any);

  // Mock data for demonstration since contracts aren't deployed
  const mockScore = 85 - (index * 5);
  const safetyScore = score ? Number(score) : mockScore;

  const getHealthStatus = (score: number) => {
    if (score >= 80) return { text: 'Excellent', color: 'text-glow-cyan' };
    if (score >= 60) return { text: 'Good', color: 'text-glow-purple' };
    if (score >= 40) return { text: 'Fair', color: 'text-accent' };
    return { text: 'At Risk', color: 'text-destructive' };
  };

  const healthStatus = getHealthStatus(safetyScore);

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: index * 0.1 }}
    >
      <GlassContainer hover className="p-6">
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-xl font-bold">{label}</h3>
              <p className="text-sm text-muted-foreground">Protocol Safety</p>
            </div>
            <TrendingUp className="w-5 h-5 text-primary" />
          </div>

          <div className="flex justify-center py-4">
            {isLoading ? (
              <Skeleton className="w-32 h-32 rounded-full" />
            ) : (
              <CircularProgress value={safetyScore} size={120} strokeWidth={10} />
            )}
          </div>

          <div className="pt-4 border-t border-white/10">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Health Status</span>
              <span className={`text-sm font-semibold ${healthStatus.color}`}>
                {healthStatus.text}
              </span>
            </div>
          </div>

          <div className="text-xs text-muted-foreground text-center">
            Last updated: {new Date().toLocaleTimeString()}
          </div>
        </div>
      </GlassContainer>
    </motion.div>
  );
};
