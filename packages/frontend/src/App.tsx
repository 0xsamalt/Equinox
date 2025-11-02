import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { WagmiProvider } from "wagmi";
import { RainbowKitProvider, darkTheme } from "@rainbow-me/rainbowkit";
import { wagmiConfig } from "./config/wagmi";
import "@rainbow-me/rainbowkit/styles.css";
import Home from "./pages/Home";
import BuyPolicyPage from "./pages/BuyPolicyPage";
import MyPoliciesPage from "./pages/MyPoliciesPage";
import OraclePage from "./pages/OraclePage";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <WagmiProvider config={wagmiConfig}>
    <QueryClientProvider client={queryClient}>
      <RainbowKitProvider
        theme={darkTheme({
          accentColor: 'hsl(180 100% 50%)',
          accentColorForeground: 'hsl(250 60% 5%)',
          borderRadius: 'large',
          overlayBlur: 'small',
        })}
      >
        <TooltipProvider>
          <Toaster />
          <Sonner />
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/buy" element={<BuyPolicyPage />} />
              <Route path="/policies" element={<MyPoliciesPage />} />
              <Route path="/oracle" element={<OraclePage />} />
              {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
              <Route path="*" element={<NotFound />} />
            </Routes>
          </BrowserRouter>
        </TooltipProvider>
      </RainbowKitProvider>
    </QueryClientProvider>
  </WagmiProvider>
);

export default App;
