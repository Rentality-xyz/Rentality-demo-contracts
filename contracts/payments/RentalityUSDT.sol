// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityCurrencyType.sol";


contract RentalityUSDTPayment is ARentalityUpgradableCurrencyType {


    function getLatest() public override pure returns (int)
    {
        return 100;
    }

    function getFromUsd(uint256 amount, int256, uint8) public pure override returns (uint256) {
        return (amount * 10**6) / uint(getLatest());
    }

    function getUsd(uint256 amount, int256, uint8) public pure override returns (uint256) {
        return (amount * uint(getLatest())) / (10**6);
    }


}