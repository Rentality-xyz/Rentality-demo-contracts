// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EthToUsdConverter { 
    
    AggregatorV3Interface internal ethToUsdPriceFeed;
    int256 private currentEthToUsdPrice; 

    constructor(address ethToUsdPriceFeedAddress) {

        //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        currentEthToUsdPrice = getLatestEthToUsdPrice();
    }  
    
    function getLatestEthToUsdPrice() public view returns (int256) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUsdPriceFeed.latestRoundData();

        return price; //  example price returned 165110000000
    }

    function getPriceFeedDecimals() public view returns (uint8) {
        return ethToUsdPriceFeed.decimals(); 
    }
    
    function getEthFromUsd(uint256 valueInUsdCents) public view returns (uint256) {
        return (valueInUsdCents * (1 ether) * (10 ** (getPriceFeedDecimals()-2))) / uint(getLatestEthToUsdPrice());
    }

    function getUsdFromEth(uint256 valueInEth) public view returns (uint256) {
        return (valueInEth * uint(getLatestEthToUsdPrice()) / ((10 ** (getPriceFeedDecimals()-2)) * (1 ether)));
    }
}