// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './payments/RentalityPaymentService.sol';
import './RentalityPlatform.sol';
import './abstract/IRentalityAdminGateway.sol';
import {RentalityContract, RentalityGateway} from './RentalityGateway.sol';

contract RentalityAdminGateway is UUPSOwnable, IRentalityAdminGateway {
  RentalityCarToken private carService;
  RentalityCurrencyConverter private currencyConverterService;
  RentalityTripService private tripService;
  RentalityUserService private userService;
  RentalityPlatform private rentalityPlatform;
  RentalityPaymentService private paymentService;
  RentalityClaimService private claimService;
  RentalityCarDelivery private deliveryService;
  RentalityView private viewService;

  /// @notice Ensures that the caller is either an admin, the contract owner, or an admin from the origin transaction.
  modifier onlyAdmin() {
    require(
      userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) || (tx.origin == owner()),
      'User is not an admin'
    );
    _;
  }
  function getRentalityContracts() public view returns (RentalityContract memory) {
    return
      RentalityContract(
        carService,
        currencyConverterService,
        tripService,
        userService,
        rentalityPlatform,
        paymentService,
        claimService,
        RentalityAdminGateway(this),
        deliveryService,
        viewService
      );
  }

  /// @notice Retrieves the address of the RentalityCarToken contract.
  /// @return The address of the RentalityCarToken contract.
  function getCarServiceAddress() public view returns (address) {
    return address(carService);
  }

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCarToken contract.
  function updateCarService(address contractAddress) public onlyAdmin {
    carService = RentalityCarToken(contractAddress);
  }
  /// @notice Retrieves the address of the RentalityPayment contract.
  /// @return The address of the RentalityPayment contract.
  function getPaymentService() public view returns (address) {
    return address(paymentService);
  }

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPayment contract.
  function updatePaymentService(address contractAddress) public onlyAdmin {
    paymentService = RentalityPaymentService(payable(contractAddress));
  }
  /// @notice Retrieves the address of the RentalityClaim contract.
  /// @return The address of the RentalityClaim contract.
  function getClaimServiceAddress() public view returns (address) {
    return address(claimService);
  }

  /// @notice Updates the address of the RentalityClaim contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityClaim contract.
  function updateClaimService(address contractAddress) public onlyAdmin {
    claimService = RentalityClaimService(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityPlatform contract.
  /// @return The address of the RentalityPlatform contract.
  function getRentalityPlatformAddress() public view returns (address) {
    return address(rentalityPlatform);
  }

  /// @notice Updates the address of the RentalityPlatform contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPlatform contract.
  function updateRentalityPlatform(address contractAddress) public onlyAdmin {
    rentalityPlatform = RentalityPlatform(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityCurrencyConverter contract.
  /// @return The address of the RentalityCurrencyConverter contract.
  function getCurrencyConverterServiceAddress() public view returns (address) {
    return address(currencyConverterService);
  }

  /// @notice Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCurrencyConverter contract.
  function updateCurrencyConverterService(address contractAddress) public onlyAdmin {
    currencyConverterService = RentalityCurrencyConverter(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityTripService contract.
  /// @return The address of the RentalityTripService contract.
  function getTripServiceAddress() public view returns (address) {
    return address(tripService);
  }

  /// @notice Updates the address of the RentalityTripService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityTripService contract.
  function updateTripService(address contractAddress) public onlyAdmin {
    tripService = RentalityTripService(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityUserService contract.
  /// @return The address of the RentalityUserService contract.
  function getUserServiceAddress() public view returns (address) {
    return address(userService);
  }

  /// @notice Updates the address of the RentalityUserService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityUserService contract.
  function updateUserService(address contractAddress) public onlyAdmin {
    userService = RentalityUserService(contractAddress);
  }

  /// @notice Updates the address of the GeoService contract.
  /// @param newGeoServiceAddress The new address of the GeoService contract.
  function updateGeoServiceAddress(address newGeoServiceAddress) public onlyAdmin {
    carService.updateGeoServiceAddress(newGeoServiceAddress);
  }

  /// @notice Updates the address of the GeoParser contract.
  /// @param newGeoParserAddress The new address of the GeoParser contract.
  function updateGeoParserAddress(address newGeoParserAddress) public onlyAdmin {
    carService.updateGeoParsesAddress(newGeoParserAddress);
  }

  /// @notice Retrieves the address of the RentalityCarDelivery contract.
  /// @return The address of the RentalityCarDelivery contract.
  function getDeliveryServiceAddress() public view returns (address) {
    return address(deliveryService);
  }

  /// @notice Updates the address of the RentalityCarDelivery contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCarDeliveryn contract.
  function updateDeliveryService(address contractAddress) public onlyAdmin {
    deliveryService = RentalityCarDelivery(contractAddress);
  }

  /// @notice Withdraws the specified amount from the RentalityPlatform contract.
  /// @param amount The amount to withdraw.
  /// @param tokenAddress one of available on Rentality currency
  function withdrawFromPlatform(uint256 amount, address tokenAddress) public {
    paymentService.withdrawFromPlatform(amount, tokenAddress);
  }

  /// @notice Withdraws the entire balance from the RentalityPlatform contract.
  /// @param tokenAddress one of available on Rentality currency
  function withdrawAllFromPlatform(address tokenAddress) public {
    uint balance = currencyConverterService.isETH(tokenAddress)
      ? address(paymentService).balance
      : IERC20(tokenAddress).balanceOf(address(paymentService));

    paymentService.withdrawFromPlatform(balance, tokenAddress);
  }
  /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
  /// @param valueInPPM The new platform fee value in PPM.
  function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
    paymentService.setPlatformFeeInPPM(valueInPPM);
  }

  /// @notice Adds currency to list of available on Rentality,
  /// by providing ERC20 token address, and corresponding Rentality service for calculation.
  function addCurrency(address tokenAddress, address rentalityTokenService) public onlyAdmin {
    currencyConverterService.addCurrencyType(tokenAddress, rentalityTokenService);
  }

  /// @dev Sets the waiting time, only callable by administrators.
  /// @param timeInSec, set old value to this
  function setClaimsWaitingTime(uint timeInSec) public {
    claimService.setWaitingTime(timeInSec);
  }

  /// @dev get waiting time to approval
  /// @return waiting time to approval in sec
  function getClaimWaitingTime() public view returns (uint) {
    return claimService.getWaitingTime();
  }

  /// @notice Retrieves the platform fee in parts per million (PPM).
  /// @return The platform fee in PPM.
  function getPlatformFeeInPPM() public view returns (uint32) {
    return paymentService.getPlatformFeeInPPM();
  }

  /// @notice Retrieves the platform fee calculated from the given value.
  /// @param value The value from which to calculate the platform fee.
  /// @return The calculated platform fee.
  function getPlatformFeeFrom(uint256 value) private view returns (uint256) {
    return paymentService.getPlatformFeeFrom(value);
  }

  /// @notice Calculates the total cost with applied discount for a trip.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The original value of the trip.
  /// @param user the address of discount provider
  /// @return The total cost after applying the discount.
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return paymentService.calculateSumWithDiscount(user, daysOfTrip, value);
  }

  /// @notice Calculates the taxes for a trip based on the specified tax ID.
  /// @param taxesId The ID of the taxes contract.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The original value of the trip.
  /// @return The total taxes for the trip.
  function calculateTaxes(uint taxesId, uint64 daysOfTrip, uint64 value) public view returns (uint64, uint64) {
    return paymentService.calculateTaxes(taxesId, daysOfTrip, value);
  }

  /// @notice Adds a new taxes contract to the payment service.
  /// @param taxesContactAddress The address of the taxes contract to add.
  function addTaxesContract(address taxesContactAddress) public {
    paymentService.addTaxesContract(taxesContactAddress);
  }

  /// @notice Adds a new discount contract to the payment service.
  /// @param discountContactAddress The address of the discount contract to add.
  function addDiscountContract(address discountContactAddress) public {
    paymentService.addDiscountContract(discountContactAddress);
  }

  /// @notice Changes the current discount contract used by the payment service.
  /// @param discountContract The address of the new discount contract.
  function changeCurrentDiscountType(address discountContract) public {
    paymentService.changeCurrentDiscountType(discountContract);
  }

  /// @notice Confirms check-out for a trip.
  /// @param tripId The ID of the trip.
  function payToHost(uint256 tripId) public {
    rentalityPlatform.confirmCheckOut(tripId);
  }

  /// @notice Rejects a trip request. Only callable by hosts.
  /// @param tripId The ID of the trip to reject.
  function refundToGuest(uint256 tripId) public {
    return rentalityPlatform.rejectTripRequest(tripId);
  }
  /// @dev Sets the Civic verifier and gatekeeper network for identity verification.
  /// @param _civicVerifier The address of the Civic verifier contract.
  /// @param _civicGatekeeperNetwork The identifier of the Civic gatekeeper network.
  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) public {
    userService.setCivicData(_civicVerifier, _civicGatekeeperNetwork);
  }

  // @notice Sets a new message for the Terms and Conditions (TC) and updates the corresponding hashed message.
  /// @dev This function can only be called by an admin.
  /// @param message The new message for the TC.
  function setNewTCMessage(string memory message) public {
    userService.setNewTCMessage(message);
  }

  function setPlatformFee(uint value) public {
    claimService.setPlatformFee(value);
  }

  function setKycCommission(uint value) public {
    userService.setKycCommission(value);
  }

  function getKycCommission() public view returns (uint) {
    return userService.getKycCommission();
  }

  function getAllTrips(
    Schemas.TripFilter memory filter,
    uint page,
    uint itemsPerPage
  ) public view returns (Schemas.AllTripsDTO memory) {
    uint totalTripsCount = tripService.totalTripCount();

    uint[] memory matchedTrips = new uint[](totalTripsCount);

    uint counter = 0;
    for (uint i = 1; i <= totalTripsCount; i++) {
      if (isTripMatch(filter, tripService.getTrip(i))) {
        matchedTrips[counter] = i;
        counter += 1;
      }
    }
    if (counter == 0) return Schemas.AllTripsDTO(new Schemas.Trip[](0), 0);
    uint totalPageCount = (counter + itemsPerPage - 1) / itemsPerPage;

    if (page > totalPageCount) {
      page = totalPageCount;
    }

    uint startIndex = (page - 1) * itemsPerPage;
    uint endIndex = startIndex + itemsPerPage;

    if (endIndex > counter) {
      endIndex = counter;
    }
    Schemas.Trip[] memory result = new Schemas.Trip[](endIndex - startIndex);
    for (uint i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = tripService.getTrip(matchedTrips[i]);
    }

    return Schemas.AllTripsDTO(result, totalPageCount);
  }

  function isTripMatch(Schemas.TripFilter memory filter, Schemas.Trip memory trip) internal view returns (bool) {
    IRentalityGeoService geoService = IRentalityGeoService(carService.getGeoServiceAddress());
    Schemas.LocationInfo memory locationInfo = geoService.getLocationInfo(
      carService.getCarInfoById(trip.carId).locationHash
    );
    return ((bytes(filter.location.country).length == 0 ||
      RentalityUtils.containWord(
        RentalityUtils.toLower(locationInfo.country),
        RentalityUtils.toLower(filter.location.country)
      )) &&
      (bytes(filter.location.state).length == 0 ||
        RentalityUtils.containWord(
          RentalityUtils.toLower(locationInfo.state),
          RentalityUtils.toLower(filter.location.state)
        )) &&
      (bytes(filter.location.city).length == 0 ||
        RentalityUtils.containWord(
          RentalityUtils.toLower(locationInfo.city),
          RentalityUtils.toLower(filter.location.city)
        )) &&
      (filter.startDateTime <= trip.startDateTime && filter.endDateTime >= trip.endDateTime) &&
      (filter.paymentStatus == Schemas.PaymentStatus.Any ||
        (filter.paymentStatus == Schemas.PaymentStatus.PaidToHost && trip.status == Schemas.TripStatus.Finished) ||
        (filter.paymentStatus == Schemas.PaymentStatus.Prepayment &&
          (trip.status == Schemas.TripStatus.Created ||
            trip.status == Schemas.TripStatus.Approved ||
            trip.status == Schemas.TripStatus.CheckedInByHost ||
            (trip.status == Schemas.TripStatus.CheckedInByGuest && trip.tripStartedBy == trip.guest) ||
            (trip.status == Schemas.TripStatus.CheckedOutByGuest && trip.tripFinishedBy == trip.guest) ||
            (trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest))) ||
        (filter.paymentStatus == Schemas.PaymentStatus.RefundToGuest && trip.status == Schemas.TripStatus.Canceled) ||
        (filter.paymentStatus == Schemas.PaymentStatus.Unpaid &&
          ((trip.status == Schemas.TripStatus.CheckedInByGuest && trip.tripStartedBy == trip.host) ||
            (trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.host)))) &&
      (filter.status == Schemas.AdminTripStatus.Any ||
        (filter.status == Schemas.AdminTripStatus.Created && trip.status == Schemas.TripStatus.Created) ||
        (filter.status == Schemas.AdminTripStatus.Approved && trip.status == Schemas.TripStatus.Approved) ||
        (filter.status == Schemas.AdminTripStatus.CheckedInByHost &&
          trip.status == Schemas.TripStatus.CheckedInByHost) ||
        (filter.status == Schemas.AdminTripStatus.CheckedInByGuest &&
          trip.status == Schemas.TripStatus.CheckedInByGuest &&
          trip.tripStartedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.CheckedOutByGuest &&
          trip.status == Schemas.TripStatus.CheckedOutByGuest &&
          trip.tripFinishedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.CheckedOutByHost &&
          trip.status == Schemas.TripStatus.CheckedOutByHost &&
          trip.tripFinishedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.Finished && trip.status == Schemas.TripStatus.Finished) ||
        (filter.status == Schemas.AdminTripStatus.GuestCanceledBeforeApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime == 0 &&
          trip.rejectedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.HostCanceledBeforeApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime == 0 &&
          trip.rejectedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.GuestCanceledAfterApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime > 0 &&
          trip.rejectedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.HostCanceledAfterApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime > 0 &&
          trip.rejectedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.CompletedWithoutGuestConfirmation &&
          trip.status == Schemas.TripStatus.CheckedOutByHost &&
          trip.tripFinishedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.CompletedByGuest &&
          trip.status == Schemas.TripStatus.Finished &&
          trip.tripFinishedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.CompletedByAdmin &&
          trip.status == Schemas.TripStatus.Finished &&
          tripService.completedByAdmin(trip.tripId))));
  }

  //  @dev Initializes the contract with the provided addresses for various services.
  //  @param carServiceAddress The address of the RentalityCarToken contract.
  //  @param currencyConverterServiceAddress The address of the RentalityCurrencyConverter contract.
  //  @param tripServiceAddress The address of the RentalityTripService contract.
  //  @param userServiceAddress The address of the RentalityUserService contract.
  //  @param rentalityPlatformAddress The address of the RentalityPlatform contract.
  //  @param paymentServiceAddress The address of the RentalityPaymentService contract.
  //  Requirements:
  //  - The contract must not have been initialized before.
  function initialize(
    address carServiceAddress,
    address currencyConverterServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address rentalityPlatformAddress,
    address paymentServiceAddress,
    address claimServiceAddress,
    address carDeliveryAddress,
    address viewServiceAddress
  ) public initializer {
    carService = RentalityCarToken(carServiceAddress);
    currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
    tripService = RentalityTripService(tripServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
    paymentService = RentalityPaymentService(payable(paymentServiceAddress));
    claimService = RentalityClaimService(claimServiceAddress);
    deliveryService = RentalityCarDelivery(carDeliveryAddress);
    viewService = RentalityView(viewServiceAddress);

    viewService.updateServiceAddresses(getRentalityContracts());
    __Ownable_init();
  }
}
