import { cn } from "@/lib/utils";
import { motion } from "framer-motion";

interface GlassContainerProps {
  children: React.ReactNode;
  className?: string;
  hover?: boolean;
}

export const GlassContainer = ({ children, className, hover = false }: GlassContainerProps) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      whileHover={hover ? { scale: 1.02, y: -4 } : undefined}
      className={cn(
        "relative backdrop-blur-glass bg-white/5 rounded-lg border border-white/10",
        "shadow-[0_8px_32px_rgba(0,0,0,0.3)]",
        hover && "transition-all duration-300 hover:border-primary/50 hover:shadow-[0_8px_32px_rgba(0,255,255,0.3)]",
        className
      )}
    >
      {children}
    </motion.div>
  );
};
