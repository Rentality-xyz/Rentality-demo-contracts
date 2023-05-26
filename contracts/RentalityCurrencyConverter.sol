// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A
contract RentalityCurrencyConverter {
    AggregatorV3Interface internal ethToUsdPriceFeed;
    int256 private currentEthToUsdPrice;
    uint8 private currentEthToUsdDecimals;
    uint256 public updatePriceInterval;
    uint256 public lastUpdatePriceTimeStamp;

    constructor(address ethToUsdPriceFeedAddress) {
        //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        (currentEthToUsdPrice, currentEthToUsdDecimals) = getEthToUsdPrice();
    }

    function getLatestEthToUsdPrice() private view returns (int256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUsdPriceFeed.latestRoundData();

        return price; //  example price returned 165110000000
    }

    function getEthToUsdPrice() public view returns (int256, uint8) {
        return (getLatestEthToUsdPrice(), ethToUsdPriceFeed.decimals());
    }

    function getEthFromUsd(uint256 valueInUsdCents) public view returns (uint256) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getEthToUsdPrice();

        return
            (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) /
            uint(ethToUsdPrice);
    }

    function getUsdFromEth(uint256 valueInEth) public view returns (uint256) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getEthToUsdPrice();

        return ((valueInEth * uint(ethToUsdPrice)) /
            ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }

    function getEthToUsdPriceWithCache() public returns (int256, uint8) {
        if ((block.timestamp - lastUpdatePriceTimeStamp) > updatePriceInterval) {
            lastUpdatePriceTimeStamp = block.timestamp;
            currentEthToUsdPrice = getLatestEthToUsdPrice();
            currentEthToUsdDecimals = ethToUsdPriceFeed.decimals();
        }
        return (currentEthToUsdPrice, currentEthToUsdDecimals);
    }

    function getEthFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256) {
        (int256 ethToUsdPrice,uint8 ethToUsdDecimals) = getEthToUsdPriceWithCache();

        return
            (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) /
            uint(ethToUsdPrice);
    }

    function getUsdFromEthWithCache(uint256 valueInEth) public returns (uint256) {
        (int256 ethToUsdPrice,uint8 ethToUsdDecimals) = getEthToUsdPriceWithCache();

        return ((valueInEth * uint(ethToUsdPrice)) /
            ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }
}
