// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../abstract/IRentalityAccessControl.sol";
import '../proxy/UUPSAccess.sol';
import "../Schemas.sol";
import "./RentalityCurrencyType.sol";

/// @title RentalityCurrencygeter
/// @notice A contract for geting between Ether (ETH) and United States Dollar (USD) using Chainlink price feeds
/// @dev Users can retrieve the latest ETH to USD price, get between ETH and USD, and cache the price for efficiency.
contract RentalityCurrencyConverter is Initializable, UUPSAccess {

    mapping(address => ARentalityUpgradableCurrencyType) private tokenAddressToPaymentMethod;


    function addCurrencyType(address tokenAddress, address rentalityTokenService) public {
        require(userService.isManager(msg.sender), "From manager contract only.");

        tokenAddressToPaymentMethod[tokenAddress] = ARentalityUpgradableCurrencyType(rentalityTokenService);
    }

    function getFromUsd(address currencyType, uint256 amount, int256 currencyRate, uint8 decimals) public view returns (uint) {
        return tokenAddressToPaymentMethod[currencyType].getFromUsd(amount, currencyRate, decimals);
    }

    function getLatest(address currencyType) public view returns (int) {
        return tokenAddressToPaymentMethod[currencyType].getLatest();
    }

    function getRate(address currencyType) public view returns (int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getRate();
    }

    function getFromUsdLatest(address currencyType, uint256 valueInUsdCents) public view returns (uint256, int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getFromUsdLatest(valueInUsdCents);
    }

    function getToUsdLatest(address currencyType, uint256 amount) public view returns (uint256, int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getUsdFromLatest(amount);
    }

    function getToUsd(address currencyType, uint256 tokenValue, int256 tokenToUsd, uint8 decimals) public view returns (uint256) {
        return tokenAddressToPaymentMethod[currencyType].getUsd(tokenValue, tokenToUsd, decimals);
    }

    function getCurrencyRateWithCache(address currencyType) public returns (int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getRateWithCache();
    }

    function getFromUsdWithCache(address currencyType, uint256 valueInUsdCents) public returns (uint256) {
        return tokenAddressToPaymentMethod[currencyType].getFromUsdWithCache(valueInUsdCents);
    }

    /// @return The equivalent amount in USD cents
    function getToUsdWithCache(address currencyType, uint256 amount) public returns (uint256) {
        return tokenAddressToPaymentMethod[currencyType].getUsdWithCache(amount);

    }

    function currencyTypeIsAvailable(address currencyType) public view returns (bool) {
        return address(tokenAddressToPaymentMethod[currencyType]) != address(0);
    }

    function isNative(address currencyType) public pure returns(bool) {
        return currencyType == address (0);
    }

    /// @notice contract initialization function
    /// @param _userService address to RentalityUserService
    function initialize(address _userService, address ethPaymentAddress) public virtual initializer {
        tokenAddressToPaymentMethod[address(0)] = ARentalityUpgradableCurrencyType(ethPaymentAddress);
        userService = IRentalityAccessControl(_userService);
    }
}
