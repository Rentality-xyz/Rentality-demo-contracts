// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import { RentalityViewLibDiamond } from "../../libraries/getters/RentalityViewLibDiamond.sol";
import { RentalityCarTokenHelper } from "../../libraries/getters/RentalityCarTokenHelper.sol";
import { RentalityTripsQueryDiamond } from "../../libraries/getters/RentalityTripsQueryDiamond.sol";
import { RentalityQueryDiamond } from "../../libraries/getters/RentalityQueryDiamond.sol";
import { CarTokenStorage } from "../../libraries/CarTokenStorage.sol";
import { InsuranceServiceStorage } from "../../libraries/InsuranceServiceStorage.sol";
import { UserServiceStorage } from "../../libraries/UserServiceStorage.sol";
import { PaymentsStorage } from "../../libraries/PaymentsStorage.sol";
import { CurrencyConverterStorage } from "../../libraries/CurrencyConverterStorage.sol";
import { GeoServiceStorage } from "../../libraries/GeoServiceStorage.sol";
import { TripServiceStorage } from "../../libraries/TripServiceStorage.sol";
import {RentalityPaymentsLib} from "../../libraries/getters/RentalityPaymentsLib.sol";

contract RentalityViewFacet2 {
/// @notice Retrieves information about a car by its ID.
  /// @param carId The ID of the car.
  /// @return Car information as a struct.
  function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfoWithInsurance memory) {
    return
      Schemas.CarInfoWithInsurance(
        CarTokenStorage.getCarInfoById(carId),
        InsuranceServiceStorage.getCarInsuranceInfo(carId),
        CarTokenStorage.tokenUri(carId)
      );
  }


//   // not using
  /// @notice Retrieves information about all cars.
  /// @return An array of car information.
  function getAllCars() public view returns (Schemas.CarInfo[] memory) {
    return RentalityCarTokenHelper.getAllCars();
  }

  // not using
   /// @notice Retrieves information about available cars for a specific user.
   /// @param user The address of the user.
   /// @return An array of available car information for the specified user.
  function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
    return RentalityCarTokenHelper.getAvailableCarsForUser(user);
  }


  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) public view returns (Schemas.AvailableCarDTO memory) {
    return
      RentalityViewLibDiamond.checkCarAvailabilityWithDelivery(
        carId,
        msg.sender,
        startDateTime,
        endDateTime,
        pickUpInfo,
        returnInfo
      );
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
  ) public view returns (Schemas.SearchCarWithDistance[] memory) {
    return
      RentalityQueryDiamond.searchSortedCars(
        msg.sender,
        startDateTime,
        endDateTime,
        searchParams,
        GeoServiceStorage.getLocationInfo(bytes32('')),
        GeoServiceStorage.getLocationInfo(bytes32(''))
      );
  }

    function getUniqCarsBrand() public view returns (string[] memory brandsArray) {
    return RentalityViewLibDiamond.getUniqCarsBrand();
  }
  function getUniqModelsByBrand(string memory brand) public view returns (string[] memory modelsArray) {
    return RentalityViewLibDiamond.getUniqModelsByBrand(brand);
  }


  function getFilterInfo(
    uint64 duration
  ) public view returns (Schemas.FilterInfoDTO memory) {
    uint64 maxCarPrice = 0;
    uint minCarYearOfProduction = CarTokenStorage.getCarInfoById(1).yearOfProduction;

    for (uint i = 2; i <= CarTokenStorage.totalSupply(); i++) {
      Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(i);

      uint64 sumWithDiscount = PaymentsStorage.calculateSumWithDiscount(
        CarTokenStorage.ownerOf(i),
        duration,
        car.pricePerDayInUsdCents
      );
      if (sumWithDiscount > maxCarPrice) maxCarPrice = sumWithDiscount;
      if (car.yearOfProduction < minCarYearOfProduction) minCarYearOfProduction = car.yearOfProduction;
    }
    return Schemas.FilterInfoDTO(maxCarPrice, minCarYearOfProduction);
  }

  /// @notice Calculates the KYC commission in a specific currency based on the current exchange rate.
  /// @dev This function uses the currency converter service to calculate the commission in the specified currency.
  /// @param currency The address of the currency in which the commission should be calculated.
  /// @return The KYC commission amount in the specified currency.
  function calculateKycCommission(address currency) public view returns (uint) {
    (uint result, , ) = CurrencyConverterStorage.getFromUsdLatest(
      currency,
      UserServiceStorage.getKycCommission()
    );

    return result;
  }

   /// @notice Retrieves information about cars owned by the caller.
  /// @return An array of car information owned by the caller.
  function getMyCars() public view returns (Schemas.CarInfoDTO[] memory) {
    return RentalityQueryDiamond.getCarsOwnedByUserWithEditability(msg.sender);
  }

  /// @notice Retrieves detailed information about a car.
  /// @param carId The ID of the car for which details are requested.
  /// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
  function getCarDetails(uint carId) public view returns (Schemas.CarDetails memory) {
    return RentalityQueryDiamond.getCarDetails(carId);
  }




}