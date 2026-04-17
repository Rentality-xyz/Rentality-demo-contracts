// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IInvestment.sol';

abstract contract InvestmentBase is IInvestment {
    uint256 internal investmentCount;

    mapping(uint256 => uint256) internal investmentIdToFundedAmount;
    mapping(uint256 => address) internal investmentIdToCreator;
    mapping(uint256 => address) internal investmentIdToCurrency;
    mapping(uint256 => bool) internal investmentIdToListed;
    mapping(uint256 => uint256) internal carIdToInvestmentId;

    function getInvestmentCount() public view virtual returns (uint256) {
        return investmentCount;
    }

    function getInvestedAmount(uint256 investmentId) public view virtual returns (uint256) {
        return investmentIdToFundedAmount[investmentId];
    }

    function getCreator(uint256 investmentId) public view virtual returns (address) {
        return investmentIdToCreator[investmentId];
    }

    function _nextInvestmentId() internal returns (uint256) {
        investmentCount += 1;
        return investmentCount;
    }
}
