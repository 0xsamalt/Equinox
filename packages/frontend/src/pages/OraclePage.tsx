import { AbstractBackground } from '@/components/AbstractBackground';
import { Navbar } from '@/components/Navbar';
import { Oracle } from './Oracle';

const OraclePage = () => {
  return (
    <div className="min-h-screen">
      <AbstractBackground />
      <Navbar />
      
      <main className="container mx-auto px-4 py-8">
        <Oracle />
      </main>
    </div>
  );
};

export default OraclePage;
