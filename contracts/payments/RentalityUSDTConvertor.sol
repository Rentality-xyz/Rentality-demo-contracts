// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityCurrencyType.sol';

contract RentalityUSDTConverter is ARentalityUpgradableCurrencyType {
  /// @notice Converts the specified amount from USD to USDT
  /// @param amount The amount in USD cents
  /// @param rate The specific USDT to USD rate to use for conversion
  /// @param decimals The specific USDT to USD decimals to use for conversion
  /// @return The equivalent amount in USDT

  // 30000 100016719 8 x = 300 000000
  function getFromUsd(uint256 amount, int256 rate, uint8 decimals) public pure override returns (uint256) {
    return (amount * (10 ** 6) / (uint(rate)) * 10 ** 6);
  }

  /// @notice Converts the specified amount from USDT to USD
  /// @param amount The amount in USDT
  /// @param rate The specific USDT to USD rate to use for conversion
  /// @param decimals The specific USDT to USD decimals to use for conversion
  /// @return The equivalent amount in USD cents
  // 299949851 100016719
  function getUsd(uint256 amount, int256 rate, uint8 decimals) public view override returns (uint256) {
    return ((amount * uint(rate)) / (10 ** (currentToUsdDecimals + 6))) * 100;
  }
}
