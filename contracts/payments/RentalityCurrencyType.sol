// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IERC20.sol';

abstract contract ARentalityCurrencyType {

    // Current ETH to USD rate and decimals
    int256 internal currentToUsdRate;
    uint8 internal currentToUsdDecimals;

    // Update interval for caching the ETH to USD rate
    uint256 public updateRateInterval;

    // Timestamp of the last update of the ETH to USD rate
    uint256 public lastUpdateRateTimeStamp;

    IERC20 public tokenAddress;

    function getTokenAddress() public virtual view returns (address) {
        return address(tokenAddress);
    }

    function getThisFromUsdCents(uint256 amount, int256 toUsdRate, uint8 decimals) public virtual view returns (uint) {
        return amount / uint256(toUsdRate) * (10 ** uint256(decimals));
    }

    function tokenDecimals() public virtual view returns (uint8) {
        return tokenAddress.decimals();
    }

    function getLatest() public virtual view returns (int);

    function getRate() public virtual view returns (int256, uint8);

    function getThisValueFromUsdLatest(uint256 valueInUsdCents) public virtual view returns (uint256, int256, uint8);

    function getUsdValueFromThisLatest(uint256 thisValue) public virtual view returns (uint256, int256, uint8);

    function getUsdFromThis(uint256 thisValue, int256 thisToUsd, uint8 decimals) public virtual view returns (uint256);

    function getThisFromUsd(
        uint256 valueInUsdCents,
        int256 ethToUsdRate,
        uint8 ethToUsdDecimals
    ) public pure returns (uint256);

    function getThisToUsdRateWithCache() public virtual returns (int256, uint8) {
        if ((block.timestamp - lastUpdateRateTimeStamp) > updateRateInterval) {
            lastUpdateRateTimeStamp = block.timestamp;
            currentToUsdRate = getLatest();
            currentToUsdDecimals = tokenDecimals();
        }
        return (currentToUsdRate, currentToUsdDecimals);
    }

    function getThisFromUsdWithCache(uint256 valueInUsdCents) public virtual returns (uint256) {
        ( currentToUsdRate, currentToUsdDecimals) = getRate();

        return getThisFromUsdCents(valueInUsdCents, currentToUsdRate, currentToUsdDecimals);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
    /// @return The equivalent amount in USD cents
    function getUsdFromThisWithCache(uint256 valueInThis) public virtual returns (uint256) {
        (currentToUsdRate, currentToUsdDecimals) = getRate();

        return getUsdFromThis(valueInThis, rate, decimals);

    }

}