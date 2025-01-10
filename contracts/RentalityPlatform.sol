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
import {RentalityPlatformHelper} from './RentalityPlatformHelper.sol';

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

  using RentalityTripsQuery for RentalityContract;
  /// @dev Modifier to restrict access to admin users only.

  RentalityInsurance private insuranceService;

  RentalityReferralProgram private refferalProgram;
  RentalityPromoService private promoService;
  RentalityDimoService private dimoService;

  RentalityPlatformHelper private platformHelper;

   fallback(bytes calldata data) external returns (bytes memory) {
    (bool ok_view, bytes memory res_view) = address(platformHelper).call(data);
    bytes4 errorSign = 0x403e7fa6;
    if (!ok_view && bytes4(res_view) == errorSign) {
      revert FunctionNotFound();
    } else if (!ok_view) {
      assembly {
        revert(add(res_view, 32), mload(res_view))
      }
    }
    return res_view;
  }

  function updateServiceAddresses(RentalityAdminGateway adminService, RentalityPlatformHelper platformHelperAddress) public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = adminService.getRentalityContracts();
    insuranceService = adminService.getInsuranceService();
    refferalProgram = adminService.getRefferalServiceAddress();
    promoService = adminService.getPromoService();
    dimoService = adminService.getDimoService();
    platformHelper = platformHelperAddress;
  }

  /// @notice Creates a trip request with delivery.
  /// @param request The trip request with delivery details.
  function createTripRequestWithDelivery(
    Schemas.CreateTripRequestWithDelivery memory request,
    string memory promo
  ) public payable {
    (uint64 pickUp, uint64 dropOf) = RentalityUtils.calculateDelivery(addresses, request);
    bytes32 pickUpHash = IRentalityGeoService(addresses.carService.getGeoServiceAddress()).createSignedLocationInfo(
      request.pickUpInfo
    );
    bytes32 returnHash = IRentalityGeoService(addresses.carService.getGeoServiceAddress()).createSignedLocationInfo(
      request.returnInfo
    );
    _createTripRequest(
      request.currencyType,
      request.carId,
      request.startDateTime,
      request.endDateTime,
      pickUp,
      dropOf,
      pickUpHash,
      returnHash,
      promo
    );
  }

  // /// @notice Create a trip request.
  // /// @param request The request parameters for creating a new trip.
  // function createTripRequest(Schemas.CreateTripRequest memory request) public payable {
  //   _createTripRequest(
  //     request.currencyType,
  //     request.carId,
  //     request.startDateTime,
  //     request.endDateTime,
  //     0,
  //     0,
  //     bytes32(''),
  //     bytes32('')
  //     // request.useRefferalDiscount
  //   );
  // }
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
    bytes32 returnHash,
    string memory promo
  ) private {
    RentalityUtils.validateTripRequest(addresses, currencyType, carId, startDateTime, endDateTime);
    // uint discount = 0;
    //    if(useRefferalDiscount)
    //  discount = refferalProgram.useDiscount(Schemas.RefferalProgram.CreateTrip, false, addresses.tripService.totalTripCount() + 1);
    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(carId);

    (
      Schemas.PaymentInfo memory paymentInfo,
      uint valueSumInCurrency,
      uint hostEarningsInCurrency,
      uint hostEarnings,
      bool usePromo
    ) = RentalityUtils.createPaymentInfo(
        addresses,
        carId,
        startDateTime,
        endDateTime,
        currencyType,
        pickUp,
        dropOf,
        promoService,
        promo,
        tx.origin
      );
    uint insurance = insuranceService.calculateInsuranceForTrip(carId, startDateTime, endDateTime);
    valueSumInCurrency += addresses.currencyConverterService.getFromUsd(
      currencyType,
      insurance,
      paymentInfo.currencyRate,
      paymentInfo.currencyDecimals
    );

    addresses.paymentService.payCreateTrip{value: msg.value}(currencyType, valueSumInCurrency);

    uint tripId = addresses.tripService.createNewTrip(
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
    insuranceService.saveGuestinsurancePayment(tripId, carId, insurance);
    if (usePromo)
     promoService.usePromo(promo, tripId, tx.origin, hostEarningsInCurrency, hostEarnings, uint(startDateTime), uint(endDateTime));
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

    uint insurance = insuranceService.getInsurancePriceByTrip(tripId);
    uint valueToReturnInUsdCents = addresses.currencyConverterService.calculateTripReject(trip.paymentInfo, insurance);

    /* you should not recalculate the value with convertor,
     for return during rejection,
     but instead, use: 'addresses.tripService.tripIdToEthSumInTripCreation(tripId)'*/
    addresses.tripService.rejectTrip(tripId, 0, valueToReturnInUsdCents, 0);
    addresses.paymentService.payRejectTrip(trip, addresses.tripService.tripIdToEthSumInTripCreation(tripId));
    promoService.rejectDiscountByTrip(tripId, trip.guest);
  }

  /// @notice Confirms the check-out for a trip.
  /// @param tripId The ID of the trip to be confirmed.
  function confirmCheckOut(uint256 tripId, bytes32 refferalHash) public {
    RentalityUtils.verifyConfirmCheckOut(addresses, tripId);
    _finishTrip(tripId, refferalHash);
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId, bytes32 refferalHash) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    require(
      trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest,
      'The trip is not CheckedOutByHost'
    );
    _finishTrip(tripId, refferalHash);
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function _finishTrip(uint256 tripId, /* bool useRefferalDiscount,*/ bytes32 refferalHash) internal {
    addresses.tripService.finishTrip(tripId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);

    uint256 rentalityFee = addresses.paymentService.getPlatformFeeFrom(
      trip.paymentInfo.priceWithDiscount + trip.paymentInfo.pickUpFee + trip.paymentInfo.dropOfFee
    );

    uint insurancePrice = insuranceService.getInsurancePriceByTrip(tripId);
    (uint valueToHost, uint valueToGuest, uint valueToHostInUsdCents, uint valueToGuestInUsdCents) = addresses
      .currencyConverterService
      .calculateTripFinsish(trip.paymentInfo, rentalityFee, insurancePrice, promoService);

    addresses.paymentService.payFinishTrip(trip, valueToHost, valueToGuest);

    addresses.tripService.saveTransactionInfo(
      tripId,
      rentalityFee,
      Schemas.TripStatus.Finished,
      valueToGuestInUsdCents,
      valueToHostInUsdCents - trip.paymentInfo.resolveAmountInUsdCents - insurancePrice
    );
  }

  /// @notice Creates a new claim for a specific trip.
  /// @dev Only the host of the trip can create a claim, and certain trip status checks are performed.
  /// @param request Details of the claim to be created.
  function createClaim(Schemas.CreateClaimRequest memory request) public {
    (address host, address guest) = RentalityUtils.verifyClaim(addresses, request);
    addresses.claimService.createClaim(request, host, guest);
  }

  /// @notice Rejects a specific claim.
  /// @dev Only the host or guest of the associated trip can reject the claim.
  /// @param claimId ID of the claim to be rejected.
  function rejectClaim(uint256 claimId) public {
    Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

    require(trip.host == tx.origin || trip.guest == tx.origin, 'For trip guest or host.');

    addresses.claimService.rejectClaim(claimId, tx.origin, trip.host, trip.guest);
  }

  /// @notice Pays a specific claim, transferring funds to the host and, if applicable, refunding excess to the guest.
  /// @dev Only the guest of the associated trip can pay the claim, and certain checks are performed.
  /// @param claimId ID of the claim to be paid.
  function payClaim(uint256 claimId) public payable {
    Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

    uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);

    (uint valueToPay, uint feeInCurrency, int rate, uint8 dec) = addresses
      .currencyConverterService
      .calculateLatestValueWithFee(trip.paymentInfo.currencyType, claim.amountInUsdCents, commission);

    addresses.claimService.payClaim(claimId, trip.host, trip.guest, rate, dec);
    addresses.paymentService.payClaim{value: msg.value}(trip, valueToPay, feeInCurrency, commission);
  }

  //not using
  /// @notice Updates the status of a specific claim based on the current timestamp.
  /// @dev This function is typically called periodically to check and update claim status.
  /// @param claimId ID of the claim to be updated.
  // function updateClaim(uint256 claimId) public {
  //   Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
  //   Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

  //   addresses.claimService.updateClaim(claimId, trip.host, trip.guest);
  // }

  /// @notice Sets Know Your Customer (KYC) information for the caller.
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    bytes memory TCSignature,
    bytes32 refferalHash
  ) public {
    refferalProgram.generateReferralHash();
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.SetKYC,
      refferalHash,
      bytes(''),
      tx.origin,
      promoService
    );
    return addresses.userService.setKYCInfo(nickName, mobilePhoneNumber, profilePhoto, TCSignature);
  }

  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo, bytes32 refferalHash) public {
    refferalProgram.passReferralProgram(Schemas.RefferalProgram.PassCivic, refferalHash, bytes(''), user, promoService);
    addresses.userService.setCivicKYCInfo(user, civicKycInfo);
  }
  function setMyCivicKYCInfo(Schemas.CivicKYCInfo memory civicKycInfo) public {
    addresses.userService.setMyCivicKYCInfo(tx.origin, civicKycInfo);
  }
  /// @notice Allows the host to perform a check-in for a specific trip.
  /// This action typically occurs at the start of the trip and records key information
  /// such as fuel level, odometer reading, insurance details, and any other relevant data.
  /// @param tripId The unique identifier for the trip being checked in.
  /// @param panelParams An array of numeric parameters representing important vehicle details.
  ///   - panelParams[0]: Fuel level (e.g., as a percentage)
  ///   - panelParams[1]: Odometer reading (e.g., in kilometers or miles)
  ///   - Additional parameters can be added based on the engine and vehicle characteristics.
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) public {
    if (bytes(insuranceNumber).length > 0 || bytes(insuranceCompany).length > 0)
      insuranceService.saveTripInsuranceInfo(
        tripId,
        Schemas.SaveInsuranceRequest(insuranceCompany, insuranceNumber, '', '', Schemas.InsuranceType.OneTime)
      );
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
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams, bytes32 refferalHash) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.FinishTripAsGuest,
      refferalHash,
      abi.encode(trip.startDateTime, trip.endDateTime),
      tx.origin,
      promoService
    );
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
  function addCar(Schemas.CreateCarRequest memory request, bytes32 refferalHash) public returns (uint) {
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.AddCar,
      refferalHash,
      abi.encode(request.currentlyListed),
      tx.origin,
      promoService
    );
    require(addresses.paymentService.taxExist(request.locationInfo.locationInfo) != 0, 'Tax not exist.');
    uint carId = addresses.carService.addCar(request);
    dimoService.saveDimoTokenId(request.dimoTokenId,carId);

    insuranceService.saveInsuranceRequired(carId, request.insurancePriceInUsdCents, request.insuranceRequired);
    return carId;
  }
  /// @notice Updates the information of a car. Only callable by hosts.
  /// @param request The request containing updated car information.
  // function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) public {
  //   require(addresses.isCarEditable(request.carId), 'Car is not available for update.');

  // }

  /// @notice Updates the information of a car, including location details. Only callable by hosts.
  /// @param request The request containing updated car information.
  /// @param location The new location of the car.


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
    address viewService,
    address insuranceServiceAddress,
    address refferalProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress,
    address rentalityPlatformHelperAddress
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
    platformHelper = RentalityPlatformHelper(rentalityPlatformHelperAddress);
    __Ownable_init();
  }
}