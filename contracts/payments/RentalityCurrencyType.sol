// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IERC20.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../abstract/IRentalityAccessControl.sol";
import '../proxy/UUPSAccess.sol';

abstract contract ARentalityUpgradableCurrencyType is Initializable, UUPSAccess {

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

    function tokenDecimals() public virtual view returns (uint8) {
        return tokenAddress.decimals();
    }

    function getLatest() public virtual view returns (int);

    function getFromUsd(uint256, int256, uint8) public pure virtual returns (uint256);

    function getUsd(uint256, int256, uint8) public pure virtual returns (uint256);

    function getRate() public virtual view returns (int256, uint8) {
        return (getLatest(), tokenDecimals());
    }

    function getFromUsdLatest(uint256 amount) public view returns (uint256, int256, uint8) {
        (int256 rate, uint8 decimals) = getRate();

        return (getFromUsd(amount, rate, decimals), rate, decimals);
    }

    function getUsdFromLatest(uint256 amount) public view returns (uint256, int256, uint8) {
        (int256 rate, uint8 decimals) = getRate();

        return (getUsd(amount, rate, decimals), rate, decimals);
    }

    function getRateWithCache() public returns (int256, uint8) {
        if ((block.timestamp - lastUpdateRateTimeStamp) > updateRateInterval) {
            lastUpdateRateTimeStamp = block.timestamp;
            currentToUsdRate = getLatest();
            currentToUsdDecimals = tokenDecimals();
        }
        return (currentToUsdRate, currentToUsdDecimals);
    }

    function getFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256) {
        (int256 rate, uint8 decimals) = getRateWithCache();

        return getFromUsd(valueInUsdCents, rate, decimals);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
    /// @return The equivalent amount in USD cents
    function getUsdWithCache(uint256 valueInThis) public returns (uint256) {
        (int256 rate, uint8 decimals) = getRateWithCache();

        return getUsd(valueInThis, rate, decimals);

    }
    function initialize( address _userService, address _tokenAddress) public virtual initializer {
        userService = IRentalityAccessControl(_userService);
        tokenAddress = IERC20(_tokenAddress);

        (currentToUsdRate, currentToUsdDecimals) = getRate();
    }

}