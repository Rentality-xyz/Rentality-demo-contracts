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
import {ARentalityContext} from './abstract/ARentalityContext.sol';
import {RentalityHostInsurance} from './payments/RentalityHostInsurance.sol';

struct CreateTripRequestParams {
    Schemas.CreateTripRequestWithDelivery request;
    uint64 pickUp;
    uint64 dropOf;
    bytes32 pickUpHash;
    bytes32 returnHash;
    string promo;
}


/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityPlatform is UUPSOwnable, ARentalityContext {
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
  address private trustedForwarderAddress;

  RentalityHostInsurance private hostInsurance;


  fallback(bytes calldata data) external returns (bytes memory) {
    require(trustedForwarderAddress == msg.sender, 'only trusted forwarder');
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

  // function updateServiceAddresses(
  //   RentalityAdminGateway adminService,
  //   RentalityPlatformHelper platformHelperAddress
  // ) public {
  //   require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
  //   addresses = adminService.getRentalityContracts();
  //   insuranceService = adminService.getInsuranceService();
  //   refferalProgram = adminService.getRefferalServiceAddress();
  //   promoService = adminService.getPromoService();
  //   dimoService = adminService.getDimoService();
  //   platformHelper = platformHelperAddress;
  // }

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
    CreateTripRequestParams memory params = CreateTripRequestParams({
        request: request,
        pickUp: pickUp,
        dropOf: dropOf,
        pickUpHash: pickUpHash,
        returnHash: returnHash,
        promo: promo
    });
    _createTripRequest(params);
}

  /// @notice Creates a trip request with specified details.
  /// @dev This function is private and should only be called internally.
   function _createTripRequest(
    CreateTripRequestParams memory params
) private {
    address sender = _msgGatewaySender();
    require(
        addresses.carService.exists(params.request.carId),
        'Car with this id does not exist.'
    );
    address currencyType =  addresses.currencyConverterService.getUserCurrency(addresses.carService.ownerOf(params.request.carId)).currency;
    RentalityUtils.validateTripRequest(
        addresses,
        currencyType,
        params.request.carId,
        params.request.startDateTime,
        params.request.endDateTime,
        sender
    );

    uint insurance = insuranceService.calculateInsuranceForTrip(
        params.request.carId,
        params.request.startDateTime,
        params.request.endDateTime,
        sender
    );
    uint64 priceWithDiscount = addresses.paymentService.calculateSumWithDiscount(
        addresses.carService.ownerOf(params.request.carId),
        RentalityUtils.getCeilDays(params.request.startDateTime, params.request.endDateTime),
        addresses.carService.getCarInfoById(params.request.carId).pricePerDayInUsdCents
    );
    uint tripId = addresses.tripService.totalTripCount() + 1;

    (
        Schemas.PaymentInfo memory paymentInfo,
        uint valueSumInCurrency,
        uint hostEarningsInCurrency,
        uint hostEarnings,
        bool usePromo
    ) = RentalityUtils.createPaymentInfo(
        addresses,
        params.request.carId,
        currencyType,
        params.pickUp,
        params.dropOf,
        promoService,
        params.promo,
        sender,
        insurance,
        addresses.paymentService.calculateAndSaveTaxes(
            addresses.paymentService.defineTaxesType(address(addresses.carService), params.request.carId),
            RentalityUtils.getCeilDays(params.request.startDateTime, params.request.endDateTime),
            priceWithDiscount + params.pickUp + params.dropOf,
            tripId
        ),
        RentalityUtils.getCeilDays(params.request.startDateTime, params.request.endDateTime),
        priceWithDiscount
    );

    addresses.paymentService.payCreateTrip{value: msg.value}(
        currencyType,
        valueSumInCurrency,
        sender,
        params.request.carId
    );

    addresses.tripService.createNewTrip(
        params.request.carId,
        sender,
        addresses.carService.ownerOf(params.request.carId),
        addresses.carService.getCarInfoById(params.request.carId).pricePerDayInUsdCents,
        params.request.startDateTime,
        params.request.endDateTime,
        params.pickUpHash,
        params.returnHash,
        addresses.carService.getCarInfoById(params.request.carId).milesIncludedPerDay,
        paymentInfo,
        currencyType == address(0) ? msg.value : valueSumInCurrency
    );
    insuranceService.saveGuestinsurancePayment(tripId, params.request.carId, insurance, sender);
    if (usePromo)
        promoService.usePromo(
            params.promo,
            tripId,
            sender,
            hostEarningsInCurrency,
            hostEarnings,
            uint(params.request.startDateTime),
            uint(params.request.endDateTime)
        );
}

  /// @notice Approve a trip request on the Rentality platform.
  /// @param tripId The ID of the trip to approve.
  function approveTripRequest(uint256 tripId) public {
    addresses.tripService.approveTrip(tripId, _msgGatewaySender());

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
    uint64 totalTax = addresses.paymentService.getTotalTripTax(tripId);
    uint valueToReturnInUsdCents = addresses.currencyConverterService.calculateTripReject(trip.paymentInfo, insurance, totalTax);

    /* you should not recalculate the value with convertor,
     for return during rejection,
     but instead, use: 'addresses.tripService.tripIdToEthSumInTripCreation(tripId)'*/
    addresses.tripService.rejectTrip(tripId, 0, valueToReturnInUsdCents, 0, _msgGatewaySender());
    addresses.paymentService.payRejectTrip(trip, addresses.tripService.tripIdToEthSumInTripCreation(tripId));
    promoService.rejectDiscountByTrip(tripId, trip.guest);
  }

  /// @notice Confirms the check-out for a trip.
  /// @param tripId The ID of the trip to be confirmed.
  function confirmCheckOut(uint256 tripId) public {
    RentalityUtils.verifyConfirmCheckOut(addresses, tripId, _msgGatewaySender());
    _finishTrip(tripId);
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    require(
      trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest,
      'The trip is not CheckedOutByHost'
    );
    _finishTrip(tripId);
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function _finishTrip(uint256 tripId /* bool useRefferalDiscount,*/) internal {
    addresses.tripService.finishTrip(tripId, _msgGatewaySender());
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);

    uint256 rentalityFee = addresses.paymentService.getPlatformFeeFrom(
      trip.paymentInfo.priceWithDiscount + trip.paymentInfo.pickUpFee + trip.paymentInfo.dropOfFee
    );
    uint insurancePrice = insuranceService.getInsurancePriceByTrip(tripId);
    (
      uint valueToHost,
      uint valueToGuest,
      uint valueToHostInUsdCents,
      uint valueToGuestInUsdCents,
      uint totalIncome
    ) = addresses.currencyConverterService.calculateTripFinsish(
        trip.paymentInfo,
        rentalityFee,
        insurancePrice,
        promoService
      );

    addresses.paymentService.payFinishTrip(trip, valueToHost, valueToGuest, totalIncome);
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
  function createClaim(Schemas.CreateClaimRequest memory request, bool isInsuranceClaim) public {
    address sender = _msgGatewaySender();
    (address host, address guest) = RentalityUtils.verifyClaim(addresses, request, sender, isInsuranceClaim);
    uint claimId = addresses.claimService.createClaim(request, host, guest, sender);
    if(isInsuranceClaim)
    hostInsurance.createInsuranceClaim(claimId, sender);
  }

  /// @notice Rejects a specific claim.
  /// @dev Only the host or guest of the associated trip can reject the claim.
  /// @param claimId ID of the claim to be rejected.
  function rejectClaim(uint256 claimId) public {
    Schemas.ClaimV2 memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);
    address sender = _msgGatewaySender();

    require(trip.host == sender || trip.guest == sender, 'For trip guest or host.');

    addresses.claimService.rejectClaim(claimId, sender, trip.host, trip.guest);
  }

  /// @notice Pays a specific claim, transferring funds to the host and, if applicable, refunding excess to the guest.
  /// @dev Only the guest of the associated trip can pay the claim, and certain checks are performed.
  /// @param claimId ID of the claim to be paid.
  function payClaim(uint256 claimId) public payable {
    Schemas.ClaimV2 memory claim = addresses.claimService.getClaim(claimId);
    Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

    uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);

    (uint valueToPay, uint feeInCurrency, int rate, uint8 dec) = addresses
      .currencyConverterService
      .calculateLatestValueWithFee(trip.paymentInfo.currencyType, claim.amountInUsdCents, commission);

    addresses.claimService.payClaim(claimId, trip.host, trip.guest, rate, dec);
    if(!hostInsurance.isHostInsuranceClaim(claimId)) {
    addresses.paymentService.payClaim{value: msg.value}(
      trip,
      valueToPay,
      feeInCurrency,
      commission,
      _msgGatewaySender()
    );
    }
    else {
      hostInsurance.payClaim(valueToPay, trip);
    }
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


  // function setMyCivicKYCInfo(Schemas.CivicKYCInfo memory civicKycInfo) public {
  // addresses.userService.setMyCivicKYCInfo(tx.origin, civicKycInfo);
  // }

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
    address sender = _msgGatewaySender();
    if (bytes(insuranceNumber).length > 0 || bytes(insuranceCompany).length > 0)
      insuranceService.saveTripInsuranceInfo(
        tripId,
        Schemas.SaveInsuranceRequest(insuranceCompany, insuranceNumber, '', '', Schemas.InsuranceType.OneTime),
        sender
      );
    return addresses.tripService.checkInByHost(tripId, panelParams, insuranceCompany, insuranceNumber, sender);
  }

  /// @notice Performs check-in by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) public {
    return addresses.tripService.checkInByGuest(tripId, panelParams, _msgGatewaySender());
  }

  /// @notice Performs check-out by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) public {
    address sender = _msgGatewaySender();
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.FinishTripAsGuest,
      abi.encode(trip.startDateTime, trip.endDateTime),
      sender,
      promoService
    );
    return addresses.tripService.checkOutByGuest(tripId, panelParams, sender);
  }

  /// @notice Performs check-out by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) public {
    return addresses.tripService.checkOutByHost(tripId, panelParams, _msgGatewaySender());
  }
  /// @notice Adds a new car using the provided request. Grants host role to the caller if not already a host.
  /// @param request The request containing car information.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request) public returns (uint) {
    address sender = _msgGatewaySender();
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.AddCar,
      abi.encode(request.currentlyListed),
      sender,
      promoService
    );
    require(addresses.paymentService.taxExist(request.locationInfo.locationInfo) != 0, 'Tax not exist.');
    uint carId = addresses.carService.addCar(request, sender);
    dimoService.saveDimoTokenId(request.dimoTokenId, carId, sender, request.signedDimoTokenId);

    insuranceService.saveInsuranceRequired(carId, request.insurancePriceInUsdCents, request.insuranceRequired, sender);
    return carId;
  }

  function trustedForwarder() internal view override returns (address) {
    return trustedForwarderAddress;
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return addresses.userService.isRentalityPlatform(forwarder);
  }


  function setTrustedForwarder(address forwarder) public onlyOwner {
    trustedForwarderAddress = forwarder;
  }

  function setHostInsuranceAddress(address _hostInsurance) public onlyOwner {
    hostInsurance = RentalityHostInsurance(payable(_hostInsurance));
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
