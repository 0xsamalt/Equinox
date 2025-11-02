// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Equinox.sol";
import "../contracts/Oracle.sol";
import "../contracts/PremiumVault.sol";
import "../contracts/MockUSDC.sol";

contract EquinoxTest is Test {
    EquinoxProtocol equinox;
    Oracle oracle;
    PremiumVault vault;
    MockUSDC usdc;

    address owner = address(0xA11CE);
    address buyer = address(0xB0B);
    address protocol = address(0xC0DE);

    function setUp() public {
        vm.startPrank(owner);
        usdc = new MockUSDC();
        oracle = new Oracle();
        vault = new PremiumVault(IERC20(address(usdc)), "Vault", "vUSDC");
        equinox = new EquinoxProtocol(address(oracle), address(vault), address(usdc));
        vault.setDeRiskProtocol(address(equinox));
        oracle.addProtocol(protocol, 95);
        vm.stopPrank();

        // Mint funds
        usdc.mint(owner, 1_000_000e6);
        usdc.mint(buyer, 10_000e6);
        usdc.mint(address(vault), 1_000_000e6);

        // Fund the vault so it can cover payouts
        vm.startPrank(owner);
        usdc.approve(address(vault), 1_000_000e6);
        vault.deposit(1_000_000e6, owner); // normal ERC4626 deposit
        vm.stopPrank();
    }

    function testBuyPolicyHappyPath() public {
        vm.startPrank(buyer);
        usdc.approve(address(equinox), type(uint256).max);

        uint256 payoutAmount = 1_000e6;
        uint256 strike = 80;
        uint256 duration = 30;

        uint256 premium = equinox.calculatePremium(strike, duration, payoutAmount);

        vm.expectEmit(true, true, true, true);
        emit EquinoxProtocol.PolicyPurchased(
            buyer, 0, protocol, strike, block.timestamp + duration * 1 days, payoutAmount, premium
        );
        uint256 policyId = equinox.buyPolicy(protocol, strike, duration, payoutAmount);
        vm.stopPrank();

        // Check policy minted
        assertEq(equinox.balanceOf(buyer, policyId), 1);
        // Check policy data
        (address _protocol,, uint256 expiry,, address holder,) = _getPolicyData(policyId);
        assertEq(_protocol, protocol);
        assertEq(holder, buyer);
        assertEq(expiry, block.timestamp + duration * 1 days);
    }

    function testBuyPolicyRevertsInvalidProtocol() public {
        vm.startPrank(buyer);
        usdc.approve(address(equinox), type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(EquinoxProtocol.EquinoxProtocol__InvalidProtocol.selector));
        equinox.buyPolicy(address(0xDEAD), 80, 10, 100e6);
        vm.stopPrank();
    }

    function testClaimPayout() public {
        // Buyer buys policy first
        vm.startPrank(buyer);
        usdc.approve(address(equinox), type(uint256).max);
        uint256 policyId = equinox.buyPolicy(protocol, 90, 10, 1_000e6);
        vm.stopPrank();

        // Lower oracle score below strike
        vm.prank(owner);
        oracle.updateScore(protocol, 50);

        // Claim payout
        vm.startPrank(buyer);
        uint256 balanceBefore = usdc.balanceOf(buyer);
        equinox.claimPayout(policyId);
        uint256 balanceAfter = usdc.balanceOf(buyer);
        vm.stopPrank();

        // Verify payout credited
        assertGt(balanceAfter, balanceBefore);
        // Verify NFT burned
        assertEq(equinox.balanceOf(buyer, policyId), 0);

        // Fetch data
        (,,,,, bool claimed) = _getPolicyData(policyId);
        assertTrue(claimed, "should be marked claimed");
    }

    function testCannotClaimIfStrikeNotBreached() public {
        vm.startPrank(buyer);
        usdc.approve(address(equinox), type(uint256).max);
        uint256 policyId = equinox.buyPolicy(protocol, 80, 10, 1_000e6);
        vm.expectRevert(EquinoxProtocol.EquinoxProtocol__StrikeNotBreached.selector);
        equinox.claimPayout(policyId);
        vm.stopPrank();
    }

    function testCalculatePremiumMinBound() public view {
        uint256 premium = equinox.calculatePremium(100, 1, 1e6);
        assertEq(premium, 1e6); // MIN_PREMIUM enforced
    }

    // ======= Internal helper ========
    function _getPolicyData(uint256 policyId)
        internal
        view
        returns (address protocolAddr, uint256 strike, uint256 expiry, uint256 payout, address holder, bool claimed)
    {
        (protocolAddr, strike, expiry, payout, holder,, claimed) = equinox.policies(policyId);
    }
}
