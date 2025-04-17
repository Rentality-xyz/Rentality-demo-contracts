// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import { Schemas } from "../../Schemas.sol";
// import {TripServiceStorage} from "../../libraries/TripServiceStorage.sol";
// import {CarTokenStorage} from "../../libraries/CarTokenStorage.sol";
// import {TaxesStorage} from "../../libraries/TaxesStorage.sol";
// import {CurrencyConverterStorage} from "../../libraries/CurrencyConverterStorage.sol";
// import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
// import {RentalityTripsHelper} from "../../libraries/getters/RentalityTripsHelper.sol";
// import {RentalityUtils} from "../../libraries/getters/RentalityUtils.sol";
// import {InsuranceServiceStorage} from "../../libraries/InsuranceServiceStorage.sol";
// import {PaymentsStorage} from "../../libraries/PaymentsStorage.sol";
// import {RefferalServiceStorage} from "../../libraries/RefferalServiceStorage.sol";
// import {InsuranceServiceStorage} from "../../libraries/InsuranceServiceStorage.sol";

// contract RentalityView {
// /// @notice Retrieves information about a car by its ID.
//   /// @param carId The ID of the car.
//   /// @return Car information as a struct.
//   function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfoWithInsurance memory) {
//     return
//       Schemas.CarInfoWithInsurance(
//         CarTokenStorage.getCarInfoById(carId),
//         InsuranceServiceStorage.getCarInsuranceInfo(carId),
//         CarTokenStorage.tokenURI(carId)
//       );
//   }


//   // not using
//   /// @notice Retrieves information about all cars.
//   /// @return An array of car information.
//   function getAllCars() public view returns (Schemas.CarInfo[] memory) {
//     return addresses.carService.getAllCars();
//   }

//   // not using
//   /// @notice Retrieves information about available cars for a specific user.
//   /// @param user The address of the user.
//   /// @return An array of available car information for the specified user.
//   function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
//     return CarTokenHelper.getAvailableCarsForUser(user);
//   }

//   /// @notice Searches for available cars based on specified criteria.
//   /// @param startDateTime The start date and time of the search.
//   /// @param endDateTime The end date and time of the search.
//   /// @param searchParams Additional search parameters.
//   /// @return An array of available car information meeting the search criteria.
//   function searchAvailableCars(
//     uint64 startDateTime,
//     uint64 endDateTime,
//     Schemas.SearchCarParams memory searchParams
//   ) public view returns (Schemas.SearchCarWithDistance[] memory) {
//     return
//       addresses.searchSortedCars(
//         tx.origin,
//         startDateTime,
//         endDateTime,
//         searchParams,
//         IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getLocationInfo(bytes32('')),
//         IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getLocationInfo(bytes32('')),
//         RentalityAdminGateway(addresses.adminService).getDeliveryServiceAddress(),
//         address(insuranceService)
//       );
//   }

//   function checkCarAvailabilityWithDelivery(
//     uint carId,
//     uint64 startDateTime,
//     uint64 endDateTime,
//     Schemas.LocationInfo memory pickUpInfo,
//     Schemas.LocationInfo memory returnInfo
//   ) public view returns (Schemas.AvailableCarDTO memory) {
//     return
//       RentalityViewLib.checkCarAvailabilityWithDelivery(
//         addresses,
//         carId,
//         _msgGatewaySender(),
//         startDateTime,
//         endDateTime,
//         pickUpInfo,
//         returnInfo,
//         addresses.adminService.getDeliveryServiceAddress(),
//         address(insuranceService),
//         address(dimoService)
//       );
//   }
//   /// @notice Searches for available cars based on specified criteria.
//   /// @param startDateTime The start date and time of the search.
//   /// @param endDateTime The end date and time of the search.
//   /// @param searchParams Additional search parameters.
//   /// @param pickUpInfo Lat and lon of return and pickUp locations
//   /// @param returnInfo Lat and lon of return and pickUp locations
//   /// @return An array of available car information meeting the search criteria.
//   function searchAvailableCarsWithDelivery(
//     uint64 startDateTime,
//     uint64 endDateTime,
//     Schemas.SearchCarParams memory searchParams,
//     Schemas.LocationInfo memory pickUpInfo,
//     Schemas.LocationInfo memory returnInfo
//   )
//     public
//     view
//     returns (
//       // bool useRefferalPoints
//       Schemas.SearchCarWithDistance[] memory
//     )
//   {
//     return
//       addresses.searchSortedCars(
//         _msgGatewaySender(),
//         startDateTime,
//         endDateTime,
//         searchParams,
//         pickUpInfo,
//         returnInfo,
//         RentalityAdminGateway(addresses.adminService).getDeliveryServiceAddress(),
//         address(insuranceService),
//         address(dimoService)
//       );
//   }

//   /// @notice Retrieves information about cars owned by the caller.
//   /// @return An array of car information owned by the caller.
//   function getMyCars() public view returns (Schemas.CarInfoDTO[] memory) {
//     return RentalityUtils.getCarsOwnedByUserWithEditability(addresses, dimoService, _msgGatewaySender());
//   }

//   /// @notice Retrieves detailed information about a car.
//   /// @param carId The ID of the car for which details are requested.
//   /// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
//   function getCarDetails(uint carId) public view returns (Schemas.CarDetails memory) {
//     return RentalityUtils.getCarDetails(addresses, carId, dimoService);
//   }

//   /// @notice Retrieves information about trips where the caller is the host.
//   /// @return An array of trip information.
//   // function getTripsAsHost() public view returns (Schemas.TripDTO[] memory) {
//   // return RentalityTripsQuery.getTripsByHost(addresses, insuranceService, tx.origin);
//   // }

//   // not using
//   /// @notice Retrieves information about trips for a specific car.
//   /// @param carId The ID of the car.
//   /// @return An array of trip information for the specified car.
//   // function getTripsByCar(uint256 carId) public view returns (Schemas.Trip[] memory) {
//   // return addresses.getTripsByCar(carId);
//   // }

//   /// @notice Retrieves all claims where the caller is the host.
//   /// @dev The caller is assumed to be the host of the claims.
//   /// @return An array of FullClaimInfo containing information about each claim.
//   function getMyClaimsAs(bool host) public view returns (Schemas.FullClaimInfo[] memory) {
//     return addresses.getClaimsBy(host, _msgGatewaySender());
//   }

//   // not using
//   /// @notice Gets detailed information about a specific claim.
//   /// @dev Returns a structure containing information about the claim, associated trip, and car details.
//   /// @param claimId ID of the claim.
//   /// @return Full information about the claim.
//   function getClaim(uint256 claimId) public view returns (Schemas.FullClaimInfo memory) {
//     return RentalityUtils.getClaim(addresses, claimId);
//   }

//   /// @notice Retrieves the cars owned by a specific host.
//   /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
//   /// @param host The address of the host for whom to retrieve the cars.
//   /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
//   function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
//     return addresses.carService.getCarsOfHost(host);
//   }
//   /// @notice Get a discount.
//   /// @param user The address of user discount.
//   function getDiscount(address user) public view returns (Schemas.BaseDiscount memory) {
//     return addresses.paymentService.getBaseDiscount(user);
//   }

//   /// @dev Calculates the payments for a trip.
//   /// @param carId The ID of the car.
//   /// @param daysOfTrip The duration of the trip in days.
//   /// @param currency The currency to use for payment calculation.
//   /// @return calculatePaymentsDTO An object containing payment details.
//   // function calculatePayments(
//   //   uint carId,
//   //   uint64 daysOfTrip,
//   //   address currency
//   // ) public view returns (Schemas.CalculatePaymentsDTO memory) {
//   //   return RentalityUtils.calculatePayments(addresses, carId, daysOfTrip, currency, 0, insuranceService);
//   // }

//   /// @dev Calculates the payments for a trip.
//   /// @param carId The ID of the car.
//   /// @param daysOfTrip The duration of the trip in days.
//   /// @param currency The currency to use for payment calculation.
//   /// @param pickUpLocation lat and lon of pickUp and return locations.
//   /// @param returnLocation lat and lon of pickUp and return locations.
//   /// @return calculatePaymentsDTO An object containing payment details.
//   function calculatePaymentsWithDelivery(
//     uint carId,
//     uint64 daysOfTrip,
//     address currency,
//     Schemas.LocationInfo memory pickUpLocation,
//     Schemas.LocationInfo memory returnLocation,
//     string memory promo
//   ) public view returns (Schemas.CalculatePaymentsDTO memory) {
//     return
//       RentalityUtils.calculatePaymentsWithDelivery(
//         addresses,
//         carId,
//         daysOfTrip,
//         currency,
//         pickUpLocation,
//         returnLocation,
//         insuranceService,
//         promo,
//         promoService,
//         _msgGatewaySender()
//       );
//   }
//   /// @notice Get chat information for trips hosted by the caller on the Rentality platform.
//   /// @return chatInfo An array of chat information for trips hosted by the caller.
//   function getChatInfoFor(bool host) public view returns (Schemas.ChatInfo[] memory) {
//     return
//       RentalityTripsQuery.populateChatInfo(
//         addresses,
//         insuranceService,
//         _msgGatewaySender(),
//         host,
//         promoService,
//         dimoService
//       );
//   }

//   /// @dev Retrieves delivery data for a given car.
//   /// @param carId The ID of the car for which delivery data is requested.
//   /// @return deliveryData The delivery data including location details and delivery prices.
//   function getDeliveryData(uint carId) public view returns (Schemas.DeliveryData memory) {
//     return RentalityUtils.getDeliveryData(addresses, carId);
//   }

//   /// @dev Retrieves delivery data for a given user.
//   /// @param user The user address for which delivery data is requested.
//   /// @return deliveryData The delivery data including location details and delivery prices.
//   function getUserDeliveryPrices(address user) public view returns (Schemas.DeliveryPrices memory) {
//     return RentalityCarDelivery(addresses.adminService.getDeliveryServiceAddress()).getUserDeliveryPrices(user);
//   }

//   /// @notice Retrieves the KYC commission amount.
//   /// @dev Calls the `getKycCommission` function from the `userService` contract.
//   /// @return The current KYC commission amount.
//   function getKycCommission() public view returns (uint) {
//     return addresses.userService.getKycCommission();
//   }

//   /// @notice Checks if the KYC commission has been paid by a user.
//   /// @dev Calls the `isCommissionPaidForUser` function from the `userService` contract.
//   /// @param user The address of the user to check.
//   /// @return True if the KYC commission has been paid by the user, false otherwise.
//   function isKycCommissionPaid(address user) public view returns (bool) {
//     return addresses.userService.isCommissionPaidForUser(user);
//   }
//   function getMyFullKYCInfo() public view returns (Schemas.FullKYCInfoDTO memory) {
//     return addresses.userService.getMyFullKYCInfo(_msgGatewaySender());
//   }
//   function getInsurancesBy(bool host) public view returns (Schemas.InsuranceDTO[] memory) {
//     return RentalityTripsQuery.getTripInsurancesBy(host, addresses, insuranceService, _msgGatewaySender());
//   }

//   function calculateClaimValue(uint claimdId) public view returns (uint) {
//     return RentalityViewLib.calculateClaimValue(addresses, claimdId);
//   }

//   function getMyInsurancesAsGuest() public view returns (Schemas.InsuranceInfo[] memory) {
//     return insuranceService.getMyInsurancesAsGuest(_msgGatewaySender());
//   }
// }