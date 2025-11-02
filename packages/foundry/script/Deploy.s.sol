// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import { EquinoxProtocol } from "../contracts/Equinox.sol";
import { Oracle } from "../contracts/Oracle.sol";
import { PremiumVault } from "../contracts/PremiumVault.sol";
import { MockUSDC } from "../contracts/MockUSDC.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // 1. Deploy MockUSDC
        MockUSDC usdc = new MockUSDC();

        // 2. Deploy Oracle
        Oracle oracle = new Oracle();

        // 3. Deploy PremiumVault
        PremiumVault vault = new PremiumVault(usdc, "Premium Vault", "pVAULT");

        // 4. Deploy EquinoxProtocol
        EquinoxProtocol equinox = new EquinoxProtocol(address(oracle), address(vault), address(usdc));

        // 5. Set the vault’s DeRiskProtocol to Equinox
        vault.setDeRiskProtocol(address(equinox));

        vm.stopBroadcast();

        console.log("MockUSDC:", address(usdc));
        console.log("Oracle:", address(oracle));
        console.log("PremiumVault:", address(vault));
        console.log("EquinoxProtocol:", address(equinox));
    }
}
