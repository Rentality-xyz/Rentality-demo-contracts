// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '../RentalityCarToken.sol';
import '../RentalityTripService.sol';
import '../Schemas.sol';
import {IRentalityPlatform} from './IRentalityPlatform.sol';

/// @title RentalityGateway
/// @notice This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Gateway contract.
interface IRentalityGateway is IRentalityPlatform {

  /// ------------------------------
  /// USER PROFILE functions
  /// ------------------------------

  /// @notice fullKYCInfo returns KYC(Know Your Customer) with additional info
  function getMyFullKYCInfo() external view returns (Schemas.FullKYCInfoDTO memory fullKYCInfo);

  /// @notice Retrieves the KYC commission amount.
  /// @dev Calls the `getKycCommission` function from the `userService` contract.
  /// @return kycCommision The current KYC commission amount.
  function getKycCommission() external view returns (uint kycCommision);

  ///  @notice Calculates the KYC commission for a given currency.
  ///  @param currency The address of the currency to calculate the KYC commission for.
  ///  @return kycCommision The calculated KYC commission amount.
  function calculateKycCommission(address currency) external view returns (uint kycCommision);

  /// @notice Checks if the KYC commission has been paid by a user.
  /// @dev Calls the `isCommissionPaidForUser` function from the `userService` contract.
  /// @param user The address of the user to check.
  /// @return isPaid True if the KYC commission has been paid by the user, false otherwise.
  function isKycCommissionPaid(address user) external view returns (bool isPaid);

  /// ------------------------------
  /// HOST CARS functions
  /// ------------------------------

  /// @notice Get information about all cars owned by the caller
  /// @return myCars An array of CarInfo structures containing details about the caller's cars
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory myCars);

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return publicHostCarDTO An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory publicHostCarDTO);

  /// @notice Get the metadata URI for a specific car.
  /// @param carId The ID of the car.
  /// @return metadataURI The metadata URI for the specified car.
  function getCarMetadataURI(uint256 carId) external view returns (string memory metadataURI);

  /// @notice Get information about a specific car by ID.
  /// @param carId The ID of the car.
  /// @return carInfoWithInsurance structure containing details about the specified car.
  function getCarInfoById(
    uint256 carId
  ) external view returns (Schemas.CarInfoWithInsurance memory carInfoWithInsurance);

  /// @notice Retrieves detailed information about a car.
  /// @param carId The ID of the car for which details are requested.
  /// @return carDetails An instance of `Schemas.CarDetails` containing the details of the specified car.
  function getCarDetails(uint carId) external view returns (Schemas.CarDetails memory carDetails);

  /// @notice Gets the discount for a specific user.
  /// @param user The address of the user.
  /// @return baseDiscount The discount information for the user.
  function getDiscount(address user) external view returns (Schemas.BaseDiscount memory baseDiscount);

  /// @dev Retrieves delivery data for a given user.
  /// @param user The user address for which delivery data is requested.
  /// @return deliveryPrices The user prices for delivery.
  function getUserDeliveryPrices(address user) external view returns (Schemas.DeliveryPrices memory deliveryPrices);

  /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(uint carId) external view returns (Schemas.DeliveryData memory deliveryData);

  function getUniqCarsBrand() external view returns (string[] memory brandsArray);

  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray);

  /// ------------------------------
  /// TRIPS functions
  /// ------------------------------

  /// @notice Get information about all trips where the caller is the host.
  /// @return tripDTO An array of Trip structures containing details about trips where the caller is the host.
  function getTripsAs(bool host) external view returns (Schemas.TripDTO[] memory tripDTO);

  /// @notice Get information about a specific trip.
  /// @param tripId The ID of the trip.
  /// @return tripDTO structure containing details about the specified trip.
  function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory tripDTO);

  /// @notice Get contact information for a trip.
  /// @param tripId The ID of the trip.
  /// @return guestPhoneNumber The phone number of the guest associated with the trip.
  /// @return hostPhoneNumber The phone number of the host associated with the trip.
  function getTripContactInfo(
    uint256 tripId
  ) external view returns (string memory guestPhoneNumber, string memory hostPhoneNumber);

  /// @notice Searches for available cars with delivery based on specified criteria
  /// @dev use an empty fields for latitude and longitude to skip location part
  /// @param startDateTime The start date and time for the car rental
  /// @param endDateTime The end date and time for the car rental
  /// @param searchParams Additional parameters used to filter the search (e.g., brand, model).
  /// @param pickUpInfo The location information for picking up the car
  /// @param returnInfo The location information for returning the car
  /// @return foundCarsWithDistance An array of car information, including distance from the specified location, that meets the search criteria
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (Schemas.SearchCarsWithDistanceDTO memory foundCarsWithDistance);

  /// @notice Calculates the total payment for a car rental with delivery service
  /// @dev use an empty fields for latitude and longitude to skip location part
  /// @param carId The ID of the car being rented
  /// @param daysOfTrip The number of days for the rental period
  /// @param currency The address of the currency used for payment (e.g., Ether or ERC20)
  /// @param calculatePaymentsDTO pickUpLocation The location where the car will be picked up
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation,
    string memory promoCode
  ) external view returns (Schemas.CalculatePaymentsDTO memory calculatePaymentsDTO);

  /// ------------------------------
  /// CLAIMS functions
  /// ------------------------------

  /// @notice Retrieves all claims where the caller is the host.
  /// @dev The caller is assumed to be the host of the claims.
  /// @return fullClaimInfos An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAs(bool host) external view returns (Schemas.FullClaimInfo[] memory fullClaimInfos);

  /// @notice Gets detailed information about a specific claim through the Rentality platform.
  /// @dev This function retrieves the claim information using the Rentality platform contract.
  /// @param claimId ID of the claim.
  /// @return fullClaimInfo Full information about the claim.
  function getClaim(uint256 claimId) external view returns (Schemas.FullClaimInfo memory fullClaimInfo);

  /// @notice Calculates the claim value for a specified insurance claim
  /// @param claimId The ID of the insurance claim for which the value is being calculated
  /// @return calculatedClaimValue The calculated claim value in the specified currency
  function calculateClaimValue(uint claimId) external view returns (uint calculatedClaimValue);

  /// ------------------------------
  /// CHAT functions
  /// ------------------------------

  /// @notice Retrieves chat information for the caller acting as a host/guest.
  /// @param host A boolean indicating whether to retrieve insurance for hosts (true) or guests (false)
  /// @return chatInfo An array of chat information.
  function getChatInfoFor(bool host) external view returns (Schemas.ChatInfo[] memory chatInfo);

  /// ------------------------------
  /// GENERAL functions
  /// ------------------------------

  /// @notice Retrieves insurance info
  /// @param host A boolean indicating whether to retrieve insurance for hosts (true) or guests (false)
  /// @return insuranceDTO An array of insurance options available for the specified host status
  function getInsurancesBy(bool host) external view returns (Schemas.InsuranceDTO[] memory insuranceDTO);

  /// @notice Retrieves insurance information for the guest
  /// @return insuranceInfo An array of insurance information specific to the guest
  function getMyInsurancesAsGuest() external view returns (Schemas.InsuranceInfo[] memory insuranceInfo);

  function getGuestInsurance(address guest) external view returns (Schemas.InsuranceInfo[] memory insuranceInfo);

  function getTaxesInfoById(uint taxId) external view returns (Schemas.TaxesInfoDTO memory taxesInfoDTO);

  /// @dev Returns the owner of the contract.
  /// @return owner The address of the contract owner.
  function owner() external view returns (address owner);

  /// ------------------------------
  /// NOT USED ON FRONT
  /// ------------------------------

  /// @notice This function provides a detailed receipt of the trip, including payment information and trip details.
  /// @param tripId The ID of the trip for which the receipt is requested.
  /// @return tripReceiptDTO tripReceipt An instance of `Schemas.TripReceiptDTO` containing the trip receipt details.
  function getTripReceipt(uint tripId) external view returns (Schemas.TripReceiptDTO memory tripReceiptDTO);

  /// @notice Get information about all available cars.
  /// @return carInfo An array of CarInfo structures containing details about available cars.
  function getAvailableCars() external view returns (Schemas.CarInfo[] memory carInfo);

  /// @notice Retrieves information about all cars.
  /// @return carInfos An array of car information.
  function getAllCars() external view returns (Schemas.CarInfo[] memory carInfos);

  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.AvailableCarDTO memory availableCarDTO);

  /// @notice Retrieves additional filter information based on the duration of the trip
  /// @param duration The total number of days for the car rental
  /// @return filterInfoDTO Schemas.FilterInfoDTO A data structure containing additional filter information, optimized for the specified rental duration
  function getFilterInfo(uint64 duration) external view returns (Schemas.FilterInfoDTO memory filterInfoDTO);

  /// @return carInfo An array of available car information for the specified user.
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory carInfo);

  function checkPromo(
    string memory promo,
    uint startDateTime,
    uint endDateTime
  ) external view returns (Schemas.CheckPromoDTO memory checkPromoDTO);

  function getDimoVihicles() external view returns (uint[] memory dimoVihicles);

  function getAvaibleCurrencies() external view returns (Schemas.Currency[] memory avaibleCurrencies);

  function getAiDamageAnalyzeCaseRequest(
    uint,
    Schemas.CaseType
  ) external view returns (Schemas.AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest);

  function getUserCurrency(address user) external view returns (Schemas.UserCurrencyDTO memory userCurrency);

  function getTotalCarsAmount() external view returns (uint totalCarsAmount);

  function getPlatformInfo() external view returns(Schemas.PlatformInfoDTO memory platformInfo);

  function getHostInsuranceClaims() external view returns(Schemas.FullClaimInfo[] memory claims);

  function getHostInsuranceRule(address host) external view returns(Schemas.HostInsuranceRuleDTO memory insuranceRules);

  function getAllInsuranceRules() external view returns(Schemas.HostInsuranceRuleDTO[] memory insuranceRules);

  function getAvailableCurrency() external view returns(Schemas.AllowedCurrencyDTO[] memory);

  function getHostInsuranceBalance() external view returns(uint);
}

