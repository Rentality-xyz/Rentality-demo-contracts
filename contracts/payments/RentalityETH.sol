// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';


import "./RentalityCurrencyType.sol";

contract RentalityETHPayment is ARentalityUpgradableCurrencyType {
    // Interface for Chainlink ETH to USD price feed
    AggregatorV3Interface internal ethToUsdRateFeed;


    function tokenDecimals() public override view returns(uint8) {
        return ethToUsdRateFeed.decimals();
    }

    /// @notice Get the latest ETH to USD rate from the Chainlink rate feed
    /// @return The latest ETH to USD rate
    function getLatest() public override view returns (int256) {
        (, int rate, , , ) = ethToUsdRateFeed.latestRoundData();
        return rate;
    }


    /// @notice Get the amount of ETH equivalent to a specified value in USD cents
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @param ethToUsdRate The specific ETH to USD rate to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return valueInEth The equivalent amount of ETH
    function getFromUsd(
        uint256 valueInUsdCents,
        int256 ethToUsdRate,
        uint8 ethToUsdDecimals
    ) public pure override returns (uint256) {

        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdRate);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @param ethToUsdRate The specific ETH to USD rate to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return The equivalent amount in USD cents
    function getUsd(
        uint256 valueInEth,
        int256 ethToUsdRate,
        uint8 ethToUsdDecimals
    ) public pure override returns (uint256) {
        return ((valueInEth * uint(ethToUsdRate)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }

/// @notice contract initialization function
/// @param _userService address to RentalityUserService
/// @param ethToUsdPriceFeedAddress The address of the Chainlink ETH to USD price feed
    function initialize(address ethToUsdPriceFeedAddress, address _userService) public override initializer {
        //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdRateFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);

        super.initialize(_userService, address (0));


    }
}