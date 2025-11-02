import { AbstractBackground } from '@/components/AbstractBackground';
import { Navbar } from '@/components/Navbar';
import { BuyPolicy } from './BuyPolicy';

const BuyPolicyPage = () => {
  return (
    <div className="min-h-screen">
      <AbstractBackground />
      <Navbar />
      
      <main className="container mx-auto px-4 py-8">
        <BuyPolicy />
      </main>
    </div>
  );
};

export default BuyPolicyPage;
