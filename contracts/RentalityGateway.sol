// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
//deployed 27.06.2023 11:10 to sepolia at 0x18744A3f7D15930446B1dbc5A837562e468B2D8d

import './features/RentalityClaimService.sol';
import './abstract/IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './payments/RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './RentalityPlatform.sol';
import './payments/RentalityPaymentService.sol';
import './Schemas.sol';
import './RentalityAdminGateway.sol';

/// @title RentalityGateway
/// @notice The main gateway contract that connects various services in the Rentality platform.
/// Users can interact with the car service, trip service, user service, and payment service through this gateway.
/// Admins can update the addresses of connected services.
/// Hosts and guests can perform actions related to car rentals and trips.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityGateway is UUPSOwnable /*, IRentalityGateway*/ {
  RentalityCarToken private carService;
  RentalityCurrencyConverter private currencyConverterService;
  RentalityTripService private tripService;
  RentalityUserService private userService;
  RentalityPlatform private rentalityPlatform;
  RentalityPaymentService private paymentService;
  RentalityClaimService private claimService;
  RentalityAdminGateway private adminService;

  /// @notice Ensures that the caller is a host.
  modifier onlyHost() {
    require(userService.isHost(msg.sender), 'User is not a host');
    _;
  }

  fallback(bytes calldata data) external payable returns (bytes memory) {
    (bool ok, bytes memory res) = address(rentalityPlatform).call{value: msg.value}(data);
    if (!ok) {
      // For correct encoding revert message
      assembly {
        revert(add(32, res), mload(res))
      }
    }
    return res;
  }

  /// @dev Updates the addresses of various services used in the Rentality platform.
  ///
  /// This function retrieves the actual service addresses from the `adminService` and updates
  /// the contract's state variables with these addresses. The services include:
  /// - Car Token Service
  /// - Currency Converter Service
  /// - Trip Service
  /// - User Service
  /// - Platform Service
  /// - Payment Service
  /// - Claim Service
  ///
  /// This function should be called whenever the addresses of the services change.
  function updateServiceAddresses() public {
    carService = RentalityCarToken(adminService.getCarServiceAddress());
    currencyConverterService = RentalityCurrencyConverter(adminService.getCurrencyConverterServiceAddress());
    tripService = RentalityTripService(adminService.getTripServiceAddress());
    userService = RentalityUserService(adminService.getUserServiceAddress());
    rentalityPlatform = RentalityPlatform(adminService.getRentalityPlatformAddress());
    paymentService = RentalityPaymentService(adminService.getPaymentService());
    claimService = RentalityClaimService(adminService.getClaimServiceAddress());
    rentalityPlatform.updateServiceAddresses(adminService);
  }

  /// @notice Retrieves information about a car by its ID.
  /// @param carId The ID of the car.
  /// @return Car information as a struct.
  function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfo memory) {
    return carService.getCarInfoById(carId);
  }

  /// @notice Retrieves the metadata URI of a car by its ID.
  /// @param carId The ID of the car.
  /// @return The metadata URI of the car.
  function getCarMetadataURI(uint256 carId) public view returns (string memory) {
    return carService.tokenURI(carId);
  }

  /// @notice Adds a new car using the provided request. Grants host role to the caller if not already a host.
  /// @param request The request containing car information.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request) public returns (uint) {
    if (!userService.isHost(msg.sender)) {
      userService.grantHostRole(msg.sender);
    }
    return carService.addCar(request);
  }

  /// @notice Updates the information of a car. Only callable by hosts.
  /// @param request The request containing updated car information.
  function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) public onlyHost {
    require(RentalityQuery.isCarEditable(request.carId, address(tripService)), 'Car is not available for update.');

    return carService.updateCarInfo(request, '', '', '', '');
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
  ) public onlyHost {
    require(RentalityQuery.isCarEditable(request.carId, address(tripService)), 'Car is not available for update.');

    return carService.updateCarInfo(request, location, locationLatitude, locationLongitude, geoApiKey);
  }

  // function updateCarInfo(
  //     RentalityCarToken.UpdateCarInfoRequest memory request
  // ) public onlyHost {
  //     return
  //         carService.updateCarInfo(
  //             request.carId,
  //             request.pricePerDayInUsdCents,
  //             request.securityDepositPerTripInUsdCents,
  //             request.fuelPricePerGalInUsdCents,
  //             request.milesIncludedPerDay,
  //             request.country,
  //             request.state,
  //             request.city,
  //             request.locationLatitudeInPPM,
  //             request.locationLongitudeInPPM,
  //             request.currentlyListed
  //         );
  // }

  /// @notice Retrieves information about all cars.
  /// @return An array of car information.
  function getAllCars() public view returns (Schemas.CarInfo[] memory) {
    return carService.getAllCars();
  }

  /// @notice Retrieves information about available cars for a specific user.
  /// @param user The address of the user.
  /// @return An array of available car information for the specified user.
  function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
    return carService.getAvailableCarsForUser(user);
  }

  /// @notice Searches for available cars based on specified criteria.
  /// @param startDateTime The start date and time of the search.
  /// @param endDateTime The end date and time of the search.
  /// @param searchParams Additional search parameters.
  /// @return An array of available car information meeting the search criteria.
  function searchAvailableCars(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams
  ) public view returns (Schemas.SearchCar[] memory) {
    return tripService.searchAvailableCarsForUser(tx.origin, startDateTime, endDateTime, searchParams);
  }

  /// @notice Retrieves information about cars owned by the caller.
  /// @return An array of car information owned by the caller.
  function getMyCars() public view returns (Schemas.CarInfoDTO[] memory) {
    return RentalityQuery.getCarsOwnedByUserWithEditability(address(tripService), address(carService));
  }

  /// @notice Retrieves detailed information about a car.
  /// @param carId The ID of the car for which details are requested.
  /// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
  function getCarDetails(uint carId) public view returns (Schemas.CarDetails memory) {
    return RentalityQuery.getCarDetails(address(adminService), carId);
  }

  /// @notice Performs check-in by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByHost(uint256 tripId, uint64[] memory panelParams) public {
    return tripService.checkInByHost(tripId, panelParams);
  }

  /// @notice Performs check-in by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) public {
    return tripService.checkInByGuest(tripId, panelParams);
  }

  /// @notice Performs check-out by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) public {
    return tripService.checkOutByGuest(tripId, panelParams);
  }

  /// @notice Performs check-out by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) public {
    return tripService.checkOutByHost(tripId, panelParams);
  }

  /// @notice Retrieves information about a trip by ID.
  /// @param tripId The ID of the trip.
  /// @return Trip information.
  function getTrip(uint256 tripId) public view returns (Schemas.TripDTO memory) {
    return RentalityQuery.getTripDTO(tripId, address(userService), address(tripService), address(carService));
  }

  /// @notice Retrieves information about trips where the caller is the guest.
  /// @return An array of trip information.
  function getTripsAsGuest() public view returns (Schemas.TripDTO[] memory) {
    return RentalityQuery.getTripsByGuest(address(tripService), address(userService), address(carService), tx.origin);
  }

  /// @notice Retrieves information about trips where the caller is the host.
  /// @return An array of trip information.
  function getTripsAsHost() public view returns (Schemas.TripDTO[] memory) {
    return RentalityQuery.getTripsByHost(address(tripService), address(userService), address(carService), tx.origin);
  }

  /// @notice Retrieves information about trips for a specific car.
  /// @param carId The ID of the car.
  /// @return An array of trip information for the specified car.
  function getTripsByCar(uint256 carId) public view returns (Schemas.Trip[] memory) {
    return RentalityQuery.getTripsByCar(address(tripService), carId);
  }

  /// @notice Retrieves all claims where the caller is the host.
  /// @dev The caller is assumed to be the host of the claims.
  /// @return An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAsHost() public view returns (Schemas.FullClaimInfo[] memory) {
    return
      RentalityQuery.getClaimsByHost(
        address(claimService),
        address(tripService),
        address(carService),
        address(userService),
        address(currencyConverterService),
        msg.sender
      );
  }

  ///  @notice Retrieves all claims where the caller is the guest.
  ///  @dev The caller is assumed to be the guest of the claims.
  ///  @return An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAsGuest() public view returns (Schemas.FullClaimInfo[] memory) {
    return
      RentalityQuery.getClaimsByGuest(
        address(claimService),
        address(tripService),
        address(carService),
        address(userService),
        address(currencyConverterService),
        msg.sender
      );
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
    if (!userService.isGuest(msg.sender)) {
      userService.grantGuestRole(msg.sender);
    }
    return
      userService.setKYCInfo(
        name,
        surname,
        mobilePhoneNumber,
        profilePhoto,
        licenseNumber,
        expirationDate,
        TCSignature
      );
  }

  /// @notice Retrieves KYC information for the caller.
  /// @return KYC information for the caller.
  function getMyKYCInfo() external view returns (Schemas.KYCInfo memory) {
    return userService.getMyKYCInfo();
  }

  /// @notice This function provides a detailed receipt of the trip, including payment information and trip details.
  /// @param tripId The ID of the trip for which the receipt is requested.
  /// @return tripReceipt An instance of `Schemas.TripReceiptDTO` containing the trip receipt details.
  function getTripReceipt(uint tripId) public view returns (Schemas.TripReceiptDTO memory) {
    return RentalityUtils.fullFillTripReceipt(tripId, address(tripService));
  }

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
    return carService.getCarsOfHost(host);
  }
  /// @notice Parses the geolocation response and stores parsed data.
  /// @param carId The ID of the car for which geolocation is parsed.
  function parseGeoResponse(uint carId) public {
    IRentalityGeoService(carService.getGeoServiceAddress()).parseGeoResponse(carId);
  }
  /// @notice Get a discount.
  /// @param user The address of user discount.
  function getDiscount(address user) public view returns (Schemas.BaseDiscount memory) {
    return paymentService.getBaseDiscount(user);
  }

  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addUserDiscount(Schemas.BaseDiscount memory data) public {
    paymentService.addBaseDiscount(msg.sender, data);
  }

  // Unused
  /// @notice Searches for available cars for a specific user based on specified criteria.
  /// @param user The address of the user.
  /// @param startDateTime The start date and time of the search.
  /// @param endDateTime The end date and time of the search.
  /// @param searchParams Additional search parameters.
  /// @return An array of available car information meeting the search criteria for the specified user.
  //  function searchAvailableCarsForUser(
  //    address user,
  //    uint64 startDateTime,
  //    uint64 endDateTime,
  //    Schemas.SearchCarParams memory searchParams
  //  ) public view returns (Schemas.SearchCar[] memory) {
  //    return tripService.searchAvailableCarsForUser(user, startDateTime, endDateTime, searchParams);
  //  }

  /// @notice Retrieves KYC information for the specified user.
  /// @param user The address of the user.
  /// @return KYC information for the specified user.
  //  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory) {
  //    return userService.getKYCInfo(user);
  //  }

  /// @notice Gets an array of claims associated with a specific trip through the Rentality platform.
  /// @dev This function retrieves an array of detailed claim information for the given trip using the Rentality platform contract.
  /// @param tripId ID of the trip.
  /// @return Array of detailed claim information.
  //  function getClaimsByTrip(uint256 tripId) public view returns (Schemas.FullClaimInfo[] memory) {
  //    return
  //      RentalityQuery.getClaimsByTrip(
  //        address(claimService),
  //        address(tripService),
  //        address(carService),
  //        address(userService),
  //        address(currencyConverterService),
  //        tripId
  //      );
  //  }

  /// @notice Updates the token URI of a car. Only callable by hosts.
  /// @param carId The ID of the car to update.
  /// @param tokenUri The new token URI.
  //  function updateCarTokenUri(uint256 carId, string memory tokenUri) public onlyHost {
  //    return carService.updateCarTokenUri(carId, tokenUri);
  //  }

  //  /// @notice Burns (disables) a car. Only callable by hosts.
  //  /// @param carId The ID of the car to burn.
  //  function burnCar(uint256 carId) public onlyHost {
  //    return carService.burnCar(carId);
  //  }

  /// @notice Retrieves information about available cars.
  /// @return An array of available car information.'
  //  function getAvailableCars() public view returns (Schemas.CarInfo[] memory) {
  //    return getAvailableCarsForUser(tx.origin);
  //  }
  /// @notice Retrieves information about trips where the specified user is the guest.
  /// @param guest The address of the guest.
  /// @return An array of trip information for the specified guest.
  //  function getTripsByGuest(address guest) public view returns (Schemas.TripDTO[] memory) {
  //    return RentalityQuery.getTripsByGuest(address(tripService), address(userService), address(carService), guest);
  //  }

  /// @notice Retrieves information about trips where the specified user is the host.
  /// @param host The address of the host.
  /// @return An array of trip information for the specified host.
  //  function getTripsByHost(address host) public view returns (Schemas.TripDTO[] memory) {
  //    return RentalityQuery.getTripsByHost(address(tripService), address(userService), address(carService), host);
  //  }

  //TODO!! Platform funcs, delete after full refactoring

  /// @notice Creates a trip request. Callable by users with payment.
  /// @param request The trip request details.
  //  function createTripRequest(Schemas.CreateTripRequest memory request) public payable {
  //    return rentalityPlatform.createTripRequest{value: msg.value}(request);
  //  }

  /// @notice Retrieves contact information for a trip. Only callable by hosts or guests.
  /// @param tripId The ID of the trip.
  /// @return guestPhoneNumber
  /// @return hostPhoneNumber
  /// The guest's and host's phone numbers.
  //    function getTripContactInfo(
  //        uint256 tripId
  //    ) public view onlyHostOrGuest returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
  //        return rentalityPlatform.getTripContactInfo(tripId);
  //    }

  /// @notice Approves a trip request. Only callable by hosts.
  /// @param tripId The ID of the trip to approve.
  //  function approveTripRequest(uint256 tripId) public {
  //    return rentalityPlatform.approveTripRequest(tripId);
  //  }

  /// @notice Rejects a trip request. Only callable by hosts.
  /// @param tripId The ID of the trip to reject.
  //  function rejectTripRequest(uint256 tripId) public {
  //    return rentalityPlatform.rejectTripRequest(tripId);
  //  }

  /// @notice Retrieves chat information for the caller acting as a host.
  /// @return An array of chat information.
  //    function getChatInfoForHost() public view returns (Schemas.ChatInfo[] memory) {
  //        return rentalityPlatform.getChatInfoForHost();
  //    }
  //
  //    /// @notice Retrieves chat information for the caller acting as a guest.
  //    /// @return An array of chat information.
  //    function getChatInfoForGuest() public view returns (Schemas.ChatInfo[] memory) {
  //        return rentalityPlatform.getChatInfoForGuest();
  //    }

  /// @notice Creates a new claim through the Rentality platform.
  /// @dev This function delegates the claim creation to the Rentality platform contract.
  /// @param request Details of the claim to be created.
  //  function createClaim(Schemas.CreateClaimRequest memory request) public {
  //    rentalityPlatform.createClaim(request);
  //  }

  /// @notice Rejects a specific claim through the Rentality platform.
  /// @dev This function delegates the claim rejection to the Rentality platform contract.
  /// @param claimId ID of the claim to be rejected.
  //  function rejectClaim(uint256 claimId) public {
  //    rentalityPlatform.rejectClaim(claimId);
  //  }

  /// @notice Pays a specific claim through the Rentality platform, transferring funds and handling excess.
  /// @dev This function delegates the claim payment to the Rentality platform contract.
  /// @param claimId ID of the claim to be paid.
  //  function payClaim(uint256 claimId) public payable {
  //    rentalityPlatform.payClaim{value: msg.value}(claimId);
  //  }

  /// @notice Updates the status of a specific claim through the Rentality platform.
  /// @dev This function delegates the claim update to the Rentality platform contract.
  /// @param claimId ID of the claim to be updated.
  //  function updateClaim(uint256 claimId) public {
  //    rentalityPlatform.updateClaim(claimId);
  //  }

  /// @notice Gets detailed information about a specific claim through the Rentality platform.
  /// @dev This function retrieves the claim information using the Rentality platform contract.
  /// @param claimId ID of the claim.
  /// @return Full information about the claim.
  //    function getClaim(uint256 claimId) public view returns (Schemas.FullClaimInfo memory) {
  //        return rentalityPlatform.getClaimInfo(claimId);
  //    }

  /// @notice Confirms check-out for a trip.
  /// @param tripId The ID of the trip.
  //  function confirmCheckOut(uint256 tripId) public {
  //    rentalityPlatform.confirmCheckOut(tripId);
  //  }

  /// @notice Finishes a trip.
  //  function finishTrip(uint256 tripId) public {
  //    return rentalityPlatform.finishTrip(tripId);
  //  }

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
    address rentalityAdminGatewayAddress
  ) public initializer {
    carService = RentalityCarToken(carServiceAddress);
    currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
    tripService = RentalityTripService(tripServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
    paymentService = RentalityPaymentService(paymentServiceAddress);
    claimService = RentalityClaimService(claimServiceAddress);
    adminService = RentalityAdminGateway(rentalityAdminGatewayAddress);

    __Ownable_init();
  }
}
