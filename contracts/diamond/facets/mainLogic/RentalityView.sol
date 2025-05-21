// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Schemas} from '../../../Schemas.sol';
import {RentalityViewLibDiamond} from '../../libraries/getters/RentalityViewLibDiamond.sol';
import {RentalityCarTokenHelper} from '../../libraries/getters/RentalityCarTokenHelper.sol';
import {RentalityTripsQueryDiamond} from '../../libraries/getters/RentalityTripsQueryDiamond.sol';
import {RentalityQueryDiamond} from '../../libraries/getters/RentalityQueryDiamond.sol';
import {CarTokenStorage} from '../../libraries/CarTokenStorage.sol';
import {InsuranceServiceStorage} from '../../libraries/InsuranceServiceStorage.sol';
import {UserServiceStorage} from '../../libraries/UserServiceStorage.sol';
import {PaymentsStorage} from '../../libraries/PaymentsStorage.sol';
import {CurrencyConverterStorage} from '../../libraries/CurrencyConverterStorage.sol';
import {GeoServiceStorage} from '../../libraries/GeoServiceStorage.sol';
import {TripServiceStorage} from '../../libraries/TripServiceStorage.sol';
import {RentalityPaymentsLib} from '../../libraries/getters/RentalityPaymentsLib.sol';

contract RentalityViewFacet {
  /// @notice Searches for available cars based on specified criteria.
  /// @param startDateTime The start date and time of the search.
  /// @param endDateTime The end date and time of the search.
  /// @param searchParams Additional search parameters.
  /// @param pickUpInfo Lat and lon of return and pickUp locations
  /// @param returnInfo Lat and lon of return and pickUp locations
  /// @return An array of available car information meeting the search criteria.
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  )
    public
    view
    returns (
      // bool useRefferalPoints
      Schemas.SearchCarWithDistance[] memory
    )
  {
    return
      RentalityQueryDiamond.searchSortedCars(
        msg.sender,
        startDateTime,
        endDateTime,
        searchParams,
        pickUpInfo,
        returnInfo
      );
  }

  /// @notice Retrieves information about trips where the caller is the host.
  /// @return An array of trip information.
  function getTripsAsHost() public view returns (Schemas.TripDTO[] memory) {
    return RentalityTripsQueryDiamond.getTripsAs(msg.sender, true);
  }

  /// TODO: after adding claims
  /// @notice Retrieves all claims where the caller is the host.
  /// @dev The caller is assumed to be the host of the claims.
  /// @return An array of FullClaimInfo containing information about each claim.
  //   function getMyClaimsAs(bool host) public view returns (Schemas.FullClaimInfo[] memory) {
  //     return addresses.getClaimsBy(host, msg.sender);
  //   }

  /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @param pickUpLocation lat and lon of pickUp and return locations.
  /// @param returnLocation lat and lon of pickUp and return locations.
  /// @return calculatePaymentsDTO An object containing payment details.
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation,
    string memory promo
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    return
      RentalityPaymentsLib.calculatePaymentsWithDelivery(
        carId,
        daysOfTrip,
        currency,
        pickUpLocation,
        returnLocation,
        promo,
        msg.sender
      );
  }
  /// @notice Get chat information for trips hosted by the caller on the Rentality platform.
  /// @return chatInfo An array of chat information for trips hosted by the caller.
  function getChatInfoFor(bool host) public view returns (Schemas.ChatInfo[] memory) {
    return RentalityTripsQueryDiamond.populateChatInfo(msg.sender, host);
  }

  /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(uint carId) public view returns (Schemas.DeliveryData memory) {
    return RentalityQueryDiamond.getDeliveryData(carId);
  }

  /// TODO: after adding promo
  //   function checkPromo(
  //     string memory promo,
  //     uint startDateTime,
  //     uint endDateTime
  //   ) public view returns (Schemas.CheckPromoDTO memory) {
  //     return promoService.checkPromo(promo, startDateTime, endDateTime);
  //   }

  //   function getAiDamageAnalyzeCaseData(uint tripId, bool pre) public view returns(Schemas.AiDamageAnalyzeCaseDataDTO memory) {
  //     Schemas.CarInfo memory car = addresses.carService.getCarInfoById(addresses.tripService.getTrip(tripId).carId);
  //     Schemas.FullKYCInfoDTO memory kyc = addresses.userService.getMyFullKYCInfo(msg.sender);

  //     return Schemas.AiDamageAnalyzeCaseDataDTO(
  //       aiDamageAnalyzeService.getCurrentCaseNumber(),
  //       kyc.additionalKYC.email,
  //       kyc.kyc.surname,
  //       aiDamageAnalyzeService.getInsuranceCaseByTrip(tripId, pre),
  //       car.carVinNumber
  //     );

  //   }

  /// @notice Retrieves the metadata URI of a car by its ID.
  /// @param carId The ID of the car.
  /// @return The metadata URI of the car.
  function getCarMetadataURI(uint256 carId) public view returns (string memory) {
    return CarTokenStorage.tokenUri(carId);
  }

  ///TODO: after adding claims
  //   function calculateClaimValue(uint claimdId) public view returns (uint) {
  //     return RentalityViewLibDiamond.calculateClaimValue(addresses, claimdId);
  //   }
}
