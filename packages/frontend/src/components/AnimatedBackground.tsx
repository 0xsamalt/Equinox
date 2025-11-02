export const AnimatedBackground = () => {
  return (
    <div className="fixed inset-0 -z-10 overflow-hidden">
      {/* Base gradient */}
      <div className="absolute inset-0 bg-gradient-background" />
      
      {/* Animated orbs */}
      <div className="absolute top-0 -left-40 w-96 h-96 bg-glow-cyan/20 rounded-full mix-blend-multiply filter blur-3xl animate-float" />
      <div className="absolute top-40 -right-40 w-96 h-96 bg-glow-purple/20 rounded-full mix-blend-multiply filter blur-3xl animate-float" style={{ animationDelay: '2s' }} />
      <div className="absolute -bottom-40 left-1/2 w-96 h-96 bg-glow-pink/20 rounded-full mix-blend-multiply filter blur-3xl animate-float" style={{ animationDelay: '4s' }} />
      
      {/* Grid overlay */}
      <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:100px_100px]" />
    </div>
  );
};
