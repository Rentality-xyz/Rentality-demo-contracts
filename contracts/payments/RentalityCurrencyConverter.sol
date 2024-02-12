// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../abstract/IRentalityAccessControl.sol";
import '../proxy/UUPSAccess.sol';
import "../Schemas.sol";
import "./RentalityCurrencyType.sol";
// 7.8
// 500 500/7.8
/// @title RentalityCurrencyConverter
/// @notice A contract for converting between Ether (ETH) and United States Dollar (USD) using Chainlink price feeds
/// @dev Users can retrieve the latest ETH to USD price, convert between ETH and USD, and cache the price for efficiency.
contract RentalityCurrencyConverter is Initializable, UUPSAccess {

    mapping(address => ARentalityCurrencyType) private tokenAddressToPaymentMethod;


    function addCurrencyType(address tokenAddress, address rentalityTokenService) public {
        require(userService.isManager(msg.sender), "From manager contract only.");

        tokenAddressToPaymentMethod[tokenAddress] = ARentalityCurrencyType(rentalityTokenService);
    }

    function getTokenFromUsdCents(address currencyType, uint256 amount, int256 toUsdPrice, uint8 decimals) public view returns (uint) {
        return tokenAddressToPaymentMethod[currencyType].getThisFromUsdCents(amount, toUsdPrice, decimals);
    }

    function getLatest(address currencyType) public view returns (int) {
        return tokenAddressToPaymentMethod[currencyType].getLatest();
    }

    function getRate(address currencyType) public view returns (int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getPrice();
    }

    function getFromUsdLatest(address currencyType, uint256 valueInUsdCents) public view returns (uint256, int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getFromUsdLatest(valueInUsdCents);
    }

    function getUsdFromTokenLatest(address currencyType, uint256 tokenValue) public view returns (uint256, int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getUsdFromThisLatest(tokenValue);
    }

    function getUsdFromToken(address currencyType, uint256 tokenValue, int256 tokenToUsd, uint8 decimals) public view returns (uint256) {
        return tokenAddressToPaymentMethod[currencyType].getUsdFromThis(tokenValue, tokenToUsd, decimals);
    }

    function getPriceWithCache(address currencyType) public returns (int256, uint8) {
        return tokenAddressToPaymentMethod[currencyType].getPriceWithCache();
    }

    function getFromUsdWithCache(address currencyType, uint256 valueInUsdCents) public returns (uint256) {
        return tokenAddressToPaymentMethod[currencyType].getFromUsdWithCache(valueInUsdCents);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
    /// @return The equivalent amount in USD cents
    function getUsdFromTokenWithCache(address currencyType, uint256 valueInThis) public returns (uint256) {
        return tokenAddressToPaymentMethod[currencyType].getUsdFromThisWithCache(valueInThis);

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
        tokenAddressToPaymentMethod[address(0)] = ARentalityCurrencyType(ethPaymentAddress);
        userService = IRentalityAccessControl(_userService);
    }
}
