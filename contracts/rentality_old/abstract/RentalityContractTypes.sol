// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../adapter/ICarGateway.sol';
import './ILegacyUserProfileSource.sol';
import './IRentalityAdminGateway.sol';
import './ITripSource.sol';
import '../features/RentalityCarDelivery.sol';
import '../features/RentalityClaimService.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';

struct RentalityContract {
  ICarGateway carService;
  RentalityCurrencyConverter currencyConverterService;
  ITripSource tripService;
  ILegacyUserProfileSource userService;
  address rentalityPlatform;
  RentalityPaymentService paymentService;
  RentalityClaimService claimService;
  IRentalityAdminGateway adminService;
  RentalityCarDelivery deliveryService;
  address viewService;
}
