import { Link } from 'react-router-dom';
import { AbstractBackground } from '@/components/AbstractBackground';
import { Navbar } from '@/components/Navbar';
import { GlassContainer } from '@/components/GlassContainer';
import { Button } from '@/components/ui/button';
import { Shield, ShoppingCart, Briefcase, Activity, ArrowRight, Check } from 'lucide-react';
import { motion } from 'framer-motion';

const Home = () => {
  const features = [
    {
      icon: ShoppingCart,
      title: 'Buy Policy',
      description: 'Purchase insurance coverage for top DeFi protocols',
      href: '/buy',
      gradient: 'from-primary/20 to-primary/5',
      iconColor: 'text-primary',
    },
    {
      icon: Briefcase,
      title: 'My Policies',
      description: 'Manage your active policies and claim payouts',
      href: '/policies',
      gradient: 'from-secondary/20 to-secondary/5',
      iconColor: 'text-secondary',
    },
    {
      icon: Activity,
      title: 'Oracle Dashboard',
      description: 'Monitor real-time protocol health scores',
      href: '/oracle',
      gradient: 'from-accent/20 to-accent/5',
      iconColor: 'text-accent',
    },
  ];

  const benefits = [
    'Zero-Knowledge Proof Verification',
    'Automated Payouts',
    'Non-Custodial Insurance',
    'Real-Time Risk Monitoring',
    'Multi-Protocol Coverage',
    'Transparent On-Chain Data',
  ];

  return (
    <div className="min-h-screen">
      <AbstractBackground />
      <Navbar />
      
      <main className="container mx-auto px-4 py-16">
        {/* Hero Section */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="text-center mb-20 max-w-4xl mx-auto"
        >
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2, type: "spring" }}
            className="inline-flex items-center justify-center w-24 h-24 mb-8 relative"
          >
            <Shield className="w-16 h-16 text-primary relative z-10" />
            <div className="absolute inset-0 bg-primary/20 rounded-full blur-2xl animate-pulse" />
          </motion.div>

          <h1 className="text-5xl md:text-7xl font-bold mb-6 leading-tight">
            <span className="bg-gradient-primary bg-clip-text text-transparent">
              Decentralized
            </span>
            <br />
            <span className="text-foreground">DeFi Insurance</span>
          </h1>

          <p className="text-xl text-muted-foreground mb-8 leading-relaxed">
            Protect your investments with automated, trustless insurance powered by 
            zero-knowledge proofs. No KYC. No committees. Just math.
          </p>

          <div className="flex gap-4 justify-center flex-wrap">
            <Link to="/buy">
              <Button size="lg" className="bg-gradient-primary hover:opacity-90 text-lg px-8">
                Get Started
                <ArrowRight className="ml-2" />
              </Button>
            </Link>
            <Link to="/oracle">
              <Button size="lg" variant="outline" className="text-lg px-8">
                View Oracle
              </Button>
            </Link>
          </div>
        </motion.div>

        {/* Feature Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-20">
          {features.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 + index * 0.1 }}
            >
              <Link to={feature.href}>
                <GlassContainer hover className="p-8 h-full group cursor-pointer">
                  <div className={`w-16 h-16 rounded-lg bg-gradient-to-br ${feature.gradient} flex items-center justify-center mb-6 group-hover:scale-110 transition-transform`}>
                    <feature.icon className={`w-8 h-8 ${feature.iconColor}`} />
                  </div>
                  <h3 className="text-2xl font-bold mb-3 group-hover:text-primary transition-colors">
                    {feature.title}
                  </h3>
                  <p className="text-muted-foreground mb-4">
                    {feature.description}
                  </p>
                  <div className="flex items-center text-primary font-semibold group-hover:gap-2 transition-all">
                    Explore
                    <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
                  </div>
                </GlassContainer>
              </Link>
            </motion.div>
          ))}
        </div>

        {/* Benefits Section */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
        >
          <GlassContainer className="p-12">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
              <div>
                <h2 className="text-4xl font-bold mb-6 bg-gradient-primary bg-clip-text text-transparent">
                  Why DeRisk Protocol?
                </h2>
                <p className="text-lg text-muted-foreground mb-8">
                  The first truly decentralized insurance protocol that removes trust 
                  assumptions and delivers instant, verifiable payouts.
                </p>
                <div className="space-y-4">
                  {benefits.map((benefit, index) => (
                    <motion.div
                      key={benefit}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 1 + index * 0.1 }}
                      className="flex items-center gap-3"
                    >
                      <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
                        <Check className="w-5 h-5 text-primary" />
                      </div>
                      <span className="text-foreground font-medium">{benefit}</span>
                    </motion.div>
                  ))}
                </div>
              </div>

              <div className="relative">
                <div className="aspect-square relative">
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
                    className="absolute inset-0 rounded-full border-2 border-primary/20 border-dashed"
                  />
                  <motion.div
                    animate={{ rotate: -360 }}
                    transition={{ duration: 40, repeat: Infinity, ease: "linear" }}
                    className="absolute inset-8 rounded-full border-2 border-secondary/20 border-dashed"
                  />
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ duration: 50, repeat: Infinity, ease: "linear" }}
                    className="absolute inset-16 rounded-full border-2 border-accent/20 border-dashed"
                  />
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="text-center">
                      <div className="text-6xl font-bold bg-gradient-primary bg-clip-text text-transparent mb-2">
                        100%
                      </div>
                      <div className="text-muted-foreground">
                        Trustless
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </GlassContainer>
        </motion.div>

        {/* Stats Section */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mt-12">
          {[
            { label: 'Protocols Supported', value: '5+' },
            { label: 'Total Value Covered', value: '$0' },
            { label: 'Active Policies', value: '0' },
            { label: 'Avg Response Time', value: '15min' },
          ].map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 1.2 + index * 0.1 }}
            >
              <GlassContainer className="p-6 text-center">
                <div className="text-4xl font-bold bg-gradient-primary bg-clip-text text-transparent mb-2">
                  {stat.value}
                </div>
                <div className="text-sm text-muted-foreground">
                  {stat.label}
                </div>
              </GlassContainer>
            </motion.div>
          ))}
        </div>
      </main>
    </div>
  );
};

export default Home;
