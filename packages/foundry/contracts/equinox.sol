// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { DeRiskOracle } from "./DeRiskOracle.sol";
import { PremiumVault } from "./PremiumVault.sol";

/**
 * @title DeRiskProtocol
 * @notice Main insurance contract - issues policies as ERC-1155 NFTs
 * @dev Parametric insurance: payouts trigger automatically when safety score drops below strike
 */
contract DeRiskProtocol is ERC1155, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    DeRiskOracle public immutable oracle;
    PremiumVault public immutable vault;
    IERC20 public immutable usdc;

    uint256 public nextPolicyId;

    // Policy data structure
    struct PolicyData {
        address protocol; // Protocol being insured (e.g., Aave address)
        uint256 strikeScore; // Trigger score (e.g., 90 = pays out if score < 90)
        uint256 expiry; // Unix timestamp when policy expires
        uint256 payoutAmount; // Amount to pay out in USDC
        address holder; // Original policy buyer (for tracking)
        bool exists; // Flag to check if policy is valid
        bool claimed; // Flag to prevent double claims
    }

    // Policy ID => Policy Data
    mapping(uint256 => PolicyData) public policies;

    // Track total insured amount per protocol (risk management)
    mapping(address => uint256) public totalInsuredPerProtocol;

    // Constants for premium calculation
    uint256 public constant BASIS_POINTS = 10_000;
    uint256 public constant MIN_PREMIUM = 1e6; // 1 USDC (6 decimals)
    uint256 public constant MAX_STRIKE_SCORE = 100;
    uint256 public constant MIN_STRIKE_SCORE = 1;
    uint256 public constant MAX_DURATION_DAYS = 365;
    uint256 public constant MIN_DURATION_DAYS = 1;

    /* ========== EVENTS ========== */

    event PolicyPurchased(
        address indexed buyer,
        uint256 indexed policyId,
        address indexed protocol,
        uint256 strikeScore,
        uint256 expiry,
        uint256 payoutAmount,
        uint256 premium
    );

    event PolicyClaimed(
        address indexed claimer,
        uint256 indexed policyId,
        address indexed protocol,
        uint256 payoutAmount,
        uint256 actualScore
    );

    event PolicyTransferred(uint256 indexed policyId, address indexed from, address indexed to);

    /* ========== ERRORS ========== */

    error DeRiskProtocol__InvalidProtocol();
    error DeRiskProtocol__InvalidStrikeScore();
    error DeRiskProtocol__InvalidDuration();
    error DeRiskProtocol__InvalidPayoutAmount();
    error DeRiskProtocol__PolicyDoesNotExist();
    error DeRiskProtocol__NotPolicyOwner();
    error DeRiskProtocol__PolicyExpired();
    error DeRiskProtocol__PolicyAlreadyClaimed();
    error DeRiskProtocol__StrikeNotBreached();
    error DeRiskProtocol__InsufficientVaultBalance();
    error DeRiskProtocol__PremiumTransferFailed();

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Initialize the DeRisk Protocol
     * @param _oracle Address of DeRiskOracle contract
     * @param _vault Address of PremiumVault contract
     * @param _usdc Address of USDC token
     */
    constructor(address _oracle, address _vault, address _usdc) ERC1155("") Ownable(msg.sender) {
        require(_oracle != address(0), "DeRiskProtocol: zero oracle");
        require(_vault != address(0), "DeRiskProtocol: zero vault");
        require(_usdc != address(0), "DeRiskProtocol: zero usdc");

        oracle = DeRiskOracle(_oracle);
        vault = PremiumVault(_vault);
        usdc = IERC20(_usdc);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Buy insurance policy
     * @param protocol Protocol to insure (e.g., Aave)
     * @param strikeScore Score threshold (pays out if current score < strike)
     * @param durationInDays Policy duration in days
     * @param payoutAmount Amount to receive if claim is valid
     * @return policyId The ID of the newly created policy
     */
    function buyPolicy(address protocol, uint256 strikeScore, uint256 durationInDays, uint256 payoutAmount)
        external
        nonReentrant
        returns (uint256 policyId)
    {
        // ========== VALIDATION ==========

        // Check protocol is registered with oracle
        if (!oracle.isProtocolRegistered(protocol)) {
            revert DeRiskProtocol__InvalidProtocol();
        }

        // Validate strike score
        if (strikeScore < MIN_STRIKE_SCORE || strikeScore > MAX_STRIKE_SCORE) {
            revert DeRiskProtocol__InvalidStrikeScore();
        }

        // Validate duration
        if (durationInDays < MIN_DURATION_DAYS || durationInDays > MAX_DURATION_DAYS) {
            revert DeRiskProtocol__InvalidDuration();
        }

        // Validate payout amount
        if (payoutAmount == 0) {
            revert DeRiskProtocol__InvalidPayoutAmount();
        }

        // Check vault has sufficient balance
        if (vault.totalAssetsInVault() < payoutAmount) {
            revert DeRiskProtocol__InsufficientVaultBalance();
        }

        // ========== PREMIUM CALCULATION ==========

        uint256 premium = calculatePremium(strikeScore, durationInDays, payoutAmount);

        // ========== COLLECT PREMIUM ==========

        // Transfer premium from user to this contract
        usdc.safeTransferFrom(msg.sender, address(this), premium);

        // Approve vault to spend premium
        usdc.approve(address(vault), premium);

        // Deposit premium into vault
        vault.depositPremium(premium);

        // ========== CREATE POLICY ==========

        policyId = nextPolicyId++;
        uint256 expiry = block.timestamp + (durationInDays * 1 days);

        policies[policyId] = PolicyData({
            protocol: protocol,
            strikeScore: strikeScore,
            expiry: expiry,
            payoutAmount: payoutAmount,
            holder: msg.sender,
            exists: true,
            claimed: false
        });

        // Update total insured amount for this protocol
        totalInsuredPerProtocol[protocol] += payoutAmount;

        // Mint ERC-1155 NFT to user (1 token)
        _mint(msg.sender, policyId, 1, "");

        emit PolicyPurchased(msg.sender, policyId, protocol, strikeScore, expiry, payoutAmount, premium);
    }

    /**
     * @notice Claim payout if conditions are met
     * @param policyId The policy ID to claim
     */
    function claimPayout(uint256 policyId) external nonReentrant {
        PolicyData storage policy = policies[policyId];

        // ========== VALIDATION ==========

        // Check policy exists
        if (!policy.exists) {
            revert DeRiskProtocol__PolicyDoesNotExist();
        }

        // Check caller owns the policy NFT
        if (balanceOf(msg.sender, policyId) == 0) {
            revert DeRiskProtocol__NotPolicyOwner();
        }

        // Check policy not expired
        if (block.timestamp >= policy.expiry) {
            revert DeRiskProtocol__PolicyExpired();
        }

        // Check policy not already claimed
        if (policy.claimed) {
            revert DeRiskProtocol__PolicyAlreadyClaimed();
        }

        // ========== CHECK STRIKE CONDITION ==========

        uint256 currentScore = oracle.getScore(policy.protocol);

        // Strike must be breached (current score < strike score)
        if (currentScore >= policy.strikeScore) {
            revert DeRiskProtocol__StrikeNotBreached();
        }

        // ========== PROCESS CLAIM ==========

        // Mark as claimed (BEFORE external calls - CEI pattern)
        policy.claimed = true;

        // Reduce total insured amount for this protocol
        totalInsuredPerProtocol[policy.protocol] -= policy.payoutAmount;

        // Burn the policy NFT
        _burn(msg.sender, policyId, 1);

        // Withdraw from vault and send to claimer
        vault.withdrawForPayout(msg.sender, policy.payoutAmount);

        emit PolicyClaimed(msg.sender, policyId, policy.protocol, policy.payoutAmount, currentScore);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Calculate premium for a policy
     * @param strikeScore Score threshold
     * @param durationInDays Policy duration
     * @param payoutAmount Payout amount
     * @return premium Premium amount in USDC (6 decimals)
     */
    function calculatePremium(uint256 strikeScore, uint256 durationInDays, uint256 payoutAmount)
        public
        pure
        returns (uint256 premium)
    {
        // Risk factor: Lower strike = higher risk = higher premium
        // Strike 90 → Risk = 10% (100 - 90)
        // Strike 70 → Risk = 30% (100 - 70)
        uint256 riskBasisPoints = (100 - strikeScore) * 100;

        // Time factor: Longer duration = more risk exposure
        uint256 timeMultiplier = durationInDays;

        // Premium formula: (payoutAmount * riskBasisPoints * timeMultiplier) / 1,000,000
        // This gives approximately: payoutAmount * risk% * days / 10
        premium = (payoutAmount * riskBasisPoints * timeMultiplier) / 1_000_000;

        // Ensure minimum premium
        if (premium < MIN_PREMIUM) {
            premium = MIN_PREMIUM;
        }

        return premium;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Get policy data
     * @param policyId Policy ID
     * @return Policy data struct
     */
    function getPolicyData(uint256 policyId) external view returns (PolicyData memory) {
        return policies[policyId];
    }

    /**
     * @notice Check if a policy is claimable
     * @param policyId Policy ID
     * @return claimable True if policy can be claimed
     * @return reason Reason if not claimable
     */
    function isClaimable(uint256 policyId) external view returns (bool claimable, string memory reason) {
        PolicyData memory policy = policies[policyId];

        if (!policy.exists) {
            return (false, "Policy does not exist");
        }

        if (policy.claimed) {
            return (false, "Policy already claimed");
        }

        if (block.timestamp >= policy.expiry) {
            return (false, "Policy expired");
        }

        uint256 currentScore = oracle.getScore(policy.protocol);
        if (currentScore >= policy.strikeScore) {
            return (false, "Strike not breached");
        }

        return (true, "");
    }

    /**
     * @notice Get total insured amount for a protocol
     * @param protocol Protocol address
     * @return Total insured amount
     */
    function getTotalInsured(address protocol) external view returns (uint256) {
        return totalInsuredPerProtocol[protocol];
    }

    /**
     * @notice Get current policy count
     * @return Total policies issued
     */
    function getTotalPolicies() external view returns (uint256) {
        return nextPolicyId;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Override to track policy transfers
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override
    {
        super._update(from, to, ids, values);

        // Emit transfer event for each policy (skip mint/burn)
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                emit PolicyTransferred(ids[i], from, to);
            }
        }
    }
}
