// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './RentalityCurrencyType.sol';

contract RentalityETHPayment is ARentalityUpgradableCurrencyType {
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
}
