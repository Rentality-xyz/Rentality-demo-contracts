// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct InvestmentFundingInfo {
    uint256 targetAmount;
    uint256 fundedAmount;
    address currency;
    bool listed;
    bool inProgress;
}

struct InvestmentPayoutRoute {
    uint256 creatorPercents;
    address pool;
    address currency;
}
