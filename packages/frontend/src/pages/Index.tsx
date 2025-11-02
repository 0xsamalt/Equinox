import { useState } from 'react';
import { AnimatedBackground } from '@/components/AnimatedBackground';
import { Navbar } from '@/components/Navbar';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BuyPolicy } from './BuyPolicy';
import { MyPolicies } from './MyPolicies';
import { Oracle } from './Oracle';
import { ShoppingCart, Briefcase, Activity } from 'lucide-react';
import { motion } from 'framer-motion';

const Index = () => {
  const [activeTab, setActiveTab] = useState('buy');

  return (
    <div className="min-h-screen">
      <AnimatedBackground />
      <Navbar />
      
      <main className="container mx-auto px-4 py-8">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <TabsList className="grid w-full max-w-2xl mx-auto grid-cols-3 bg-white/5 backdrop-blur-glass border border-white/10 p-1">
              <TabsTrigger
                value="buy"
                className="data-[state=active]:bg-gradient-primary data-[state=active]:text-primary-foreground"
              >
                <ShoppingCart className="w-4 h-4 mr-2" />
                Buy Policy
              </TabsTrigger>
              <TabsTrigger
                value="policies"
                className="data-[state=active]:bg-gradient-primary data-[state=active]:text-primary-foreground"
              >
                <Briefcase className="w-4 h-4 mr-2" />
                My Policies
              </TabsTrigger>
              <TabsTrigger
                value="oracle"
                className="data-[state=active]:bg-gradient-primary data-[state=active]:text-primary-foreground"
              >
                <Activity className="w-4 h-4 mr-2" />
                Oracle
              </TabsTrigger>
            </TabsList>
          </motion.div>

          <div className="mt-8">
            <TabsContent value="buy" className="mt-0">
              <BuyPolicy />
            </TabsContent>

            <TabsContent value="policies" className="mt-0">
              <MyPolicies />
            </TabsContent>

            <TabsContent value="oracle" className="mt-0">
              <Oracle />
            </TabsContent>
          </div>
        </Tabs>
      </main>
    </div>
  );
};

export default Index;
