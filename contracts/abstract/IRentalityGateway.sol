// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../RentalityTripService.sol';
import '../Schemas.sol';

/// @title RentalityGateway
/// @notice This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Gateway contract.
interface IRentalityGateway {
  /// ------------------------------
  /// USER PROFILE functions
  /// ------------------------------

  /// @notice returns KYC(Know Your Customer) with additional info
  function getMyFullKYCInfo() external view returns (Schemas.FullKYCInfoDTO memory);

  /// @notice Set KYC (Know Your Customer) information for the caller
  /// @param nickName The nickname of the user
  /// @param mobilePhoneNumber The mobile phone number of the user
  /// @param profilePhoto The profile photo URL of the user
  /// @param TCSignature The signature of the Terms and Conditions
  /// @dev This function allows the caller to set their own KYC information
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    bytes memory TCSignature,
    bytes32 hash
  ) external;

  /// @notice Set KYC information for a specific user based on Civic identity
  /// @param user The address of the user whose Civic KYC information is being set
  /// @param civicKycInfo The Civic KYC information structure containing the user's data
  /// @dev This function is used to set verified KYC information from the Civic platform
  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo, bytes32) external;



  /// @param civicKycInfo The Civic KYC information structure containing the user's data
  /// @dev This function is used to set verified KYC information from the Civic platform
   function setMyCivicKYCInfo(Schemas.CivicKYCInfo memory civicKycInfo) external;

  /// @notice Retrieves the KYC commission amount.
  /// @dev Calls the `getKycCommission` function from the `userService` contract.
  /// @return The current KYC commission amount.
  function getKycCommission() external view returns (uint);

  ///  @notice Calculates the KYC commission for a given currency.
  ///  @param currency The address of the currency to calculate the KYC commission for.
  ///  @return The calculated KYC commission amount.
  function calculateKycCommission(address currency) external view returns (uint);

  /// @notice Pays the KYC commission.
  /// @dev This function should be called with the appropriate amount of Ether to cover the KYC commission.
  function payKycCommission(address currency) external payable;

  /// @notice Checks if the KYC commission has been paid by a user.
  /// @dev Calls the `isCommissionPaidForUser` function from the `userService` contract.
  /// @param user The address of the user to check.
  /// @return True if the KYC commission has been paid by the user, false otherwise.
  function isKycCommissionPaid(address user) external view returns (bool);

  ///  @notice Uses the KYC commission for a specific user.
  ///  @param user The address of the user whose KYC commission will be used.
  ///  @dev This function is typically called after the user has paid the KYC commission to apply it to their account.
  function useKycCommission(address user) external;

  /// ------------------------------
  /// HOST CARS functions
  /// ------------------------------

  /// @notice Add a new car to the platform.
  /// @param request The request parameters for creating a new car.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request, bytes32 refferalHash) external returns (uint);

  /// @notice Update information for an existing car, without location.
  /// @param request the Update car parameters
  function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) external;

  /// @notice Update information for an existing car with location
  /// @notice This sets geo verification status to false.
  /// @param request the Update car parameters
  /// @param location Single string that contains the car location
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;

  /// @notice Updates the token URI for a specific car
  /// @param carId The ID of the car whose token URI is being updated
  /// @param tokenUri The new token URI to be associated with the car
  /// @dev This function allows updating the metadata URI of a car token
  function updateCarTokenUri(uint256 carId, string memory tokenUri) external;

  /// @notice Get information about all cars owned by the caller
  /// @return An array of CarInfo structures containing details about the caller's cars
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory);

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);

  /// @notice Get the metadata URI for a specific car.
  /// @param carId The ID of the car.
  /// @return The metadata URI for the specified car.
  function getCarMetadataURI(uint256 carId) external view returns (string memory);

  /// @notice Get information about a specific car by ID.
  /// @param carId The ID of the car.
  /// @return CarInfo structure containing details about the specified car.
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfoWithInsurance memory);

  /// @notice Retrieves detailed information about a car.
  /// @param carId The ID of the car for which details are requested.
  /// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
  function getCarDetails(uint carId) external view returns (Schemas.CarDetails memory);

  /// @notice Gets the discount for a specific user.
  /// @param user The address of the user.
  /// @return The discount information for the user.
  function getDiscount(address user) external view returns (Schemas.BaseDiscount memory);

  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addUserDiscount(Schemas.BaseDiscount memory data) external;

  /// @notice Adds user delivery prices.
  /// @param underTwentyFiveMilesInUsdCents The delivery price in USD cents for distances under 25 miles.
  /// @param aboveTwentyFiveMilesInUsdCents The delivery price in USD cents for distances above 25 miles.
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;

  /// @dev Retrieves delivery data for a given user.
  /// @param user The user address for which delivery data is requested.
  /// @return deliveryPrices The user prices for delivery.
  function getUserDeliveryPrices(address user) external view returns (Schemas.DeliveryPrices memory);

  /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(uint carId) external view returns (Schemas.DeliveryData memory);

  /// ------------------------------
  /// TRIPS functions
  /// ------------------------------
  ///     GENERAL
  /// ------------------------------

  /// @notice Get information about all trips where the caller is the host.
  /// @return An array of Trip structures containing details about trips where the caller is the host.
  function getTripsAs(bool host) external view returns (Schemas.TripDTO[] memory);

  /// @notice Get information about a specific trip.
  /// @param tripId The ID of the trip.
  /// @return Trip structure containing details about the specified trip.
  function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory);

  /// @notice Get contact information for a trip.
  /// @param tripId The ID of the trip.
  /// @return guestPhoneNumber The phone number of the guest associated with the trip.
  /// @return hostPhoneNumber The phone number of the host associated with the trip.
  function getTripContactInfo(
    uint256 tripId
  ) external view returns (string memory guestPhoneNumber, string memory hostPhoneNumber);

   
    /// ------------------------------
  ///     HOST
  /// ------------------------------

  /// @notice Approve a trip request by its ID.
  /// @param tripId The ID of the trip to approve.
  function approveTripRequest(uint256 tripId) external;

  /// @notice Reject a trip request by its ID.
  /// @param tripId The ID of the trip to reject.
  function rejectTripRequest(uint256 tripId) external;

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
  ) external;

  /// @notice Performs check-out by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Confirms check-out for a trip.
  /// @param tripId The ID of the trip.
  function confirmCheckOut(uint256 tripId, bytes32) external;

  /// @notice Finish a trip as the host.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId, bytes32) external;

  /// ------------------------------
  ///     GUEST
  /// ------------------------------

  /// @notice Searches for available cars with delivery based on specified criteria
  /// @dev use an empty fields for latitude and longitude to skip location part
  /// @param startDateTime The start date and time for the car rental
  /// @param endDateTime The end date and time for the car rental
  /// @param searchParams Additional parameters used to filter the search (e.g., brand, model).
  /// @param pickUpInfo The location information for picking up the car
  /// @param returnInfo The location information for returning the car
  /// @return An array of car information, including distance from the specified location, that meets the search criteria
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.SearchCarWithDistance[] memory);

  /// @notice Calculates the total payment for a car rental with delivery service
  /// @dev use an empty fields for latitude and longitude to skip location part
  /// @param carId The ID of the car being rented
  /// @param daysOfTrip The number of days for the rental period
  /// @param currency The address of the currency used for payment (e.g., Ether or ERC20)
  /// @param pickUpLocation The location where the car will be picked up
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation
  ) external view returns (Schemas.CalculatePaymentsDTO memory);

  /// @notice Create a trip request.
  /// @param request The request parameters for creating a new trip.
  function createTripRequest(Schemas.CreateTripRequest memory request) external payable;

  /// @notice Create a trip request.
  /// @param request The request parameters for creating a new trip.
  function createTripRequestWithDelivery(Schemas.CreateTripRequestWithDelivery memory request) external payable;

  /// @notice Performs check-in by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Performs check-out by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams, bytes32 refferalHash) external;


  /// ------------------------------
  /// CLAIMS functions
  /// ------------------------------

  /// @notice Retrieves all claims where the caller is the host.
  /// @dev The caller is assumed to be the host of the claims.
  /// @return An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAs(bool host) external view returns (Schemas.FullClaimInfo[] memory);

  /// @notice Gets detailed information about a specific claim through the Rentality platform.
  /// @dev This function retrieves the claim information using the Rentality platform contract.
  /// @param claimId ID of the claim.
  /// @return Full information about the claim.
  function getClaim(uint256 claimId) external view returns (Schemas.FullClaimInfo memory);

  /// @notice Creates a new claim through the Rentality platform.
  /// @dev This function delegates the claim creation to the Rentality platform contract.
  /// @param request Details of the claim to be created.
  function createClaim(Schemas.CreateClaimRequest memory request) external;

  /// @notice Rejects a specific claim through the Rentality platform.
  /// @dev This function delegates the claim rejection to the Rentality platform contract.
  /// @param claimId ID of the claim to be rejected.
  function rejectClaim(uint256 claimId) external;

    /// @notice Calculates the claim value for a specified insurance claim
    /// @param claimId The ID of the insurance claim for which the value is being calculated
    /// @return The calculated claim value in the specified currency
    function calculateClaimValue(uint claimId) external view returns (uint);

    /// @notice Pays a specific claim through the Rentality platform, transferring funds and handling excess.
  /// @dev This function delegates the claim payment to the Rentality platform contract.
  /// @param claimId ID of the claim to be paid.
  function payClaim(uint256 claimId) external payable;

  /// @notice Updates the status of a specific claim through the Rentality platform.
  /// @dev This function delegates the claim update to the Rentality platform contract.
  /// @param claimId ID of the claim to be updated.
  //  function updateClaim(uint256 claimId) external;

  /// @notice Gets detailed information about a specific claim through the Rentality platform.
  /// @dev This function retrieves the claim information using the Rentality platform contract.
  /// @param claimId ID of the claim.
  /// @return Full information about the claim.
  //  function getClaim(uint256 claimId) external view returns (Schemas.FullClaimInfo memory);

  /// ------------------------------
  /// CHAT functions
  /// ------------------------------

  /// @notice Retrieves chat information for the caller acting as a host/guest.
  /// @param host A boolean indicating whether to retrieve insurance for hosts (true) or guests (false)
  /// @return An array of chat information.
  function getChatInfoFor(bool host) external view returns (Schemas.ChatInfo[] memory);

    /// ------------------------------
    /// GENERAL functions
    /// ------------------------------

  /// @notice Retrieves insurance info
  /// @param host A boolean indicating whether to retrieve insurance for hosts (true) or guests (false)
  /// @return An array of insurance options available for the specified host status
  function getInsurancesBy(bool host) external view returns (Schemas.InsuranceDTO[] memory);

  /// @notice Retrieves insurance information for the guest
  /// @return An array of insurance information specific to the guest
  function getMyInsurancesAsGuest() external view returns (Schemas.InsuranceInfo[] memory);

  /// @notice Saves insurance information related to a specific trip
  /// @param tripId The ID of the trip for which the insurance information is being saved
  /// @param insuranceInfo A struct containing the details of the insurance to be saved
  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) external;

  /// @notice Saves insurance information for a guest
  /// @param insuranceInfo A struct containing the details of the insurance requested by the guest
  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) external;

  /// ------------------------------
  /// GENERAL functions
  /// ------------------------------

  /// @dev Returns the owner of the contract.
  /// @return The address of the contract owner.
  function owner() external view returns (address);

  /// @notice This function retrieves the actual service addresses
  function updateServiceAddresses() external;

  /// ------------------------------
  /// NOT USED ON FRONT
  /// ------------------------------

  /// @notice This function provides a detailed receipt of the trip, including payment information and trip details.
  /// @param tripId The ID of the trip for which the receipt is requested.
  /// @return tripReceipt An instance of `Schemas.TripReceiptDTO` containing the trip receipt details.
  function getTripReceipt(uint tripId) external view returns (Schemas.TripReceiptDTO memory);

  /// @notice Get information about all available cars.
  /// @return An array of CarInfo structures containing details about available cars.
  function getAvailableCars() external view returns (Schemas.CarInfo[] memory);

  /// @notice Retrieves information about all cars.
  /// @return An array of car information.
  function getAllCars() external view returns (Schemas.CarInfo[] memory);


  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.AvailableCarDTO memory);

  // function updateCarTokenUri(uint256 carId, string memory tokenUri) external;
  /// @notice Retrieves additional filter information based on the duration of the trip
  /// @param duration The total number of days for the car rental
  /// @return Schemas.FilterInfoDTO A data structure containing additional filter information, optimized for the specified rental duration
  function getFilterInfo(uint64 duration) external view returns (Schemas.FilterInfoDTO memory);
  /// @return An array of available car information for the specified user.
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);

}
