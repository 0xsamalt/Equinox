// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Minimal interface for RISC Zero verifier
interface IRiscZeroVerifier {
    function verify(bytes calldata seal, bytes32 imageId, bytes32 journalDigest) external view;
}

/**
 * @title Oracle
 * @notice Hybrid oracle - manual updates for hackathon, ZK proofs for production
 * @dev Single contract supporting both modes simultaneously
 */
contract Oracle is Ownable {
    /* ========== STATE VARIABLES ========== */

    // Core protocol tracking
    mapping(address => uint256) public safetyScores; // 0-100 scale
    mapping(address => bool) public isProtocolRegistered;
    address[] public registeredProtocols;

    // ZK verification
    IRiscZeroVerifier public riscZeroVerifier;
    mapping(address => bytes32) public protocolImageIds;

    // Additional analytics from ZK proofs
    struct ProtocolMetrics {
        uint128 totalAssets; // USD value (scaled by 1e8)
        uint128 totalLiabilities; // USD value (scaled by 1e8)
        uint64 lastUpdateTime;
        uint64 zkVerificationCount;
    }

    mapping(address => ProtocolMetrics) public protocolMetrics;

    /* ========== EVENTS ========== */

    event ProtocolAdded(address indexed protocol, uint256 initialScore);
    event ScoreUpdated(address indexed protocol, uint256 oldScore, uint256 newScore, string updateType);
    event VerifierConfigured(address indexed verifier);
    event ImageIdConfigured(address indexed protocol, bytes32 imageId);

    /* ========== CONSTRUCTOR ========== */

    constructor() Ownable(msg.sender) { }

    /* ========== CORE FUNCTIONS ========== */

    /**
     * @notice Register a new protocol
     * @param protocol Protocol address
     * @param initialScore Initial safety score (0-100)
     */
    function addProtocol(address protocol, uint256 initialScore) external onlyOwner {
        require(protocol != address(0), "Invalid protocol address");
        require(!isProtocolRegistered[protocol], "Protocol already registered");
        require(initialScore <= 100, "Score must be <= 100");

        isProtocolRegistered[protocol] = true;
        safetyScores[protocol] = initialScore;
        registeredProtocols.push(protocol);

        emit ProtocolAdded(protocol, initialScore);
    }

    /**
     * @notice Manual score update (for hackathon/testing)
     * @param protocol Protocol to update
     * @param newScore New safety score (0-100)
     */
    function updateScore(address protocol, uint256 newScore) external onlyOwner {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        require(newScore <= 100, "Score must be <= 100");

        uint256 oldScore = safetyScores[protocol];
        safetyScores[protocol] = newScore;

        protocolMetrics[protocol].lastUpdateTime = uint64(block.timestamp);

        emit ScoreUpdated(protocol, oldScore, newScore, "manual");
    }

    /* ========== ZK VERIFICATION ========== */

    /**
     * @notice Configure RISC Zero verifier (one-time setup)
     * @param _verifier Verifier contract address (Sepolia: 0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187)
     */
    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier");
        riscZeroVerifier = IRiscZeroVerifier(_verifier);
        emit VerifierConfigured(_verifier);
    }

    /**
     * @notice Set approved guest program for a protocol
     * @param protocol Protocol address
     * @param imageId RISC Zero Image ID (guest program hash)
     */
    function setImageId(address protocol, bytes32 imageId) external onlyOwner {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        require(imageId != bytes32(0), "Invalid image ID");
        protocolImageIds[protocol] = imageId;
        emit ImageIdConfigured(protocol, imageId);
    }

    /**
     * @notice Update score with ZK proof (production mode)
     * @param protocol Protocol to update
     * @param journal Public outputs (48 bytes: u64 + u128 + u128 + u64)
     * @param seal ZK proof
     */
    function updateScoreWithProof(address protocol, bytes calldata journal, bytes calldata seal) external {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        require(address(riscZeroVerifier) != address(0), "Verifier not configured");
        require(journal.length == 48, "Invalid journal length");

        bytes32 imageId = protocolImageIds[protocol];
        require(imageId != bytes32(0), "Image ID not set for protocol");

        // Verify proof
        bytes32 journalDigest = sha256(journal);
        try riscZeroVerifier.verify(seal, imageId, journalDigest) {
            // Decode journal (little-endian)
            uint64 safetyScoreBP = _readUint64LE(journal, 0); // Basis points (10000 = 100%)
            uint128 totalAssets = _readUint128LE(journal, 8);
            uint128 totalLiabilities = _readUint128LE(journal, 24);
            uint64 timestamp = _readUint64LE(journal, 40);

            // Convert from basis points to 0-100 scale
            uint256 scoreOutOf100 = (uint256(safetyScoreBP) * 100) / 10000;
            if (scoreOutOf100 > 100) scoreOutOf100 = 100;

            // Update state
            uint256 oldScore = safetyScores[protocol];
            safetyScores[protocol] = scoreOutOf100;

            ProtocolMetrics storage metrics = protocolMetrics[protocol];
            metrics.totalAssets = totalAssets;
            metrics.totalLiabilities = totalLiabilities;
            metrics.lastUpdateTime = timestamp;
            metrics.zkVerificationCount++;

            emit ScoreUpdated(protocol, oldScore, scoreOutOf100, "zk-proof");
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("ZK verification failed: ", reason)));
        } catch {
            revert("ZK verification failed");
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getScore(address protocol) external view returns (uint256) {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        return safetyScores[protocol];
    }

    function getRegisteredProtocols() external view returns (address[] memory) {
        return registeredProtocols;
    }

    function getProtocolMetrics(address protocol)
        external
        view
        returns (
            uint256 score,
            uint128 totalAssets,
            uint128 totalLiabilities,
            uint64 lastUpdate,
            uint64 zkVerifications
        )
    {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        ProtocolMetrics memory metrics = protocolMetrics[protocol];
        return (
            safetyScores[protocol],
            metrics.totalAssets,
            metrics.totalLiabilities,
            metrics.lastUpdateTime,
            metrics.zkVerificationCount
        );
    }

    function isZKEnabled(address protocol) external view returns (bool) {
        return address(riscZeroVerifier) != address(0) && protocolImageIds[protocol] != bytes32(0);
    }

    /* ========== INTERNAL HELPERS ========== */

    function _readUint64LE(bytes calldata data, uint256 offset) internal pure returns (uint64) {
        uint64 value = 0;
        for (uint256 i = 0; i < 8; i++) {
            value |= uint64(uint8(data[offset + i])) << (i * 8);
        }
        return value;
    }

    function _readUint128LE(bytes calldata data, uint256 offset) internal pure returns (uint128) {
        uint128 value = 0;
        for (uint256 i = 0; i < 16; i++) {
            value |= uint128(uint8(data[offset + i])) << (i * 8);
        }
        return value;
    }
}
