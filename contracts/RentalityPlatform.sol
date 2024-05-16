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
  /// @dev Modifier to restrict access to admin users only.
  modifier onlyAdmin() {
    require(
      addresses.userService.isAdmin(msg.sender) || addresses.userService.isAdmin(tx.origin) || (tx.origin == owner()),
      'User is not an admin'
    );
    _;
  }

  // modifier onlyHost() {
  //     require(addresses.userService.isHost(msg.sender), "User is not a host");
  //     _;
  // }

  // modifier onlyGuest() {
  //     require(addresses.userService.isGuest(msg.sender), "User is not a guest");
  //     _;
  // }

  function updateServiceAddresses(RentalityAdminGateway adminService) public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = adminService.getRentalityContracts();
  }

  /// @notice Withdraw a specific amount of funds from the contract.
  /// @param amount The amount to withdraw from the contract.
  function withdrawFromPlatform(uint256 amount, address currencyType) public {
    require(
      address(this).balance > 0 || IERC20(currencyType).balanceOf(address(this)) > 0,
      'There is no commission to withdraw'
    );

    require(
      address(this).balance >= amount || IERC20(currencyType).balanceOf(address(this)) >= amount,
      'There is not enough balance on the contract'
    );

    bool success;
    if (addresses.currencyConverterService.isETH(currencyType)) {
      //require(payable(owner()).send(amount));
      (success, ) = payable(owner()).call{value: amount}('');
      require(success, 'Transfer failed.');
    } else {
      success = IERC20(currencyType).transfer(owner(), amount);
    }
    require(success, 'Transfer failed.');
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

    uint64 priceInUsdCents = addresses.deliveryService.calculatePriceByDeliveryDataInUsdCents(
      request.deliveryInfo,
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLatitude(request.carId),
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLongitude(request.carId)
    );

    _createTripRequest(
      request.currencyType,
      request.carId,
      request.startDateTime,
      request.endDateTime,
      priceInUsdCents
    );
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

    _createTripRequest(request.currencyType, request.carId, request.startDateTime, request.endDateTime, 0);
  }
  /// @notice Creates a trip request with specified details.
  /// @dev This function is private and should only be called internally.
  /// @param currencyType Address of the currency type contract.
  /// @param carId ID of the car for the trip request.
  /// @param startDateTime Start date and time of the trip request.
  /// @param endDateTime End date and time of the trip request.
  /// @param deliveryFee Fee for delivery associated with the trip request.
  function _createTripRequest(
    address currencyType,
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    uint64 deliveryFee
  ) private {
    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(carId);

    (Schemas.PaymentInfo memory paymentInfo, uint valueSumInCurrency) = RentalityUtils.createPaymentInfo(
      addresses,
      carId,
      startDateTime,
      endDateTime,
      currencyType,
      deliveryFee
    );

    if (addresses.currencyConverterService.isETH(currencyType)) {
      require(
        msg.value == valueSumInCurrency,
        'Rental fee must be equal to sum: price with discount + taxes + deposit + delivery'
      );
    } else {
      require(
        IERC20(currencyType).allowance(tx.origin, address(this)) >= valueSumInCurrency,
        'Rental fee must be equal to sum: price with discount + taxes + deposit + delivery'
      );

      bool success = IERC20(currencyType).transferFrom(tx.origin, address(this), valueSumInCurrency);
      require(success, 'Transfer failed.');
    }
    /// updating cache currency data
    addresses.currencyConverterService.getCurrencyRateWithCache(currencyType);

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
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarCity(carId),
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarCity(carId),
      carInfo.milesIncludedPerDay,
      paymentInfo
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

    uint64 valueToReturnInUsdCents = trip.paymentInfo.priceWithDiscount +
      trip.paymentInfo.salesTax +
      trip.paymentInfo.governmentTax +
      trip.paymentInfo.depositInUsdCents;

    uint256 valueToReturnInToken = addresses.currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      valueToReturnInUsdCents,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );
    bool successGuest;
    if (addresses.currencyConverterService.isETH(trip.paymentInfo.currencyType)) {
      (successGuest, ) = payable(trip.guest).call{value: valueToReturnInToken}('');
    } else {
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToReturnInToken);
    }
    require(successGuest, 'Transfer to guest failed.');

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

    uint256 rentalityFee = addresses.paymentService.getPlatformFeeFrom(trip.paymentInfo.priceWithDiscount);

    uint256 valueToHostInUsdCents = trip.paymentInfo.priceWithDiscount +
      trip.paymentInfo.deliveryFee +
      trip.paymentInfo.resolveAmountInUsdCents -
      rentalityFee;

    uint256 valueToGuestInUsdCents = trip.paymentInfo.depositInUsdCents - trip.paymentInfo.resolveAmountInUsdCents;

    uint256 valueToHost = addresses.currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      valueToHostInUsdCents,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );
    uint256 valueToGuest = addresses.currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      valueToGuestInUsdCents,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );
    bool successHost;
    bool successGuest;
    if (addresses.currencyConverterService.isETH(trip.paymentInfo.currencyType)) {
      (successHost, ) = payable(trip.host).call{value: valueToHost}('');
      (successGuest, ) = payable(trip.guest).call{value: valueToGuest}('');
    } else {
      successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToHost);
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToGuest);
    }
    require(successHost && successGuest, 'Transfer failed.');

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

    uint256 valueToPay = addresses.currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      claim.amountInUsdCents + commission,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );

    uint256 feeInCurrency = addresses.currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      commission,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );
    addresses.claimService.payClaim(claimId, trip.host, trip.guest);
    bool successHost;

    if (addresses.currencyConverterService.isETH(trip.paymentInfo.currencyType)) {
      require(msg.value >= valueToPay, 'Insufficient funds sent.');
      (successHost, ) = payable(trip.host).call{value: valueToPay - feeInCurrency}('');

      if (msg.value > valueToPay + feeInCurrency) {
        uint256 excessValue = msg.value - valueToPay;
        (bool successRefund, ) = payable(tx.origin).call{value: excessValue}('');
        require(successRefund, 'Refund to guest failed.');
      }
    } else {
      require(IERC20(trip.paymentInfo.currencyType).allowance(tx.origin, address(this)) >= valueToPay);
      successHost = IERC20(trip.paymentInfo.currencyType).transferFrom(
        tx.origin,
        trip.host,
        valueToPay - feeInCurrency
      );
      if (commission != 0) {
        bool successPlatform = IERC20(trip.paymentInfo.currencyType).transferFrom(tx.origin, trip.host, feeInCurrency);
        require(successPlatform, 'Fail to transfer fee.');
      }
    }
    require(successHost, 'Transfer to host failed.');
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
  /// @param name The name of the user.
  /// @param surname The surname of the user.
  /// @param mobilePhoneNumber The mobile phone number of the user.
  /// @param profilePhoto The URL of the user's profile photo.
  /// @param licenseNumber The user's license number.
  /// @param expirationDate The expiration date of the user's license.
  /// @param TCSignature The signature of the user indicating acceptance of Terms and Conditions (TC).
  function setKYCInfo(
    string memory name,
    string memory surname,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory licenseNumber,
    uint64 expirationDate,
    bytes memory TCSignature
  ) public {
    if (!addresses.userService.isGuest(tx.origin)) {
      addresses.userService.grantGuestRole(tx.origin);
    }
    return
      addresses.userService.setKYCInfo(
        name,
        surname,
        mobilePhoneNumber,
        profilePhoto,
        licenseNumber,
        expirationDate,
        TCSignature
      );
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
    return addresses.carService.addCar(request);
  }

  /// @notice Updates the information of a car. Only callable by hosts.
  /// @param request The request containing updated car information.
  function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) public {
    require(addresses.isCarEditable(request.carId), 'Car is not available for update.');

    return addresses.carService.updateCarInfo(request, '', '', '', '');
  }

  /// @notice Updates the information of a car, including location details. Only callable by hosts.
  /// @param request The request containing updated car information.
  /// @param location The new location of the car.
  /// @param geoApiKey The API key for geocoding purposes.
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    string memory location,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory geoApiKey
  ) public {
    require(addresses.isCarEditable(request.carId), 'Car is not available for update.');

    return addresses.carService.updateCarInfo(request, location, locationLatitude, locationLongitude, geoApiKey);
  }
  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addUserDiscount(Schemas.BaseDiscount memory data) public {
    addresses.paymentService.addBaseDiscount(tx.origin, data);
  }

  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    addresses.deliveryService.setUserDeliveryPrices(underTwentyFiveMilesInUsdCents, aboveTwentyFiveMilesInUsdCents);
  }
  /// @notice Parses the geolocation response and stores parsed data.
  /// @param carId The ID of the car for which geolocation is parsed.
  function parseGeoResponse(uint carId) public {
    IRentalityGeoService(addresses.carService.getGeoServiceAddress()).parseGeoResponse(carId);
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
    address carDeliveryAddress
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(address(this)),
      RentalityPaymentService(paymentServiceAddress),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(address(0)),
      RentalityCarDelivery(carDeliveryAddress)
    );

    __Ownable_init();
  }
}
