// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RentalityMockPriceFeed {
  uint8 public decimals;
  int256 public answer;

  constructor(uint8 decimals_, int256 answer_) {
    decimals = decimals_;
    answer = answer_;
  }

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer_, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return (1, answer, block.timestamp, block.timestamp, 1);
  }

  function updateAnswer(int256 newAnswer) external {
    answer = newAnswer;
  }
}
