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
import './RentalityAdminGateway.sol';
import './libs/RentalityQuery.sol';

struct RentalityContract {
  RentalityCarToken carService;
  RentalityCurrencyConverter currencyConverterService;
  RentalityTripService tripService;
  RentalityUserService userService;
  RentalityPlatform rentalityPlatform;
  RentalityPaymentService paymentService;
  RentalityClaimService claimService;
  RentalityAdminGateway adminService;
}

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
  RentalityContract private addresses;
  /// @notice Ensures that the caller is a host.
  modifier onlyHost() {
    require(addresses.userService.isHost(msg.sender), 'User is not a host');
    _;
  }
  using RentalityQuery for RentalityContract;

  fallback(bytes calldata data) external payable returns (bytes memory) {
    (bool ok, bytes memory res) = address(addresses.rentalityPlatform).call{value: msg.value}(data);
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
  //    function updateServiceAddresses(RentalityContract memory contrcacts) public {
  //        carService = RentalityCarToken(adminService.getCarServiceAddress());
  //        currencyConverterService = RentalityCurrencyConverter(adminService.getCurrencyConverterServiceAddress());
  //        tripService = RentalityTripService(adminService.getTripServiceAddress());
  //        userService = RentalityUserService(adminService.getUserServiceAddress());
  //        rentalityPlatform = RentalityPlatform(adminService.getRentalityPlatformAddress());
  //        paymentService = RentalityPaymentService(adminService.getPaymentService());
  //        claimService = RentalityClaimService(adminService.getClaimServiceAddress());
  //        rentalityPlatform.updateServiceAddresses(adminService);
  //    }


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
  //      addresses.getClaimsByTrip(
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
  //    return addresses.getTripsByGuest(address(tripService), address(userService), address(carService), guest);
  //  }

  /// @notice Retrieves information about trips where the specified user is the host.
  /// @param host The address of the host.
  /// @return An array of trip information for the specified host.
  //  function getTripsByHost(address host) public view returns (Schemas.TripDTO[] memory) {
  //    return addresses.getTripsByHost(address(tripService), address(userService), address(carService), host);
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
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(rentalityPlatformAddress),
      RentalityPaymentService(paymentServiceAddress),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(rentalityAdminGatewayAddress)
    );

    __Ownable_init();
  }
}
