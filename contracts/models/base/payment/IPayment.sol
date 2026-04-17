// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPayment {
    function getTreasuryBalance(address currencyType) external view returns (uint256);
    function withdrawFromTreasury(uint256 amount, address currencyType, address receiver) external;
}
