// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import './abstract/IRentalityDiscount.sol';
import '../Schemas.sol';

/// @title RentalityBaseDiscount
/// @notice This contract provides functionality for managing discounts applied to trip prices.
contract RentalityBaseDiscount is IRentalityDiscount, Initializable, UUPSAccess {
  mapping(address => Schemas.BaseDiscount) private userAddressToBaseDiscount;
  Schemas.BaseDiscount public defaultDiscount;

  /// @notice Retrieves the discount information for a given user address.
  /// @param userAddress The address of the user.
  /// @return The discount data encoded as bytes.
  function getDiscount(address userAddress) public view returns (bytes memory) {
    if (userAddress == address(0)) return abi.encode(defaultDiscount);

    Schemas.BaseDiscount memory discount = userAddressToBaseDiscount[userAddress];
    if (discount.initialized) return abi.encode(discount);
    else return abi.encode(defaultDiscount);
  }
  function getParsedDiscount(address userAddress) public view returns (Schemas.BaseDiscount memory) {
    if (userAddress == address(0)) return defaultDiscount;

    Schemas.BaseDiscount memory discount = userAddressToBaseDiscount[userAddress];
    if (discount.initialized) return discount;
    else return defaultDiscount;
  }

  /// @notice Calculates the total price with discount for a trip.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param price The original price of the trip.
  /// @param user the address of discount provider
  /// @return The total price after applying the discount.
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 price) public view returns (uint64) {
    uint32 discountPercent;
    Schemas.BaseDiscount memory discount = userAddressToBaseDiscount[user];
    if (!discount.initialized) {
      discount = defaultDiscount;
    }

    if (daysOfTrip >= 3 && daysOfTrip < 7) {
      discountPercent = discount.threeDaysDiscount;
    } else if (daysOfTrip >= 7 && daysOfTrip < 30) {
      discountPercent = discount.sevenDaysDiscount;
    } else if (daysOfTrip >= 30) {
      discountPercent = discount.thirtyDaysDiscount;
    } else {
      return price * daysOfTrip;
    }

    return (price * daysOfTrip * (1_000_000 - discountPercent)) / 1_000_000;
  }
  /// @notice Sets the default discount values.
  /// @dev Only callable by an admin.
  /// @param newDiscounts The new default discount data.
  function setDiscount(bytes memory newDiscounts) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');

    Schemas.BaseDiscount memory newDiscountData = abi.decode(newDiscounts, (Schemas.BaseDiscount));
    verifyDiscountValidity(newDiscountData);
    defaultDiscount = newDiscountData;
  }

  /// @notice Adds or updates a discount for a specific user.
  /// @dev Only callable by a manager.
  /// @param newDiscounts The new discount data.
  function addUserDiscount(address user, bytes memory newDiscounts) public {
    require(userService.isManager(msg.sender), 'Only manager.');
    Schemas.BaseDiscount memory newDiscountData = abi.decode(newDiscounts, (Schemas.BaseDiscount));
    verifyDiscountValidity(newDiscountData);

    userAddressToBaseDiscount[user] = newDiscountData;
  }

  /// @notice Verifies the validity of a discount.
  /// @param discount The discount data to verify.
  function verifyDiscountValidity(Schemas.BaseDiscount memory discount) private pure {
    verifyPercentagesValidity(discount.threeDaysDiscount);
    verifyPercentagesValidity(discount.sevenDaysDiscount);
    verifyPercentagesValidity(discount.thirtyDaysDiscount);
  }

  /// @notice Verifies the validity of discount percentages.
  /// @param value The discount percentage to verify.
  function verifyPercentagesValidity(uint value) private pure {
    require(value <= 1_000_000, 'Incorrect value');
  }
  function setDefaultDiscountToFalse() public {
    require(userService.isAdmin(msg.sender),'only Admin');
    defaultDiscount.initialized = false;
  }

  /// @notice Initializes the RentalityBaseDiscount contract.
  /// @param _userService The address of the RentalityUserService contract.
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);

    defaultDiscount = Schemas.BaseDiscount(20_000, 100_000, 150_000, false); // Default discount values
  }
}
