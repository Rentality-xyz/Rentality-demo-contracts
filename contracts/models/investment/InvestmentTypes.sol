// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../car/CarTypes.sol';

struct InvestmentCarRequest {
    CreateCarRequest car;
    bool insuranceRequired;
    uint256 insurancePriceInUsdCents;
}

struct CarInvestment {
    InvestmentCarRequest car;
    uint256 priceInCurrency;
    bool inProgress;
    uint256 creatorPercents;
}

struct InvestmentDTO {
    CarInvestment investment;
    address nft;
    uint256 investmentId;
    uint256 payedInUsd;
    address creator;
    bool isCarBought;
    uint256 income;
    uint256 myIncome;
    uint256 myInvestingSum;
    uint256 listingDate;
    uint256 myTokens;
    uint256 myPart;
    uint256 totalHolders;
    uint256 totalTokens;
    address currency;
    uint256 totalEarnings;
    uint256 userReceivedEarnings;
    string name;
    string symbol;
    uint256 priceInUsdCents;
    uint256 payedInCurrency;
    bool listed;
}

struct ClaimInvestmentDTO {
    string tokenURI;
    uint256 income;
    uint256 myIncome;
}
