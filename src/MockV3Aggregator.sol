// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Minimal Chainlink-style mock with latestRoundData() and decimals()
contract MockV3Aggregator {
    uint8 public decimals;
    int256 public answer;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        answer = _initialAnswer;
    }

    /// @notice set a new price (for tests / demo)
    function updateAnswer(int256 _answer) external {
        answer = _answer;
    }

    /// @notice Chainlink-like latestRoundData
    /// returns (roundId, answer, startedAt, updatedAt, answeredInRound)
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 _answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, answer, block.timestamp, block.timestamp, 0);
    }
}
