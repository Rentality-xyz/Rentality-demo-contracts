// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IRentalityAccessControl.sol';
import './proxy/UUPSOwnable.sol';
import './RentalityTripService.sol';

/// @title Rentality Payment Service Contract
/// @notice This contract manages platform fees and allows the adjustment of the platform fee by the manager.
/// @dev It is connected to RentalityUserService to check if the caller is an admin.
contract RentalityPaymentService is UUPSOwnable {
  uint32 platformFeeInPPM;
  IRentalityAccessControl private userService;

  /// @dev Enumeration representing the currency type used for payments.
  enum CurrencyType {
    ETH
  }

  /// @dev Struct containing payment information for a trip.
  struct PaymentInfo {
    uint256 tripId;
    address from;
    address to;
    uint64 totalDayPriceInUsdCents;
    uint64 taxPriceInUsdCents;
    uint64 depositInUsdCents;
    uint64 resolveAmountInUsdCents;
    CurrencyType currencyType;
    int256 ethToCurrencyRate;
    uint8 ethToCurrencyDecimals;
    uint64 resolveFuelAmountInUsdCents;
    uint64 resolveMilesAmountInUsdCents;
  }

  // Struct to store transaction history details for a trip
  struct TransactionInfo {
    uint256 rentalityFee;
    uint256 depositRefund;
    // Earnings from the trip (cancellation or completion)
    uint256 tripEarnings;
    // Timestamp of the transaction
    uint256 dateTime;
    // Status before trip cancellation, will be 'Finished' in case of completed trip.
    RentalityTripService.TripStatus statusBeforeCancellation;
  }

  /// @notice Get the current platform fee in parts per million (PPM).
  /// @return The current platform fee in PPM.
  function getPlatformFeeInPPM() public view returns (uint32) {
    return platformFeeInPPM;
  }

  /// @notice Set the platform fee in parts per million (PPM).
  /// @param valueInPPM The new value for the platform fee in PPM.
  /// @dev Only callable by an admin. The value must be positive and not exceed 1,000,000.
  function setPlatformFeeInPPM(uint32 valueInPPM) public {
    require(userService.isAdmin(msg.sender), 'Only manager can change the platform fee');
    require(valueInPPM > 0, "Make sure the value isn't negative");
    require(valueInPPM <= 1_000_000, "Value can't be more than 1000000");

    platformFeeInPPM = valueInPPM;
  }

  /// @notice Get the platform fee from a given value.
  /// @param value The value from which to calculate the platform fee.
  /// @return The platform fee calculated from the given value.
  function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
    return (value * platformFeeInPPM) / 1_000_000;
  }

  /// @notice Constructor to initialize the RentalityPaymentService.
  /// @param _userService The address of the RentalityUserService contract
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    platformFeeInPPM = 200_000;
    __Ownable_init();
  }
}
