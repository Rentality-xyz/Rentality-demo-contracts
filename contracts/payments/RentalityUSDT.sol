// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IERC20.sol';
import "./RentalityCurrencyType.sol";

contract RentalityUSDTPayment is ARentalityCurrencyType {

    function getThisFromUsdCents(uint256 amount, int256, uint8) public override pure returns (uint) {
        return amount;
    }

    function getLatest() public override pure returns (int)
    {
        return 1;
    }

    function getPrice() public override view returns (int256, uint8) {
        return (1, tokenAddress.decimals());
    }

    function getFromUsdLatest(uint256 valueInUsdCents) public override view returns (uint256, int256, uint8) {
        return(valueInUsdCents, 1, tokenAddress.decimals());
    }

    function getUsdFromThisLatest(uint256 thisValue) public override view returns (uint256, int256, uint8) {
        return getFromUsdLatest(thisValue);
    }

    function getUsdFromThis(uint256 thisValue, int256, uint8) public override pure returns (uint256) {
        return thisValue;
    }


}