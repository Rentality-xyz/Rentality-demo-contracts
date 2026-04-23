// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import './RentalPricingTypes.sol';

interface IRentalityBaseDiscountAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
}

contract RentalityBaseDiscount is UUPSOwnable {
  IRentalityBaseDiscountAccess public userAccess;
  mapping(address => RentalBaseDiscount) private userAddressToBaseDiscount;
  RentalBaseDiscount public defaultDiscount;

  error OnlyAdmin();
  error OnlyPlatform();
  error IncorrectDiscount();

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = IRentalityBaseDiscountAccess(userAccessAddress);
    defaultDiscount = RentalBaseDiscount(20_000, 100_000, 150_000, false);
  }

  function getDiscount(address userAddress) public view returns (bytes memory) {
    return abi.encode(getParsedDiscount(userAddress));
  }

  function getParsedDiscount(address userAddress) public view returns (RentalBaseDiscount memory) {
    if (userAddress == address(0)) {
      return defaultDiscount;
    }

    RentalBaseDiscount memory discount = userAddressToBaseDiscount[userAddress];
    return discount.initialized ? discount : defaultDiscount;
  }

  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 price) public view returns (uint64) {
    RentalBaseDiscount memory discount = getParsedDiscount(user);
    uint32 discountPercent;

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

  function setDiscount(bytes memory newDiscounts) public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }

    RentalBaseDiscount memory newDiscountData = abi.decode(newDiscounts, (RentalBaseDiscount));
    _verifyDiscountValidity(newDiscountData);
    defaultDiscount = newDiscountData;
  }

  function addUserDiscount(address user, bytes memory newDiscounts) public {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    RentalBaseDiscount memory newDiscountData = abi.decode(newDiscounts, (RentalBaseDiscount));
    _verifyDiscountValidity(newDiscountData);
    userAddressToBaseDiscount[user] = newDiscountData;
  }

  function setDefaultDiscountToFalse() public {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }
    defaultDiscount.initialized = false;
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityBaseDiscountAccess(userAccessAddress);
  }

  function _verifyDiscountValidity(RentalBaseDiscount memory discount) private pure {
    _verifyPercentageValidity(discount.threeDaysDiscount);
    _verifyPercentageValidity(discount.sevenDaysDiscount);
    _verifyPercentageValidity(discount.thirtyDaysDiscount);
  }

  function _verifyPercentageValidity(uint32 value) private pure {
    if (value > 1_000_000) {
      revert IncorrectDiscount();
    }
  }
}
