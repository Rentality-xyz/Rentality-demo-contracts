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
import './libs/RentalityQuery.sol';
import {RentalityCarDelivery} from './features/RentalityCarDelivery.sol';
import {UUPSOwnable} from './proxy/UUPSOwnable.sol';
import {RentalityUtils} from './libs/RentalityUtils.sol';
import './RentalityView.sol';

/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityPlatform is UUPSOwnable {
  RentalityContract private addresses;

  // unused, have to be here, because of proxy
  address private automationService;
  using RentalityQuery for RentalityContract;
  using RentalityTripsQuery for RentalityContract;
  /// @dev Modifier to restrict access to admin users only.
  modifier onlyAdmin() {
    require(
      addresses.userService.isAdmin(msg.sender) || addresses.userService.isAdmin(tx.origin) || (tx.origin == owner()),
      'User is n ot an admin'
    );
    _;
  }

  function updateServiceAddresses(RentalityAdminGateway adminService) public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = adminService.getRentalityContracts();
  }

  //    function withdrawAllFromPlatform(address currencyType) public {
  //        return withdrawFromPlatform(address(this).balance, currencyType);
  //    }

  /// @notice Creates a trip request with delivery.
  /// @param request The trip request with delivery details.
  function createTripRequestWithDelivery(Schemas.CreateTripRequestWithDelivery memory request) public payable {
    RentalityUtils.validateTripRequest(
      addresses,
      request.currencyType,
      request.carId,
      request.startDateTime,
      request.endDateTime
    );
    bytes32 locationHash = addresses.carService.getCarInfoById(request.carId).locationHash;
    (uint64 pickUp, uint64 dropOf) = addresses.deliveryService.calculatePricesByDeliveryDataInUsdCents(
      request.pickUpInfo.locationInfo,
      request.returnInfo.locationInfo,
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLatitude(locationHash),
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLongitude(locationHash),
      addresses.carService.getCarInfoById(request.carId).createdBy
    );
    if (pickUp > 0) addresses.carService.verifySignedLocationInfo(request.pickUpInfo);
    if (dropOf > 0) addresses.carService.verifySignedLocationInfo(request.returnInfo);
    bytes32 pickUpHash = IRentalityGeoService(addresses.carService.getGeoServiceAddress()).createLocationInfo(
      request.pickUpInfo.locationInfo
    );
    bytes32 returnHash = IRentalityGeoService(addresses.carService.getGeoServiceAddress()).createLocationInfo(
      request.returnInfo.locationInfo
    );
    _createTripRequest(
      request.currencyType,
      request.carId,
      request.startDateTime,
      request.endDateTime,
      pickUp,
      dropOf,
      pickUpHash,
      returnHash
    );
  }

  function payKycCommission(address currency) public payable {
    (uint valueToPay, , ) = addresses.currencyConverterService.getFromUsdLatest(
      currency,
      addresses.userService.getKycCommission()
    );

    addresses.paymentService.payKycCommission{value: msg.value}(valueToPay, currency);
  }

  function useKycCommission(address user) public {
    addresses.userService.useKycCommission(user);
  }
  /// @notice Create a trip request.
  /// @param request The request parameters for creating a new trip.
  function createTripRequest(Schemas.CreateTripRequest memory request) public payable {
    RentalityUtils.validateTripRequest(
      addresses,
      request.currencyType,
      request.carId,
      request.startDateTime,
      request.endDateTime
    );

    _createTripRequest(
      request.currencyType,
      request.carId,
      request.startDateTime,
      request.endDateTime,
      0,
      0,
      bytes32(''),
      bytes32('')
    );
  }
  /// @notice Creates a trip request with specified details.
  /// @dev This function is private and should only be called internally.
  /// @param currencyType Address of the currency type contract.
  /// @param carId ID of the car for the trip request.
  /// @param startDateTime Start date and time of the trip request.
  /// @param endDateTime End date and time of the trip request.
  /// @param pickUp Fee for delivery associated with the trip request.
  /// @param dropOf Fee for delivery associated with the trip request.
  function _createTripRequest(
    address currencyType,
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    uint64 pickUp,
    uint64 dropOf,
    bytes32 pickUpHash,
    bytes32 returnHash
  ) private {
    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(carId);

    (Schemas.PaymentInfo memory paymentInfo, uint valueSumInCurrency) = RentalityUtils.createPaymentInfo(
      addresses,
      carId,
      startDateTime,
      endDateTime,
      currencyType,
      pickUp,
      dropOf
    );

    addresses.paymentService.payCreateTrip{value: msg.value}(currencyType, valueSumInCurrency);

    if (!addresses.userService.isGuest(tx.origin)) {
      addresses.userService.grantGuestRole(tx.origin);
    }

    addresses.tripService.createNewTrip(
      carId,
      tx.origin,
      addresses.carService.ownerOf(carId),
      carInfo.pricePerDayInUsdCents,
      startDateTime,
      endDateTime,
      pickUpHash,
      returnHash,
      carInfo.milesIncludedPerDay,
      paymentInfo,
      msg.value
    );
  }

  /// @notice Approve a trip request on the Rentality platform.
  /// @param tripId The ID of the trip to approve.
  function approveTripRequest(uint256 tripId) public {
    addresses.tripService.approveTrip(tripId);

    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    Schemas.Trip[] memory intersectedTrips = addresses.getTripsForCarThatIntersect(
      trip.carId,
      trip.startDateTime,
      trip.endDateTime
    );
    if (intersectedTrips.length > 0) {
      for (uint256 i = 0; i < intersectedTrips.length; i++) {
        if (intersectedTrips[i].status == Schemas.TripStatus.Created) {
          rejectTripRequest(intersectedTrips[i].tripId);
        }
      }
    }
  }
  /// @notice Reject a trip request on the Rentality platform.
  /// @param tripId The ID of the trip to reject.
  function rejectTripRequest(uint256 tripId) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    Schemas.TripStatus statusBeforeCancellation = trip.status;

    addresses.tripService.rejectTrip(tripId);

    uint valueToReturnInUsdCents = addresses.currencyConverterService.calculateTripReject(trip.paymentInfo);
    /* you should not recalculate the value with convertor,
     for return during rejection,
     but instead, use: 'addresses.tripService.tripIdToEthSumInTripCreation(tripId)'*/

    addresses.paymentService.payRejectTrip(trip, addresses.tripService.tripIdToEthSumInTripCreation(tripId));

    addresses.tripService.saveTransactionInfo(tripId, 0, statusBeforeCancellation, valueToReturnInUsdCents, 0);
  }

  /// @notice Confirms the check-out for a trip.
  /// @param tripId The ID of the trip to be confirmed.
  function confirmCheckOut(uint256 tripId) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);

    require(trip.guest == tx.origin || addresses.userService.isAdmin(tx.origin), 'For trip guest or admin only');
    require(trip.host == trip.tripFinishedBy, 'No needs to confirm.');
    require(trip.status == Schemas.TripStatus.CheckedOutByHost, 'The trip is not in status CheckedOutByHost');
    _finishTrip(tripId);
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    require(
      trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest,
      'The trip is not in status CheckedOutByHost'
    );
    _finishTrip(tripId);
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function _finishTrip(uint256 tripId) internal {
    addresses.tripService.finishTrip(tripId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);

    uint256 rentalityFee = addresses.paymentService.getPlatformFeeFrom(
      trip.paymentInfo.priceWithDiscount + trip.paymentInfo.pickUpFee + trip.paymentInfo.dropOfFee
    );

    (uint valueToHost, uint valueToGuest, uint valueToHostInUsdCents, uint valueToGuestInUsdCents) = addresses
      .currencyConverterService
      .calculateTripFinsish(trip.paymentInfo, rentalityFee);

    addresses.paymentService.payFinishTrip(trip, valueToHost, valueToGuest);

    addresses.tripService.saveTransactionInfo(
      tripId,
      rentalityFee,
      Schemas.TripStatus.Finished,
      valueToGuestInUsdCents,
      valueToHostInUsdCents - trip.paymentInfo.resolveAmountInUsdCents
    );
  }

  /// @notice Creates a new claim for a specific trip.
  /// @dev Only the host of the trip can create a claim, and certain trip status checks are performed.
  /// @param request Details of the claim to be created.
  function createClaim(Schemas.CreateClaimRequest memory request) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(request.tripId);

    require(
      (trip.host == tx.origin && uint8(request.claimType) <= 7) ||
        (trip.guest == tx.origin && ((uint8(request.claimType) <= 9) && (uint8(request.claimType) >= 3))),
      'Only for trip host or guest, or wrong claim type.'
    );

    require(
      trip.status != Schemas.TripStatus.Canceled && trip.status != Schemas.TripStatus.Created,
      'Wrong trip status.'
    );

    addresses.claimService.createClaim(request, trip.host, trip.guest);
  }

  /// @notice Rejects a specific claim.
  /// @dev Only the host or guest of the associated trip can reject the claim.
  /// @param claimId ID of the claim to be rejected.
  function rejectClaim(uint256 claimId) public {
    Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

    require(trip.host == tx.origin || trip.guest == tx.origin, 'Only for trip guest or host.');

    addresses.claimService.rejectClaim(claimId, tx.origin, trip.host, trip.guest);
  }

  /// @notice Pays a specific claim, transferring funds to the host and, if applicable, refunding excess to the guest.
  /// @dev Only the guest of the associated trip can pay the claim, and certain checks are performed.
  /// @param claimId ID of the claim to be paid.
  function payClaim(uint256 claimId) public payable {
    Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

    require((claim.isHostClaims && tx.origin == trip.guest) || tx.origin == trip.host, 'Only guest or host.');
    require(
      claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel,
      'Wrong claim Status.'
    );
    uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);

    (uint valueToPay, uint feeInCurrency, int rate, uint8 dec) = addresses
      .currencyConverterService
      .calculateLatestValueWithFee(trip.paymentInfo.currencyType, claim.amountInUsdCents, commission);

    addresses.claimService.payClaim(claimId, trip.host, trip.guest, rate, dec);
    addresses.paymentService.payClaim{value: msg.value}(trip, valueToPay, feeInCurrency, commission);
  }

  /// @notice Updates the status of a specific claim based on the current timestamp.
  /// @dev This function is typically called periodically to check and update claim status.
  /// @param claimId ID of the claim to be updated.
  function updateClaim(uint256 claimId) public {
    Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

    addresses.claimService.updateClaim(claimId, trip.host, trip.guest);
  }

  /// @notice Sets Know Your Customer (KYC) information for the caller.
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    bytes memory TCSignature
  ) public {
    return addresses.userService.setKYCInfo(nickName, mobilePhoneNumber, profilePhoto, TCSignature);
  }

  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) public {
    addresses.userService.setCivicKYCInfo(user, civicKycInfo);
  }
  /// @notice Allows the host to perform a check-in for a specific trip.
  /// This action typically occurs at the start of the trip and records key information
  /// such as fuel level, odometer reading, insurance details, and any other relevant data.
  /// @param tripId The unique identifier for the trip being checked in.
  /// @param panelParams An array of numeric parameters representing important vehicle details.
  ///   - panelParams[0]: Fuel level (e.g., as a percentage)
  ///   - panelParams[1]: Odometer reading (e.g., in kilometers or miles)
  ///   - Additional parameters can be added based on the engine and vehicle characteristics.
  /// @param insuranceCompany The name of the insurance company covering the vehicle.
  /// @param insuranceNumber The insurance policy number.
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) public {
    return addresses.tripService.checkInByHost(tripId, panelParams, insuranceCompany, insuranceNumber);
  }

  /// @notice Performs check-in by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) public {
    return addresses.tripService.checkInByGuest(tripId, panelParams);
  }

  /// @notice Performs check-out by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) public {
    return addresses.tripService.checkOutByGuest(tripId, panelParams);
  }

  /// @notice Performs check-out by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) public {
    return addresses.tripService.checkOutByHost(tripId, panelParams);
  }
  /// @notice Adds a new car using the provided request. Grants host role to the caller if not already a host.
  /// @param request The request containing car information.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request) public returns (uint) {
    if (!addresses.userService.isHost(tx.origin)) {
      addresses.userService.grantHostRole(tx.origin);
    }
    require(addresses.paymentService.taxExist(request.locationInfo.locationInfo) != 0, 'Tax not exist.');
    return addresses.carService.addCar(request);
  }

  /// @notice Updates the information of a car. Only callable by hosts.
  /// @param request The request containing updated car information.
  function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) public {
    require(addresses.isCarEditable(request.carId), 'Car is not available for update.');

    return
      addresses.carService.updateCarInfo(
        request,
        IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getLocationInfo(bytes32('')),
        string('')
      );
  }

  /// @notice Updates the information of a car, including location details. Only callable by hosts.
  /// @param request The request containing updated car information.
  /// @param location The new location of the car.
  /// @param geoApiKey The API key for geocoding purposes.
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location,
    string memory geoApiKey
  ) public {
    require(addresses.isCarEditable(request.carId), 'Car is not available for update.');

    addresses.carService.verifySignedLocationInfo(location);
    return addresses.carService.updateCarInfo(request, location.locationInfo, geoApiKey);
  }
  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addUserDiscount(Schemas.BaseDiscount memory data) public {
    addresses.paymentService.addBaseDiscount(tx.origin, data);
  }

  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    addresses.deliveryService.setUserDeliveryPrices(underTwentyFiveMilesInUsdCents, aboveTwentyFiveMilesInUsdCents);
  }

  // function updateCarTokenUri(uint256 carId, string memory tokenUri) public {
  // addresses.carService.updateCarTokenUri(carId,tokenUri);
  // }

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
    address viewService
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

    __Ownable_init();
  }
}
