// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/MockUSDC.sol";
import "../contracts/PremiumVault.sol";

contract PremiumVaultTest is Test {
    MockUSDC usdc;
    PremiumVault vault;

    address owner = address(this);
    address user1 = makeAddr("user1");
    address deRiskProtocol = makeAddr("deRisk");
    address user2 = makeAddr("user2");

    function setUp() public {
        usdc = new MockUSDC();
        vault = new PremiumVault(usdc, "DeRisk Vault", "DRV");

        // Mint some USDC to Alice
        usdc.mint(user1, 100_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testInitialSetup() public {
        assertEq(vault.asset(), address(usdc));
        assertEq(vault.name(), "DeRisk Vault");
        assertEq(vault.symbol(), "DRV");
        assertEq(vault.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositPremium() public {
        uint256 beforeVault = usdc.balanceOf(address(vault));
        vm.startPrank(user1);
        usdc.approve(address(vault), 10_000e6);

        vault.depositPremium(10_000e6);
        vm.stopPrank();

        uint256 afterVault = usdc.balanceOf(address(vault));

        assertEq(afterVault - beforeVault, 10_000e6);
        assertEq(vault.totalAssets(), afterVault);
    }

    function testDepositZeroReverts() public {
        vm.expectRevert(PremiumVault.PremiumVault__ZeroDeposit.selector);
        vault.depositPremium(0);
    }

    /*//////////////////////////////////////////////////////////////
                            PAYOUT TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetDeRiskProtocol() public {
        vault.setDeRiskProtocol(deRiskProtocol);
        assertEq(vault.equinoxProtocol(), deRiskProtocol);
    }

    function testWithdrawForPayout() public {
        // Step 1: Deposit by Alice
        vm.startPrank(user1);
        usdc.approve(address(vault), 20_000e6);
        vault.depositPremium(20_000e6);
        vm.stopPrank();

        // Step 2: Set protocol and withdraw payout
        vault.setDeRiskProtocol(deRiskProtocol);

        uint256 beforeTo = usdc.balanceOf(user2);
        uint256 beforeVault = usdc.balanceOf(address(vault));

        vm.startPrank(deRiskProtocol);
        vault.withdrawForPayout(user2, 5_000e6);
        vm.stopPrank();

        uint256 afterTo = usdc.balanceOf(user2);
        uint256 afterVault = usdc.balanceOf(address(vault));

        assertEq(afterTo - beforeTo, 5_000e6);
        assertEq(beforeVault - afterVault, 5_000e6);
    }

    function testNonProtocolCannotWithdraw() public {
        vm.expectRevert("PremiumVault: caller not DeRiskProtocol");
        vault.withdrawForPayout(user2, 1_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY WITHDRAW TEST
    //////////////////////////////////////////////////////////////*/

    function testEmergencyWithdrawByOwner() public {
        // Step 1: Simulate some stuck USDC in the vault
        usdc.mint(address(vault), 50_000e6);
        uint256 beforeVault = usdc.balanceOf(address(vault));
        uint256 beforeOwner = usdc.balanceOf(owner);

        // Step 2: Perform emergency withdraw by owner
        vm.expectEmit(true, true, true, true);
        emit PremiumVault.EmergencyWithdraw(owner, 10_000e6);
        vault.emergencyWithdraw(address(usdc), owner, 10_000e6);

        // Step 3: Verify balances updated correctly
        uint256 afterVault = usdc.balanceOf(address(vault));
        uint256 afterOwner = usdc.balanceOf(owner);

        assertEq(beforeVault - afterVault, 10_000e6);
        assertEq(afterOwner - beforeOwner, 10_000e6);
    }
}
