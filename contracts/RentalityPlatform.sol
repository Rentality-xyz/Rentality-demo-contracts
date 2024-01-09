// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityCarToken.sol';
import './RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './RentalityPaymentService.sol';
import './IRentalityGateway.sol';
import './proxy/UUPSOwnable.sol';
import './RentalityClaimService.sol';

/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityPlatform is UUPSOwnable {
  RentalityCarToken private carService;
  RentalityCurrencyConverter private currencyConverterService;
  RentalityTripService private tripService;
  RentalityUserService private userService;
  RentalityPaymentService private paymentService;
  RentalityClaimService private claimService;

  /// @dev Modifier to restrict access to admin users only.
  modifier onlyAdmin() {
    require(
      userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) || (tx.origin == owner()),
      'User is not an admin'
    );
    _;
  }

  // modifier onlyHost() {
  //     require(userService.isHost(msg.sender), "User is not a host");
  //     _;
  // }

  // modifier onlyGuest() {
  //     require(userService.isGuest(msg.sender), "User is not a guest");
  //     _;
  // }

  // modifier onlyHostOrGuest() {
  //     require(
  //         userService.isHost(msg.sender) || userService.isGuest(msg.sender),
  //         "User is not a host or guest"
  //     );
  //     _;
  // }

  /// @notice Get the address of the Car service on the Rentality platform.
  /// @return The address of the Car service.
  function getCarServiceAddress() public view returns (address) {
    return address(carService);
  }

  /// @notice Update the address of the Car service on the Rentality platform.
  /// @dev This function can only be called by the platform admin.
  /// @param contractAddress The new address of the Car service.
  function updateCarService(address contractAddress) public onlyAdmin {
    carService = RentalityCarToken(contractAddress);
  }

  /// @notice Get the address of the currency converter service on the Rentality platform.
  /// @return The address of the currency converter service.
  function getCurrencyConverterServiceAddress() public view returns (address) {
    return address(currencyConverterService);
  }

  /// @notice Update the address of the currency converter service on the Rentality platform.
  /// @dev This function can only be called by the platform admin.
  /// @param contractAddress The new address of the currency converter service.
  function updateCurrencyConverterService(address contractAddress) public onlyAdmin {
    currencyConverterService = RentalityCurrencyConverter(contractAddress);
  }

  // @notice Get the address of the RentalityTripService service contract.
  function getTripServiceAddress() public view returns (address) {
    return address(tripService);
  }

  /// @notice Update the RentalityTripService service contract address.
  /// @param contractAddress The new address of the RentalityTripService contract.
  function updateTripService(address contractAddress) public onlyAdmin {
    tripService = RentalityTripService(contractAddress);
  }

  /// @notice Get the address of the RentalityUserService service contract.
  function getUserServiceAddress() public view returns (address) {
    return address(userService);
  }

  /// @notice Update the RentalityUserService service contract address.
  /// @param contractAddress The new address of the RentalityUserService contract.
  function updateUserService(address contractAddress) public onlyAdmin {
    userService = RentalityUserService(contractAddress);
  }

  /// @notice Withdraw a specific amount of funds from the contract.
  /// @param amount The amount to withdraw from the contract.
  function withdrawFromPlatform(uint256 amount) public {
    require(address(this).balance > 0, 'There is no commission to withdraw');
    require(address(this).balance >= amount, 'There is not enough balance on the contract');

    //require(payable(owner()).send(amount));
    (bool success, ) = payable(owner()).call{value: amount}('');
    require(success, 'Transfer failed.');
  }

  function withdrawAllFromPlatform() public {
    return withdrawFromPlatform(address(this).balance);
  }

  /// @notice Create a new trip request on the Rentality platform.
  /// @param request The details of the trip request as specified in IRentalityGateway.CreateTripRequest.
  function createTripRequest(IRentalityGateway.CreateTripRequest memory request) public payable {
    require(msg.value > 0, 'Rental fee must be greater than 0');
    require(carService.ownerOf(request.carId) != tx.origin, 'Car is not available for creator');
    require(
      !isCarUnavailable(request.carId, request.startDateTime, request.endDateTime),
      'Unavailable for current date.'
    );

    uint64 valueSum = request.totalDayPriceInUsdCents + request.taxPriceInUsdCents + request.depositInUsdCents;
    uint256 valueSumInEth = currencyConverterService.getEthFromUsd(
      valueSum,
      request.ethToCurrencyRate,
      request.ethToCurrencyDecimals
    );

    require(msg.value == valueSumInEth, 'Rental fee must be equal to sum totalDayPrice + taxPrice + deposit');

    if (!userService.isGuest(tx.origin)) {
      userService.grantGuestRole(tx.origin);
    }

    RentalityTripService.PaymentInfo memory paymentInfo = RentalityTripService.PaymentInfo(
      0,
      tx.origin,
      address(this),
      request.totalDayPriceInUsdCents,
      request.taxPriceInUsdCents,
      request.depositInUsdCents,
      0,
      RentalityTripService.CurrencyType.ETH,
      request.ethToCurrencyRate,
      request.ethToCurrencyDecimals,
      0,
      0
    );

    RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(request.carId);

    tripService.createNewTrip(
      request.carId,
      tx.origin,
      request.host,
      carInfo.pricePerDayInUsdCents,
      request.startDateTime,
      request.endDateTime,
      request.startLocation,
      request.endLocation,
      carInfo.milesIncludedPerDay,
      request.fuelPrices,
      paymentInfo
    );
  }

  // @dev Checks if a car has any active trips within the specified time range.
  // @param carId The ID of the car to check for availability.
  // @param startDateTime The start time of the time range.
  // @param endDateTime The end time of the time range.
  // @return A boolean indicating whether the car is unavailable during the specified time range.
  function isCarUnavailable(uint256 carId, uint64 startDateTime, uint64 endDateTime) private view returns (bool) {
    // Iterate through all trips to check for intersections with the specified car and time range.
    for (uint256 tripId = 1; tripId <= tripService.totalTripCount(); tripId++) {
      RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
      RentalityCarToken.CarInfo memory car = carService.getCarInfoById(trip.carId);

      if (
        trip.carId == carId &&
        trip.endDateTime + car.timeBufferBetweenTripsInSec > startDateTime &&
        trip.startDateTime < endDateTime
      ) {
        RentalityTripService.TripStatus tripStatus = trip.status;

        // Check if the trip is active (not in Created, Finished, or Canceled status).
        bool isActiveTrip = (tripStatus != RentalityTripService.TripStatus.Created &&
          tripStatus != RentalityTripService.TripStatus.Finished &&
          tripStatus != RentalityTripService.TripStatus.Canceled);

        // Return true if an active trip is found.
        if (isActiveTrip) {
          return true;
        }
      }
    }

    // If no active trips are found, return false indicating the car is available.
    return false;
  }

  /// @notice Approve a trip request on the Rentality platform.
  /// @param tripId The ID of the trip to approve.
  function approveTripRequest(uint256 tripId) public {
    tripService.approveTrip(tripId);

    RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
    RentalityTripService.Trip[] memory intersectedTrips = RentalityUtils.getTripsForCarThatIntersect(
      tripService,
      carService,
      trip.carId,
      trip.startDateTime,
      trip.endDateTime
    );
    if (intersectedTrips.length > 0) {
      for (uint256 i = 0; i < intersectedTrips.length; i++) {
        if (intersectedTrips[i].status == RentalityTripService.TripStatus.Created) {
          rejectTripRequest(intersectedTrips[i].tripId);
        }
      }
    }
  }
  /// @notice Reject a trip request on the Rentality platform.
  /// @param tripId The ID of the trip to reject.
  function rejectTripRequest(uint256 tripId) public {
    RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
    tripService.rejectTrip(tripId);

    uint64 valueToReturnInUsdCents = trip.paymentInfo.totalDayPriceInUsdCents +
      trip.paymentInfo.taxPriceInUsdCents +
      trip.paymentInfo.depositInUsdCents;

    uint64 subtractAmount;
    if (trip.status == RentalityTripService.TripStatus.Approved) {
      subtractAmount = trip.pricePerDayInUsdCents / 2;
    } else if (trip.status == RentalityTripService.TripStatus.CheckedInByHost) {
      subtractAmount = trip.pricePerDayInUsdCents;
    } else {
      subtractAmount = 0;
    }

    uint32 platformFeeInPPM = paymentService.getPlatformFeeInPPM();
    uint64 platformFee = (subtractAmount * platformFeeInPPM) / 1000000;
    uint64 returnToHost = subtractAmount - platformFee;

    valueToReturnInUsdCents -= subtractAmount;

    uint256 valueToReturnInEth = currencyConverterService.getEthFromUsd(
      valueToReturnInUsdCents,
      trip.paymentInfo.ethToCurrencyRate,
      trip.paymentInfo.ethToCurrencyDecimals
    );

    (bool successGuest, ) = payable(trip.guest).call{value: valueToReturnInEth}('');
    require(successGuest, 'Transfer to guest failed.');

    if (returnToHost > 0) {
      uint256 returnToHostInEth = currencyConverterService.getEthFromUsd(
        returnToHost,
        trip.paymentInfo.ethToCurrencyRate,
        trip.paymentInfo.ethToCurrencyDecimals
      );
      (bool successHost, ) = payable(trip.host).call{value: returnToHostInEth}('');
      require(successHost, 'Transfer to host failed.');
    }
  }

  /// @notice Finish a trip on the Rentality platform.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId) public {
    tripService.finishTrip(tripId);
    RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

    uint256 valueToHostInUsdCents = trip.paymentInfo.totalDayPriceInUsdCents +
      trip.paymentInfo.taxPriceInUsdCents +
      trip.paymentInfo.resolveAmountInUsdCents -
      paymentService.getPlatformFeeFrom(trip.paymentInfo.totalDayPriceInUsdCents + trip.paymentInfo.taxPriceInUsdCents);
    uint256 valueToHostInEth = currencyConverterService.getEthFromUsd(
      valueToHostInUsdCents,
      trip.paymentInfo.ethToCurrencyRate,
      trip.paymentInfo.ethToCurrencyDecimals
    );
    uint256 valueToGuestInUsdCents = trip.paymentInfo.depositInUsdCents - trip.paymentInfo.resolveAmountInUsdCents;
    uint256 valueToGuestInEth = currencyConverterService.getEthFromUsd(
      valueToGuestInUsdCents,
      trip.paymentInfo.ethToCurrencyRate,
      trip.paymentInfo.ethToCurrencyDecimals
    );
    //require(payable(trip.host).send(valueToHostInEth));
    //require(payable(trip.guest).send(valueToGuestInEth));
    (bool successHost, ) = payable(trip.host).call{value: valueToHostInEth}('');
    (bool successGuest, ) = payable(trip.guest).call{value: valueToGuestInEth}('');
    require(successHost, 'Transfer failed.');
    require(successGuest, 'Transfer failed.');
  }

  /// @notice Creates a new claim for a specific trip.
  /// @dev Only the host of the trip can create a claim, and certain trip status checks are performed.
  /// @param request Details of the claim to be created.
  function createClaim(RentalityClaimService.CreateClaimRequest memory request) public {
    RentalityTripService.Trip memory trip = tripService.getTrip(request.tripId);

    require(trip.host == tx.origin, 'Only for trip host.');
    require(
      trip.status != RentalityTripService.TripStatus.Canceled && trip.status != RentalityTripService.TripStatus.Created,
      'Wrong trip status.'
    );

    claimService.createClaim(request);
  }

  /// @notice Rejects a specific claim.
  /// @dev Only the host or guest of the associated trip can reject the claim.
  /// @param claimId ID of the claim to be rejected.
  function rejectClaim(uint256 claimId) public {
    RentalityClaimService.Claim memory claim = claimService.getClaim(claimId);
    RentalityTripService.Trip memory trip = tripService.getTrip(claim.tripId);

    require(trip.host == tx.origin || trip.guest == tx.origin, 'Only for trip guest or host.');

    claimService.rejectClaim(claimId, tx.origin);
  }

  /// @notice Pays a specific claim, transferring funds to the host and, if applicable, refunding excess to the guest.
  /// @dev Only the guest of the associated trip can pay the claim, and certain checks are performed.
  /// @param claimId ID of the claim to be paid.
  function payClaim(uint256 claimId) public payable {
    RentalityClaimService.Claim memory claim = claimService.getClaim(claimId);
    RentalityTripService.Trip memory trip = tripService.getTrip(claim.tripId);

    require(trip.guest == tx.origin, 'Only guest.');
    require(
      claim.status != RentalityClaimService.Status.Paid && claim.status != RentalityClaimService.Status.Cancel,
      'Wrong claim Status.'
    );

    uint256 valueToPay = currencyConverterService.getEthFromUsd(
      claim.amountInUsdCents,
      trip.paymentInfo.ethToCurrencyRate,
      trip.paymentInfo.ethToCurrencyDecimals
    );
    uint256 platformFee = paymentService.getPlatformFeeFrom(valueToPay);

    uint256 totalAmount = valueToPay + platformFee;

    require(msg.value >= totalAmount, 'Insufficient funds sent.');

    claimService.payClaim(claimId);

    (bool successHost, ) = payable(trip.host).call{value: valueToPay}('');
    require(successHost, 'Transfer to host failed.');

    if (msg.value > totalAmount) {
      uint256 excessValue = msg.value - totalAmount;
      (bool successRefund, ) = payable(tx.origin).call{value: excessValue}('');
      require(successRefund, 'Refund to guest failed.');
    }
  }

  /// @notice Updates the status of a specific claim based on the current timestamp.
  /// @dev This function is typically called periodically to check and update claim status.
  /// @param claimId ID of the claim to be updated.
  function updateClaim(uint256 claimId) public {
    claimService.updateClaim(claimId);
  }

  /// @notice Gets detailed information about a specific claim.
  /// @dev Returns a structure containing information about the claim, associated trip, and car details.
  /// @param claimId ID of the claim.
  /// @return Full information about the claim.
  function getClaimInfo(uint256 claimId) public view returns (RentalityClaimService.FullClaimInfo memory) {
    RentalityClaimService.Claim memory claim = claimService.getClaim(claimId);
    RentalityTripService.Trip memory trip = tripService.getTrip(claim.tripId);
    RentalityCarToken.CarInfo memory car = carService.getCarInfoById(trip.carId);
    string memory guestPhoneNumber = userService.getKYCInfo(trip.guest).mobilePhoneNumber;
    string memory hostPhoneNumber = userService.getKYCInfo(trip.host).mobilePhoneNumber;

    return RentalityClaimService.FullClaimInfo(claim, trip.host, trip.guest, guestPhoneNumber, hostPhoneNumber, car);
  }

  /// @notice Get contact information for a specific trip on the Rentality platform.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  function getTripContactInfo(
    uint256 tripId
  ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

    RentalityUserService.KYCInfo memory guestInfo = userService.getKYCInfo(trip.guest);
    RentalityUserService.KYCInfo memory hostInfo = userService.getKYCInfo(trip.host);

    return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
  }

  /// @notice Get KYC (Know Your Customer) information for the caller on the Rentality platform.
  /// @return kycInfo The KYC information for the caller.
  function getMyKYCInfo() external view returns (RentalityUserService.KYCInfo memory kycInfo) {
    return userService.getMyKYCInfo();
  }

  /// @notice Get chat information for trips hosted by the caller on the Rentality platform.
  /// @return chatInfo An array of chat information for trips hosted by the caller.
  function getChatInfoForHost() public view returns (IRentalityGateway.ChatInfo[] memory) {
    RentalityTripService.Trip[] memory trips = RentalityUtils.getTripsByHost(tripService, tx.origin);
    return RentalityUtils.populateChatInfo(trips, userService, carService);
  }

  /// @notice Get chat information for trips attended by the caller on the Rentality platform.
  /// @return chatInfo An array of chat information for trips attended by the caller.
  function getChatInfoForGuest() public view returns (IRentalityGateway.ChatInfo[] memory) {
    RentalityTripService.Trip[] memory trips = RentalityUtils.getTripsByGuest(tripService, tx.origin);
    return RentalityUtils.populateChatInfo(trips, userService, carService);
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
    address claimServiceAddress
  ) public initializer {
    carService = RentalityCarToken(carServiceAddress);
    currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
    tripService = RentalityTripService(tripServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    paymentService = RentalityPaymentService(paymentServiceAddress);
    claimService = RentalityClaimService(claimServiceAddress);

    __Ownable_init();
  }
}
