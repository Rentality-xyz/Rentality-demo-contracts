/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './features/RentalityClaimService.sol';
import './abstract/IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './payments/RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './payments/RentalityPaymentService.sol';
import './Schemas.sol';
import './RentalityAdminGateway.sol';
import {RentalityCarDelivery} from './features/RentalityCarDelivery.sol';
import {UUPSOwnable} from './proxy/UUPSOwnable.sol';
import {RentalityUtils} from './libs/RentalityUtils.sol';
import {RentalityDimoService} from './features/RentalityDimoService.sol';
import './RentalityView.sol';
import {RentalityReferralProgram} from './features/refferalProgram/RentalityReferralProgram.sol';
import './payments/RentalityInsurance.sol';
import {RentalityPromoService} from './features/RentalityPromo.sol';

/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityPlatformHelper is UUPSOwnable {

    RentalityContract private addresses;


  RentalityInsurance private insuranceService;
  RentalityDimoService private dimoService;

  RentalityReferralProgram private refferalProgram;
  RentalityPromoService private promoService;


  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) public {
    insuranceService.saveGuestInsurance(insuranceInfo);
  }

    /// @notice Adds a user discount.
  /// @param data The discount data.
  function addUserDiscount(Schemas.BaseDiscount memory data) public {
    addresses.paymentService.addBaseDiscount(tx.origin, data);
  }

  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    addresses.deliveryService.setUserDeliveryPrices(underTwentyFiveMilesInUsdCents, aboveTwentyFiveMilesInUsdCents,tx.origin);
  }
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) public {
    dimoService.saveButch(dimoTokenIds, carIds);
  }
  function useKycCommission(address user) public {
    addresses.userService.useKycCommission(user);
  }

    function payKycCommission(address currency) public payable {
    (uint valueToPay, , ) = addresses.currencyConverterService.getFromUsdLatest(
      currency,
      addresses.userService.getKycCommission()
    );

    addresses.paymentService.payKycCommission{value: msg.value}(valueToPay, currency,tx.origin);
  }

    function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    require(trip.host == tx.origin || trip.guest == tx.origin, 'For trip host or guest');
    insuranceService.saveTripInsuranceInfo(tripId, insuranceInfo);
  }
  

    function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) public {
    require(RentalityUtils.isCarEditable(addresses, request.carId), 'Car is not available for update.');

    if (location.signature.length > 0) addresses.carService.verifySignedLocationInfo(location);
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.UnlistedCar,
      abi.encode(addresses.carService.getCarInfoById(request.carId).currentlyListed, request.currentlyListed),
      tx.origin,
      promoService
    );
    insuranceService.saveInsuranceRequired(request.carId, request.insurancePriceInUsdCents, request.insuranceRequired);
    return addresses.carService.updateCarInfo(request, location.locationInfo, location.signature.length > 0, tx.origin);
  }



    /// @notice Constructor to initialize the RentalityPlatform with service contract addresses.
  /// @param carServiceAddress The address of the RentalityCarToken contract.
  /// @param currencyConverterServiceAddress The address of the RentalityCurrencyConverter contract.
  /// @param tripServiceAddress The address of the RentalityTripService contract.
  /// @param userServiceAddress The address of the RentalityUserService contract.
  /// @param paymentServiceAddress The address of the RentalityPaymentService contract.
  function initialize(
    address carServiceAddress,
    address currencyConverterServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address paymentServiceAddress,
    address claimServiceAddress,
    address carDeliveryAddress,
    address viewService,
    address insuranceServiceAddress,
    address refferalProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(address(this)),
      RentalityPaymentService(payable(paymentServiceAddress)),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(address(0)),
      RentalityCarDelivery(carDeliveryAddress),
      RentalityView(viewService)
    );
    insuranceService = RentalityInsurance(insuranceServiceAddress);
    refferalProgram = RentalityReferralProgram(refferalProgramAddress);
    promoService = RentalityPromoService(promoServiceAddress);

    dimoService = RentalityDimoService(dimoServiceAddress);
    __Ownable_init();
  }

}