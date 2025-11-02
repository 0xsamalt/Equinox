import { AbstractBackground } from '@/components/AbstractBackground';
import { Navbar } from '@/components/Navbar';
import { MyPolicies } from './MyPolicies';

const MyPoliciesPage = () => {
  return (
    <div className="min-h-screen">
      <AbstractBackground />
      <Navbar />
      
      <main className="container mx-auto px-4 py-8">
        <MyPolicies />
      </main>
    </div>
  );
};

export default MyPoliciesPage;
