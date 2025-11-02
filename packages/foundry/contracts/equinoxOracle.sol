// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DeRiskOracle
 * @notice Mock oracle for protocol safety scores
 * @dev In production
 */
contract DeRiskOracle is Ownable {
    //protocol address => safety score (0-100)
    mapping(address => uint256) public safetyScores;

    //track registered protocols
    mapping(address => bool) public isProtocolRegistered;
    address[] public registeredProtocols;

    event ProtocolAdded(address indexed protocol, uint256 initialScore);
    event ScoreUpdated(address indexed protocol, uint256 oldScore, uint256 newScore);

    constructor() Ownable(msg.sender) { }

    //function for adding new protocols
    function addProtocol(address protocol, uint256 initialScore) external onlyOwner {
        require(protocol != address(0), "Invalid protocol address");
        require(!isProtocolRegistered[protocol], "Protocol already registered");
        require(initialScore <= 100, "Score must be <= 100");

        isProtocolRegistered[protocol] = true;
        safetyScores[protocol] = initialScore;
        registeredProtocols.push(protocol);

        emit ProtocolAdded(protocol, initialScore);
    }

    //Manuak score update function for now
    function updateScore(address protocol, uint256 newScore) external onlyOwner {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        require(newScore <= 100, "Score must be <= 100");

        uint256 oldScore = safetyScores[protocol];
        safetyScores[protocol] = newScore;

        emit ScoreUpdated(protocol, oldScore, newScore);
    }

    ////////////////////
    /// Getter Functions
    ////////////////////

    function getScore(address protocol) external view returns (uint256) {
        require(isProtocolRegistered[protocol], "Protocol not registered");
        return safetyScores[protocol];
    }

    function getRegisteredProtocols() external view returns (address[] memory) {
        return registeredProtocols;
    }
}
