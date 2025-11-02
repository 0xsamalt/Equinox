// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal interface for RISC Zero verifier
interface IRiscZeroVerifier {
    /// @notice Verify a RISC Zero receipt
    /// @param seal The encoded cryptographic proof (SNARK or STARK)
    /// @param imageId The identifier for the guest program
    /// @param journalDigest The SHA-256 digest of the journal
    function verify(bytes calldata seal, bytes32 imageId, bytes32 journalDigest) external view;
}

/// @title MinimalVerifier
/// @notice Minimal contract to verify RISC Zero proofs for Aave safety scores
contract MinimalVerifier {
    /// @notice Address of the RISC Zero verifier contract (Sepolia: 0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187)
    IRiscZeroVerifier public verifier;

    /// @notice The Image ID of the guest program we accept (convert AAVE_ID to bytes32)
    bytes32 public immutable guestImageId;

    /// @notice Latest verified safety score (scaled by 10000, so 8000 = 80.00%)
    uint64 public latestSafetyScore;

    /// @notice Total assets in USD (scaled by 1e8)
    uint128 public latestTotalAssets;

    /// @notice Total liabilities in USD (scaled by 1e8)
    uint128 public latestTotalLiabilities;

    /// @notice Timestamp of the latest verified data
    uint64 public latestTimestamp;

    /// @notice Count of successful verifications
    uint256 public verificationCount;

    /// @notice Event emitted when a proof is verified successfully
    event ProofVerified(
        bytes32 indexed imageId, uint64 safetyScore, uint128 totalAssets, uint128 totalLiabilities, uint64 timestamp
    );

    /// @notice Event emitted when verification fails
    event VerificationFailed(bytes32 indexed imageId, string reason);

    constructor(address _verifier, bytes32 _guestImageId) {
        require(_verifier != address(0), "Invalid verifier address");
        require(_guestImageId != bytes32(0), "Invalid image ID");
        verifier = IRiscZeroVerifier(_verifier);
        guestImageId = _guestImageId;
    }

    /// @notice Verify a RISC Zero proof and store the safety score data
    /// @param journal The public outputs from the guest program (48 bytes: u64 + u128 + u128 + u64)
    /// @param seal The ZK proof bytes
    /// @dev Journal structure (little-endian): safety_score(8) + total_assets(16) + total_liabilities(16) + timestamp(8) = 48 bytes
    function verifyAndStore(bytes calldata journal, bytes calldata seal) external {
        require(journal.length == 48, "Invalid journal length: expected 48 bytes");

        // Compute the journal digest (SHA-256)
        bytes32 journalDigest = sha256(journal);

        // Call the RISC Zero verifier - will revert if proof is invalid
        try verifier.verify(seal, guestImageId, journalDigest) {
            // Proof is valid! Decode the journal (little-endian format)
            // Bytes 0-7:   safety_score (u64)
            // Bytes 8-23:  total_assets_usd (u128)
            // Bytes 24-39: total_liabilities_usd (u128)
            // Bytes 40-47: timestamp (u64)

            uint64 safetyScore = _readUint64LE(journal, 0);
            uint128 totalAssets = _readUint128LE(journal, 8);
            uint128 totalLiabilities = _readUint128LE(journal, 24);
            uint64 timestamp = _readUint64LE(journal, 40);

            // Store the verified data
            latestSafetyScore = safetyScore;
            latestTotalAssets = totalAssets;
            latestTotalLiabilities = totalLiabilities;
            latestTimestamp = timestamp;
            verificationCount++;

            // Emit success event
            emit ProofVerified(guestImageId, safetyScore, totalAssets, totalLiabilities, timestamp);
        } catch Error(string memory reason) {
            emit VerificationFailed(guestImageId, reason);
            revert(string(abi.encodePacked("Proof verification failed: ", reason)));
        } catch {
            emit VerificationFailed(guestImageId, "Unknown verification error");
            revert("Proof verification failed: Unknown error");
        }
    }

    /// @notice Check if a proof would be valid without storing data (view function)
    /// @param journal The public outputs from the guest program
    /// @param seal The ZK proof bytes
    /// @return True if the proof is valid
    function checkProof(bytes calldata journal, bytes calldata seal) external view returns (bool) {
        if (journal.length != 48) {
            return false;
        }

        bytes32 journalDigest = sha256(journal);

        try verifier.verify(seal, guestImageId, journalDigest) {
            return true;
        } catch {
            return false;
        }
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /// @notice Get the latest verified safety score as a percentage (e.g., 80.00%)
    /// @return The safety score percentage with 2 decimal places
    function getSafetyScorePercentage() external view returns (uint256) {
        // latestSafetyScore is scaled by 10000, so divide by 100 to get percentage
        return (uint256(latestSafetyScore) * 100) / 10000;
    }

    /// @notice Get all latest verified data
    /// @return safetyScore The safety score (scaled by 10000)
    /// @return totalAssets Total assets in USD (scaled by 1e8)
    /// @return totalLiabilities Total liabilities in USD (scaled by 1e8)
    /// @return timestamp The timestamp of the data
    function getLatestData()
        external
        view
        returns (uint64 safetyScore, uint128 totalAssets, uint128 totalLiabilities, uint64 timestamp)
    {
        return (latestSafetyScore, latestTotalAssets, latestTotalLiabilities, latestTimestamp);
    }

    /// @notice Check if the protocol is healthy (safety score >= 100%)
    /// @return True if safety score indicates solvency
    function isHealthy() external view returns (bool) {
        return latestSafetyScore >= 10000; // 10000 = 100.00%
    }

    // ============================================
    // INTERNAL HELPER FUNCTIONS
    // ============================================

    /// @notice Read a uint64 in little-endian format from bytes
    function _readUint64LE(bytes calldata data, uint256 offset) internal pure returns (uint64) {
        uint64 value = 0;
        for (uint256 i = 0; i < 8; i++) {
            value |= uint64(uint8(data[offset + i])) << (i * 8);
        }
        return value;
    }

    /// @notice Read a uint128 in little-endian format from bytes
    function _readUint128LE(bytes calldata data, uint256 offset) internal pure returns (uint128) {
        uint128 value = 0;
        for (uint256 i = 0; i < 16; i++) {
            value |= uint128(uint8(data[offset + i])) << (i * 8);
        }
        return value;
    }
}
