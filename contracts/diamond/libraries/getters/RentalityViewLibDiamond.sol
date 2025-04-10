// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import {CarTokenStorage} from '../CarTokenStorage.sol';
import {GeoServiceStorage} from '../GeoServiceStorage.sol';
import {DeliveryStorage} from '../DeliveryStorage.sol';
import {DimoServiceStorage} from '../DimoServiceStorage.sol';
import {InsuranceServiceStorage} from '../InsuranceServiceStorage.sol';
import {CurrencyConverterStorage} from '../CurrencyConverterStorage.sol';
import {UserServiceStorage} from '../UserServiceStorage.sol';
import {TaxesStorage} from '../TaxesStorage.sol';
import {TripServiceStorage} from '../TripServiceStorage.sol';
import {PaymentsStorage} from '../PaymentsStorage.sol';
import {RentalityUtilsDiamond} from './RentalityUtilsDiamond.sol';
import {RentalityCarTokenHelper} from './RentalityCarTokenHelper.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityTripsQueryDiamond} from './RentalityTripsQueryDiamond.sol';


library RentalityViewLibDiamond {
// @notice Retrieves all trips based on the provided filter and pagination.
  /// @param filter The filter to apply to the trips.
  /// @param page The current page number.
  /// @param itemsPerPage The number of items per page.
  /// @return A structure containing the filtered trips and total page count.
  function getAllTrips(
    Schemas.TripFilter memory filter,
    uint page,
    uint itemsPerPage
  ) internal view returns (Schemas.AllTripsDTO memory) {
    TripServiceStorage.TripServiceFaucetStorage storage tripServiceStorage = TripServiceStorage.accessStorage();
    uint totalTripsCount = tripServiceStorage._tripIdCounter;

    uint[] memory matchedTrips = new uint[](totalTripsCount);

    uint counter = 0;
    for (uint i = 1; i <= totalTripsCount; i++) {
      if (isTripMatch(filter, TripServiceStorage.getTrip(i))) {
        matchedTrips[counter] = i;
        counter += 1;
      }
    }
    if (counter == 0) return Schemas.AllTripsDTO(new Schemas.AdminTripDTO[](0), 0);

    uint totalPageCount = (counter + itemsPerPage - 1) / itemsPerPage;

    if (page > totalPageCount) {
      page = totalPageCount;
    }

    uint startIndex = (page - 1) * itemsPerPage;
    uint endIndex = startIndex + itemsPerPage;

    if (endIndex > counter) {
      endIndex = counter;
    }

    Schemas.AdminTripDTO[] memory result = new Schemas.AdminTripDTO[](endIndex - startIndex);
    for (uint i = startIndex; i < endIndex; i++) {
      Schemas.Trip memory trip = TripServiceStorage.getTrip(matchedTrips[i]);
      Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(trip.carId);
      result[i - startIndex] = Schemas.AdminTripDTO(
        trip,
        CarTokenStorage.tokenUri(trip.carId),
        GeoServiceStorage.getLocationInfo(car.locationHash),
        Schemas.PromoDTO("", 0, 0)
      );
    }

    return Schemas.AllTripsDTO(result, totalPageCount);
  }

  // @notice Checks if a trip matches the provided filter.
  /// @dev This function is used internally to filter trips based on the given criteria.
  /// @param filter The filter to apply.
  /// @param trip The trip to check against the filter.
  /// @return Returns true if the trip matches the filter, otherwise false.
  function isTripMatch(
    Schemas.TripFilter memory filter,
    Schemas.Trip memory trip
  ) internal view returns (bool) {
    TripServiceStorage.TripServiceFaucetStorage storage tripServiceStorage = TripServiceStorage.accessStorage();
    Schemas.LocationInfo memory locationInfo = GeoServiceStorage.getLocationInfo(
      CarTokenStorage.getCarInfoById(trip.carId).locationHash
    );
    return ((bytes(filter.location.country).length == 0 ||
      RentalityUtilsDiamond.containWord(
        RentalityUtilsDiamond.toLower(locationInfo.country),
        RentalityUtilsDiamond.toLower(filter.location.country)
      )) &&
      (bytes(filter.location.state).length == 0 ||
        RentalityUtilsDiamond.containWord(
          RentalityUtilsDiamond.toLower(locationInfo.state),
          RentalityUtilsDiamond.toLower(filter.location.state)
        )) &&
      (bytes(filter.location.city).length == 0 ||
        RentalityUtilsDiamond.containWord(
          RentalityUtilsDiamond.toLower(locationInfo.city),
          RentalityUtilsDiamond.toLower(filter.location.city)
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
          tripServiceStorage.completedByAdmin[trip.tripId])));
  }

  function getFilterInfo(
    uint64 duration
  ) internal view returns (Schemas.FilterInfoDTO memory) {
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

  
    // TODO: update after adding investment
//   function calculatePercentage(
//     uint invested,
//     uint totalPrice,
//     RentalityCurrencyConverter converter
//   ) internal view returns (uint, uint) {
//     uint percentages = invested == 0 ? 0 : Math.ceilDiv(invested * 100, totalPrice);
//     (uint investInUsd, , ) = converter.getToUsdLatest(address(0), invested);
//     return (percentages, investInUsd);
//   }

//   function getAllMyTokensWithTotalPrice(
//     address user,
//     RentalityInvestmentNft nftContract
//   ) internal view returns (uint[] memory, uint, uint, uint) {
//     uint[] memory result = new uint[](nftContract.balanceOf(user));
//     uint counter = 0;
//     uint totalPrice = 0;
//     (uint totalSupply, uint totalHolders) = nftContract.totalSupplyWithTotalHolders();
//     for (uint i = 1; i <= totalSupply; i++)
//       if (nftContract.ownerOf(i) == user) {
//         result[counter] = i;
//         counter += 1;
//         totalPrice += nftContract.tokenIdToPriceInEth(i);
//       }
//     return (result, totalPrice, totalHolders, totalSupply);
//   }

  function getUniqCarsBrand() internal view returns (string[] memory) {
    uint totalSupply = CarTokenStorage.totalSupply();
    uint realAmount = 0;
    string[] memory brandsArray = new string[](totalSupply);
    for (uint i = 1; i <= totalSupply; i++) {
      Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(i);
      string memory carBrand = car.brand;
      if (car.currentlyListed && _isUniqInStringInArray(brandsArray, carBrand, realAmount)) {
        brandsArray[realAmount] = carBrand;
        realAmount += 1;
      }
    }
    assembly ('memory-safe') {
      mstore(brandsArray, realAmount)
    }
    return brandsArray;
  }

  function getUniqModelsByBrand(
    string memory brand
  ) internal view returns (string[] memory modelsArray) {
    uint totalSupply = CarTokenStorage.totalSupply();
    uint realAmount = 0;
    bytes32 hashedBrand = keccak256(abi.encodePacked(brand));
    modelsArray = new string[](totalSupply);
    for (uint i = 1; i <= totalSupply; i++) {
      Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(i);
      if (keccak256(abi.encodePacked(car.brand)) == hashedBrand && car.currentlyListed)
        if (_isUniqInStringInArray(modelsArray, car.model, realAmount)) {
          modelsArray[realAmount] = car.model;
          realAmount += 1;
        }
    }
    assembly ('memory-safe') {
      mstore(modelsArray, realAmount)
    }
  }
  function _isUniqInStringInArray(
    string[] memory ar,
    string memory toCompare,
    uint arrayLen
  ) private pure returns (bool) {
    bytes32 hashedString = keccak256(abi.encodePacked(toCompare));
    for (uint i = 0; i < arrayLen; i++) {
      if (keccak256(abi.encodePacked(ar[i])) == hashedString) {
        return false;
      }
    }
    return true;
  }

  function checkCarAvailabilityWithDelivery(
    uint carId,
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) internal view returns (Schemas.AvailableCarDTO memory) {
    CarTokenStorage.CarTokenFaucetStorage storage carService = CarTokenStorage.accessStorage();
    Schemas.CarInfo memory temp = CarTokenStorage.getCarInfoById(carId);

    uint fuelPrice = carService.enginesService.getFuelPriceFromEngineParams(temp.engineType, temp.engineParams);

    uint64 totalTripDays = uint64(Math.ceilDiv(endDateTime - startDateTime, 1 days));
    totalTripDays = totalTripDays == 0 ? 1 : totalTripDays;

    Schemas.DeliveryPrices memory deliveryPrices = DeliveryStorage.getUserDeliveryPrices(
      temp.createdBy
    );
    Schemas.LocationInfo memory location = GeoServiceStorage.getLocationInfo(
      temp.locationHash
    );
      int128 distance = DeliveryStorage.calculateDistance(
      location.latitude,
      location.longitude,
      pickUpInfo.latitude,
      pickUpInfo.longitude
    );
    uint64 priceWithDiscount = PaymentsStorage.calculateSumWithDiscount(
      CarTokenStorage.ownerOf(carId),
      totalTripDays,
      temp.pricePerDayInUsdCents
    );
    uint64 pickUp = 0;
    uint64 dropOf = 0;
    bytes32 locationHash = temp.locationHash;
    if (bytes(pickUpInfo.latitude).length != 0 || bytes(returnInfo.longitude).length != 0) {
      (pickUp, dropOf) = DeliveryStorage.calculatePricesByDeliveryDataInUsdCents(
        pickUpInfo,
        returnInfo,
        GeoServiceStorage.getCarLocationLatitude(
          locationHash
        ),
        GeoServiceStorage.getCarLocationLongitude(
          locationHash
        ),
        temp.createdBy
      );
    }

    uint taxId = TaxesStorage.defineTaxesType(carId);

    (uint64 totalTax, Schemas.TaxValue[] memory taxes) = taxId == 0
      ? (0,new Schemas.TaxValue[](0))
      : TaxesStorage.calculateTaxesDTO(taxId, totalTripDays, priceWithDiscount + pickUp + dropOf);
    address owner = CarTokenStorage.ownerOf(carId);
    return
      Schemas.AvailableCarDTO(
        carId,
        temp.brand,
        temp.model,
        temp.yearOfProduction,
        temp.pricePerDayInUsdCents,
        priceWithDiscount / totalTripDays,
        totalTripDays,
        priceWithDiscount,
        temp.securityDepositPerTripInUsdCents,
        temp.engineType,
        temp.milesIncludedPerDay,
        temp.createdBy,
        UserServiceStorage.getKYCInfo(temp.createdBy).name,
        UserServiceStorage.getKYCInfo(temp.createdBy).profilePhoto,
        CarTokenStorage.tokenUri(temp.carId),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        pickUp,
        dropOf,
        temp.insuranceIncluded,
        GeoServiceStorage.getLocationInfo(temp.locationHash),
        InsuranceServiceStorage.getCarInsuranceInfo(temp.carId),
        fuelPrice,
        PaymentsStorage.getBaseDiscount().getParsedDiscount(owner),
        distance,
        InsuranceServiceStorage.isGuestHasInsurance(user),
        DimoServiceStorage.getDimoTokenId(temp.carId),
        taxes,
        totalTax,
        CurrencyConverterStorage.getUserCurrency(owner)
      );
  }

}