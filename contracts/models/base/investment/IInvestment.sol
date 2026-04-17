// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './InvestmentTypes.sol';

interface IInvestment {
    function getInvestmentCount() external view returns (uint256);
    function getInvestedAmount(uint256 investmentId) external view returns (uint256);
    function getCreator(uint256 investmentId) external view returns (address);
    function getFundingInfo(uint256 investmentId) external view returns (InvestmentFundingInfo memory);
    function getPaymentsInfo(uint256 carId)
        external
        view
        returns (InvestmentPayoutRoute memory payoutRoute);
}
