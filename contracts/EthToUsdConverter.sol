// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IRentalityAccessControl.sol";
import "./proxy/UUPSAccess.sol";
/// @title EthToUsdConverter
/// @dev A contract for converting Ethereum to USD using Chainlink price feeds.
contract EthToUsdConverter is Initializable, UUPSAccess {

    AggregatorV3Interface internal ethToUsdPriceFeed;
    int256 private currentEthToUsdPrice;

    /// @dev Get the latest ETH to USD price from the Chainlink price feed.
    /// @return int256 The latest ETH to USD price
    function getLatestEthToUsdPrice() public view returns (int256) {
        (
        /*uint80 roundID*/,
            int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = ethToUsdPriceFeed.latestRoundData();

        return price; // example price returned: 165110000000
    }

    /// @dev Get the decimals of the price feed.
    /// @return uint8 The decimals of the price feed.
    function getPriceFeedDecimals() public view returns (uint8) {
        return ethToUsdPriceFeed.decimals();
    }

    /// @dev Convert a given USD value to ETH.
    /// @param valueInUsdCents The value in USD cents to convert to ETH.
    /// @return uint256 The equivalent amount in ETH.
    function getEthFromUsd(uint256 valueInUsdCents) public view returns (uint256) {
        return (valueInUsdCents * (1 ether) * (10 ** (getPriceFeedDecimals() - 2))) / uint(getLatestEthToUsdPrice());
    }

    /// @dev Convert a given ETH value to USD.
    /// @param valueInEth to convert to USD.
    /// @return uint256 The equivalent amount in USD.
    function getUsdFromEth(uint256 valueInEth) public view returns (uint256) {
        return (valueInEth * uint(getLatestEthToUsdPrice()) / ((10 ** (getPriceFeedDecimals() - 2)) * (1 ether)));
    }

    /// @dev Constructor function to initialize the contract with the specified Chainlink ETH/USD price feed address.
    /// @param ethToUsdPriceFeedAddress The address of the Chainlink ETH/USD price feed.
    function initialize(address ethToUsdPriceFeedAddress, address _userService) public virtual initializer {
        // ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        // ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        currentEthToUsdPrice = getLatestEthToUsdPrice();
        userService = IRentalityAccessControl(_userService);
    }

}
