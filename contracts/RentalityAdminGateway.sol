// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityPaymentService.sol';
import './RentalityPlatform.sol';
import './IRentalityAdminGateway.sol';

contract RentalityAdminGateway is UUPSOwnable, IRentalityAdminGateway {
  IRentalityAccessControl private userService;
  RentalityPlatform private rentalityPlatform;
  RentalityPaymentService private paymentService;

  /// @notice Ensures that the caller is either an admin, the contract owner, or an admin from the origin transaction.
  modifier onlyAdmin() {
    require(
      userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) || (tx.origin == owner()),
      'User is not an admin'
    );
    _;
  }

  /// @notice Withdraws the specified amount from the RentalityPlatform contract.
  /// @param amount The amount to withdraw.
  function withdrawFromPlatform(uint256 amount) public {
    rentalityPlatform.withdrawFromPlatform(amount);
  }

  /// @notice Withdraws the entire balance from the RentalityPlatform contract.
  function withdrawAllFromPlatform() public {
    rentalityPlatform.withdrawFromPlatform(address(this).balance);
  }
  /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
  /// @param valueInPPM The new platform fee value in PPM.
  function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
    paymentService.setPlatformFeeInPPM(valueInPPM);
  }

  /// @notice constructor function to initialize service addresses
  //  @param userServiceAddress The address of the RentalityUserService contract.
  //  @param rentalityPlatformAddress The address of the RentalityPlatform contract.
  //  @param paymentServiceAddress The address of the RentalityPaymentService contract.
  function initialize(
    address userServiceAddress,
    address rentalityPlatformAddress,
    address paymentServiceAddress
  ) public initializer {
    userService = IRentalityAccessControl(userServiceAddress);
    rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
    paymentService = RentalityPaymentService(paymentServiceAddress);

    __Ownable_init();
  }
}
