// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../IRentalityAccessControl.sol';
import '../proxy/UUPSAccess.sol';
import "../Schemas.sol";

import "./RentalityCurrencyType.sol";

contract RentalityETHPayment is Initializable, UUPSAccess, ARentalityCurrencyType {
    // Interface for Chainlink ETH to USD price feed
    AggregatorV3Interface internal ethToUsdPriceFeed;

    function getTokenAddress() public override pure returns(address) {
        return address (0);
    }

    function tokenDecimals() public override view returns(uint8) {
        return ethToUsdPriceFeed.decimals();
    }

    /// @notice Get the latest ETH to USD price from the Chainlink price feed
    /// @return The latest ETH to USD price
    function getLatest() public override view returns (int256) {
        (, int price, , ,) = ethToUsdPriceFeed.latestRoundData();
        return price;
    }

/// @notice Get the current ETH to USD price and decimals
/// @return The current ETH to USD price and decimals
    function getPrice() public override view returns (int256, uint8) {
        return (getLatest(), ethToUsdPriceFeed.decimals());
    }

/// @notice Get the amount of ETH equivalent to a specified value in USD cents
/// @param valueInUsdCents The value in USD cents to convert to ETH
/// @return The equivalent amount of ETH, ETH to USD price, and ETH to USD decimals
    function getFromUsdLatest(uint256 valueInUsdCents) public override view returns (uint256, int256, uint8) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getPrice();

        return (
            (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdPrice),
            ethToUsdPrice,
            ethToUsdDecimals
        );
    }

/// @notice Get the amount of USD cents equivalent to a specified amount of ETH
/// @param valueInEth The amount of ETH to convert to USD cents
/// @return The equivalent amount in USD cents, ETH to USD price, and ETH to USD decimals
    function getUsdFromThisLatest(uint256 valueInEth) public override view returns (uint256, int256, uint8) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getPrice();

        return (
            ((valueInEth * uint(ethToUsdPrice)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether))),
            ethToUsdPrice,
            ethToUsdDecimals
        );
    }

    function getThisFromUsdCents(uint256 valueInUsdCents, int256 ethToUsdPrice, uint8 decimals) public override view returns (uint) {
        return getEthFromUsd(valueInUsdCents, ethToUsdPrice, decimals);

    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @param ethToUsdPrice The specific ETH to USD price to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return The equivalent amount of ETH
    function getEthFromUsd(
        uint256 valueInUsdCents,
        int256 ethToUsdPrice,
        uint8 ethToUsdDecimals
    ) public pure returns (uint256) {
        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdPrice);
    }

/// @notice Get the amount of USD cents equivalent to a specified amount of ETH
/// @param valueInEth The amount of ETH to convert to USD cents
/// @param ethToUsdPrice The specific ETH to USD price to use for conversion
/// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
/// @return The equivalent amount in USD cents
    function getUsdFromThis(
        uint256 valueInEth,
        int256 ethToUsdPrice,
        uint8 ethToUsdDecimals
    ) public override pure returns (uint256) {
        return ((valueInEth * uint(ethToUsdPrice)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }


/// @notice Get the amount of ETH equivalent to a specified value in USD cents with caching
/// @param valueInUsdCents The value in USD cents to convert to ETH
/// @return The equivalent amount of ETH
    function getFromUsdWithCache(uint256 valueInUsdCents) public override returns (uint256) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getPriceWithCache();

        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdPrice);
    }

/// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
/// @param valueInEth The amount of ETH to convert to USD cents
/// @return The equivalent amount in USD cents
    function getUsdFromThisWithCache(uint256 valueInEth) public override returns (uint256) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getPriceWithCache();

        return ((valueInEth * uint(ethToUsdPrice)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }
/// @notice contract initialization function
/// @param _userService address to RentalityUserService
/// @param ethToUsdPriceFeedAddress The address of the Chainlink ETH to USD price feed
    function initialize(address ethToUsdPriceFeedAddress, address _userService) public virtual initializer {
        userService = IRentalityAccessControl(_userService);
    //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        (currentToUsdPrice, currentToUsdDecimals) = getPrice();
    }
}