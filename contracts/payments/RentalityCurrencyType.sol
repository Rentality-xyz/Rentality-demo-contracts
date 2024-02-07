// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IERC20.sol';

abstract contract ARentalityCurrencyType {
    IERC20 internal tokenAddress;

    uint256 internal updatePriceInterval;
    uint256 internal lastUpdatePriceTimeStamp;

    int256 internal currentToUsdPrice;
    uint8 internal currentToUsdDecimals;

    function getTokenAddress() public virtual view returns (address) {
        return address (tokenAddress);
    }

    function getThisFromUsdCents(uint256 amount, int256 toUsdPrice, uint8 decimals) public virtual view returns (uint) {
        return amount / uint256(toUsdPrice) * (10 ** uint256(decimals));
    }
    function tokenDecimals() public virtual view returns(uint8) {
        return tokenAddress.decimals();
    }
    function getLatest() public virtual view returns (int);

    function getPrice() public virtual view returns (int256, uint8);

    function getFromUsdLatest(uint256 valueInUsdCents) public virtual view returns (uint256, int256, uint8);

    function getUsdFromThisLatest(uint256 thisValue) public virtual view returns (uint256, int256, uint8);

    function getUsdFromThis(uint256 thisValue, int256 thisToUsd, uint8 decimals) public virtual pure returns (uint256);

    function getPriceWithCache() public virtual returns (int256, uint8) {
        if ((block.timestamp - lastUpdatePriceTimeStamp) > updatePriceInterval) {
            lastUpdatePriceTimeStamp = block.timestamp;
            currentToUsdPrice = getLatest();
            currentToUsdDecimals = decimals();
        }
        return (currentToUsdPrice, currentToUsdDecimals);
    }

    function getFromUsdWithCache(uint256 valueInUsdCents) public virtual returns (uint256) {
        (int price, uint8 decimals) = getPriceWithCache();

        return getThisFromUsdCents(valueInUsdCents, price, decimals);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @return The equivalent amount in USD cents
    function getUsdFromThisWithCache(uint256 valueInThis) public virtual returns (uint256) {
        (int price, uint8 decimals) = getPriceWithCache();

        return getUsdFromThis(valueInThis, price, decimals);

    }

}