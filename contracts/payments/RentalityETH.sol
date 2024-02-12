// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../abstract/IRentalityAccessControl.sol";
import '../proxy/UUPSAccess.sol';
import "../Schemas.sol";

import "./RentalityCurrencyType.sol";

contract RentalityETHPayment is Initializable, UUPSAccess, ARentalityCurrencyType {
    // Interface for Chainlink ETH to USD price feed
    AggregatorV3Interface internal ethToUsdRateFeed;

    function getTokenAddress() public override pure returns(address) {
        return address (0);
    }

    function tokenDecimals() public override view returns(uint8) {
        return ethToUsdRateFeed.decimals();
    }

    /// @notice Get the latest ETH to USD rate from the Chainlink rate feed
    /// @return The latest ETH to USD rate
    function getLatest() public override view returns (int256) {
        (, int rate, , , ) = ethToUsdRateFeed.latestRoundData();
        return rate;
    }

    /// @notice Get the current ETH to USD rate and decimals
    /// @return ethToUsdRate The ETH to USD rate
    /// @return ethToUsdDecimals The ETH to USD decimals
    function getRate() public view returns (int256 ethToUsdRate, uint8 ethToUsdDecimals) {
        return (getLatest(), ethToUsdRateFeed.decimals());
    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @return valueInEth The equivalent amount of ETH
    /// @return ethToUsdRate The ETH to USD rate
    /// @return ethToUsdDecimals The ETH to USD decimals
    function getThisValueFromUsdLatest(
        uint256 valueInUsdCents
    ) public view returns (uint256 valueInEth, int256 ethToUsdRate, uint8 ethToUsdDecimals) {
        (int256 rate, uint8 decimals) = getEthToUsdRate();

        return ((valueInUsdCents * (1 ether) * (10 ** (decimals - 2))) / uint(rate), rate, decimals);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @return valueInUsdCents The equivalent amount in USD cents
    /// @return ethToUsdRate The ETH to USD rate
    /// @return ethToUsdDecimals The ETH to USD decimals
    function getUsdValueFromThisLatest(
        uint256 valueInEth
    ) public view returns (uint256 valueInUsdCents, int256 ethToUsdRate, uint8 ethToUsdDecimals) {
        (int256 rate, uint8 decimals) = getEthToUsdRate();

        return (((valueInEth * uint(rate)) / ((10 ** (decimals - 2)) * (1 ether))), rate, decimals);
    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @param ethToUsdRate The specific ETH to USD rate to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return valueInEth The equivalent amount of ETH
    function getThisFromUsd(
        uint256 valueInUsdCents,
        int256 ethToUsdRate,
        uint8 ethToUsdDecimals
    ) public pure returns (uint256) {
        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdRate);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @param ethToUsdRate The specific ETH to USD rate to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return The equivalent amount in USD cents
    function getUsdFromThis(
        uint256 valueInEth,
        int256 ethToUsdRate,
        uint8 ethToUsdDecimals
    ) public pure returns (uint256) {
        return ((valueInEth * uint(ethToUsdRate)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }

    /// @notice Get the ETH to USD rate and decimals with caching
    /// @return ethToUsdRate The ETH to USD rate
    /// @return ethToUsdDecimals The ETH to USD decimals
    function getThisToUsdRateWithCache() public returns (int256 ethToUsdRate, uint8 ethToUsdDecimals) {
        if ((block.timestamp - lastUpdateRateTimeStamp) > updateRateInterval) {
            lastUpdateRateTimeStamp = block.timestamp;
            currentToUsdRate = getLatest();
            currentToUsdDecimals = ethToUsdRateFeed.decimals();
        }
        return (currentToUsdRate, currentToUsdDecimals);
    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents with caching
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @return The equivalent amount of ETH
    function getThisFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256) {
        (int256 ethToUsdRate, uint8 ethToUsdDecimals) = getEthToUsdRateWithCache();

        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdRate);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @return The equivalent amount in USD cents
    function getUsdFromThisWithCache(uint256 valueInEth) public returns (uint256) {
        (int256 ethToUsdRate, uint8 ethToUsdDecimals) = getEthToUsdRateWithCache();

        return ((valueInEth * uint(ethToUsdRate)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }
/// @notice contract initialization function
/// @param _userService address to RentalityUserService
/// @param ethToUsdPriceFeedAddress The address of the Chainlink ETH to USD price feed
    function initialize(address ethToUsdPriceFeedAddress, address _userService) public virtual initializer {
        userService = IRentalityAccessControl(_userService);
    //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdRateFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        (currentToUsdRate, currentToUsdDecimals) = getRate();
    }
}