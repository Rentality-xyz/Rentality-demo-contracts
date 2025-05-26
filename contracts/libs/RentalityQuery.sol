/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import '../RentalityTripService.sol';
import '../RentalityUserService.sol';
import '../RentalityPlatform.sol';
import '../features/RentalityClaimService.sol';
import '../RentalityAdminGateway.sol';
import '../RentalityGateway.sol';
import '../engine/RentalityEnginesService.sol';
import '../payments/RentalityBaseDiscount.sol';
import {IRentalityGeoService} from '../abstract/IRentalityGeoService.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
import '../Schemas.sol';
import {RentalityTripsQuery} from './RentalityTripsQuery.sol';
import {CurrencyRate as ClaimCurrencyRate} from '../features/RentalityClaimService.sol';
import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
import {RentalityReferralProgram} from '../features/refferalProgram/RentalityReferralProgram.sol';
import {RentalityDimoService} from '../features/RentalityDimoService.sol';
library RentalityQuery {
  // /// @notice Retrieves all claims associated with a specific trip.
  // /// @dev This function fetches detailed claim information for a given trip ID.
  // /// @param contracts The Rentality contract instance containing service addresses.
  // /// @param tripId The ID of the trip for which to retrieve claims.
  // /// @return An array of FullClaimInfo structures containing detailed information about each claim.
  // function getClaimsByTrip(
  //   RentalityContract memory contracts,
  //   uint256 tripId
  // ) public view returns (Schemas.FullClaimInfo[] memory) {
  //   RentalityClaimService claimService = contracts.claimService;
  //   RentalityTripService tripService = contracts.tripService;
  //   RentalityCarToken carService = contracts.carService;
  //   RentalityUserService userService = contracts.userService;
  //   RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

  //   uint256 arraySize = 0;
  //   for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
  //     Schemas.Claim memory claim = claimService.getClaim(i);
  //     if (claim.tripId == tripId) {
  //       arraySize += 1;
  //     }
  //   }
  //   uint256 counter = 0;

  //   Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);

  //   for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
  //     Schemas.Claim memory claim = claimService.getClaim(i);

  //     if (claim.tripId == tripId) {
  //       Schemas.Trip memory trip = tripService.getTrip(tripId);
  //       Schemas.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
  //       string memory guestPhoneNumber = userService.getKYCInfo(trip.guest).mobilePhoneNumber;
  //       string memory hostPhoneNumber = userService.getKYCInfo(trip.host).mobilePhoneNumber;

  //       uint valueInEth = _getClaimValueInCurrency(
  //         trip.paymentInfo.currencyType,
  //         claim.amountInUsdCents,
  //         claim,
  //         claimService,
  //         currencyConverterService
  //       );

  //       claimInfos[counter++] = Schemas.FullClaimInfo(
  //         claim,
  //         trip.host,
  //         trip.guest,
  //         guestPhoneNumber,
  //         hostPhoneNumber,
  //         carInfo,
  //         valueInEth,
  //         IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getCarTimeZoneId(
  //           carService.getCarInfoById(trip.carId).locationHash
  //         )
  //       );
  //     }
  //   }

  //   return claimInfos;
  // }

  function getClaimsBy(
    RentalityContract memory contracts,
    bool host,
    address user
  ) public view returns (Schemas.FullClaimInfo[] memory) {
    return host ? getClaimsByHost(contracts, user) : getClaimsByGuest(contracts, user);
  }

  /// @notice Retrieves all claims associated with a specific host.
  /// @dev This function fetches detailed claim information for a given host address.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param host The address of the host for which to retrieve claims.
  /// @return An array of FullClaimInfo structures containing detailed information about each claim.
  function getClaimsByHost(
    RentalityContract memory contracts,
    address host
  ) private view returns (Schemas.FullClaimInfo[] memory) {
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    uint256 arraySize = 0;

    for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
      Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);
      Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);

      if (trip.host == host) {
        arraySize++;
      }
    }

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
    uint256 counter = 0;

    for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
      Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);
      Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);

      if (trip.host == host) {
        uint valueInEth = _getClaimValueInCurrency(
          trip.paymentInfo.currencyType,
          claim.amountInUsdCents,
          claim,
          contracts.claimService,
          currencyConverterService
        );
        claimInfos[counter++] = Schemas.FullClaimInfo(
          claim,
          host,
          trip.guest,
          userService.getKYCInfo(trip.guest).mobilePhoneNumber,
          userService.getKYCInfo(host).mobilePhoneNumber,
          contracts.carService.getCarInfoById(trip.carId),
          valueInEth,
          IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getCarTimeZoneId(
            contracts.carService.getCarInfoById(trip.carId).locationHash
          ),
          contracts.claimService.getClaimTypeInfo(claim.claimType),
          contracts.currencyConverterService.getUserCurrency(trip.host)
        );
      }
    }

    return claimInfos;
  }

  /// @notice Retrieves all claims associated with a specific guest.
  /// @dev This function fetches detailed claim information for a given guest address.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param guest The address of the guest for which to retrieve claims.
  /// @return An array of FullClaimInfo structures containing detailed information about each claim.
  function getClaimsByGuest(
    RentalityContract memory contracts,
    address guest
  ) private view returns (Schemas.FullClaimInfo[] memory) {
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    uint256 arraySize = 0;

    for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
      Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);

      if (contracts.tripService.getTrip(claim.tripId).guest == guest) {
        arraySize++;
      }
    }

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
    uint256 counter = 0;
    for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
      Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);
      Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);
      if (trip.guest == guest) {

        claimInfos[counter++] = Schemas.FullClaimInfo(
          claim,
          trip.host,
          guest,
          userService.getKYCInfo(guest).mobilePhoneNumber,
          userService.getKYCInfo(trip.host).mobilePhoneNumber,
          carService.getCarInfoById(trip.carId),
          _getClaimValueInCurrency(
          trip.paymentInfo.currencyType,
          claim.amountInUsdCents,
          claim,
          contracts.claimService,
          currencyConverterService
        ),
          IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getCarTimeZoneId(
            carService.getCarInfoById(trip.carId).locationHash
          ),
          contracts.claimService.getClaimTypeInfo(claim.claimType),
          contracts.currencyConverterService.getUserCurrency(trip.host)
        );
      }
    }

    return claimInfos;
  }

  function _getClaimValueInCurrency(
    address currency,
    uint amount,
    Schemas.ClaimV2 memory claim,
    RentalityClaimService claimService,
    RentalityCurrencyConverter currencyConverterService
  ) private view returns (uint) {
    uint valueInEth = 0;
    if (claim.status == Schemas.ClaimStatus.Paid) {
      (int rate,) = claimService.claimIdToCurrencyRate(claim.claimId);
      if (rate > 0) valueInEth = currencyConverterService.getFromUsdCents(currency, amount, rate);
    } else (valueInEth, , ) = currencyConverterService.getFromUsdCentsLatest(currency, amount);
    return valueInEth;
  }

  /// @notice Searches for available cars for a user based on specified search parameters.
  /// @dev This function checks for car availability, trip intersection, and delivery options.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param user The address of the user searching for cars.
  /// @param startDateTime The start time for the search period.
  /// @param endDateTime The end time for the search period.
  /// @param searchParams The parameters to filter the search (e.g., car type, price).
  /// @param pickUpInfo The location info for car pick-up.
  /// @param returnInfo The location info for car return.
  /// @param deliveryServiceAddress The address of the delivery service contract.
  /// @return result An array of SearchCar structures containing available cars that meet the criteria.
  function searchAvailableCarsForUser(
    RentalityContract memory contracts,
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    address deliveryServiceAddress,
    address insuranceServiceAddress,
    address dimoService,
    uint from,
    uint to
  ) public view returns (Schemas.SearchCar[] memory result, uint totalCars) {
    RentalityInsurance insuranceService = RentalityInsurance(insuranceServiceAddress);
    RentalityCarToken carService = contracts.carService;
    Schemas.CarInfo[] memory availableCars = carService.fetchAvailableCarsForUser(user, searchParams, from, to);
    if (availableCars.length == 0) return (new Schemas.SearchCar[](0), 0);

    uint[] memory temp = new uint[](availableCars.length);
    uint256 resultCount = 0;
   
   for (uint i = 0; i < availableCars.length; i++) {
   bool hasIntersectTrip = RentalityTripsQuery.isCarHasIntersectetTrips(
                contracts,
                startDateTime,
                endDateTime,
                availableCars[i].carId
              );
        if (!hasIntersectTrip) {
          temp[resultCount] = i;
          resultCount++;
        }
      }
      assembly ("memory-safe") {
        mstore(temp, resultCount)
      }


    result = new Schemas.SearchCar[](resultCount);
    bool isGuestHasInsurance = insuranceService.isGuestHasInsurance(user);
    uint64 totalTripDays = uint64(Math.ceilDiv(endDateTime - startDateTime, 1 days));
    totalTripDays = totalTripDays == 0 ? 1 : totalTripDays;
    for (uint i = 0; i < resultCount; i++) {

   

      Schemas.DeliveryPrices memory deliveryPrices = RentalityCarDelivery(deliveryServiceAddress).getUserDeliveryPrices(
        availableCars[temp[i]].createdBy
      );
      uint64 priceWithDiscount = contracts.paymentService.calculateSumWithDiscount(
        carService.ownerOf( availableCars[temp[i]].carId),
        totalTripDays,
         availableCars[temp[i]].pricePerDayInUsdCents
      );
      uint64 pickUp = 0;
      uint64 dropOf = 0;
      if (bytes(pickUpInfo.latitude).length != 0 || bytes(returnInfo.longitude).length != 0) {
        (pickUp, dropOf) = RentalityCarDelivery(deliveryServiceAddress).calculatePricesByDeliveryDataInUsdCents(
          pickUpInfo,
          returnInfo,
          IRentalityGeoService(carService.getGeoServiceAddress()).getCarLocationLatitude(
            carService.getCarInfoById( availableCars[temp[i]].carId).locationHash
          ),
          IRentalityGeoService(carService.getGeoServiceAddress()).getCarLocationLongitude(
            carService.getCarInfoById( availableCars[temp[i]].carId).locationHash
          ),
          availableCars[temp[i]].createdBy
        );
      }

      uint taxId = contracts.paymentService.defineTaxesType(address(contracts.carService),  availableCars[temp[i]].carId);

      uint64 totalTax = taxId == 0
        ? 0
        : contracts.paymentService.calculateTaxes(taxId, totalTripDays, priceWithDiscount + pickUp + dropOf);

      result[i] = Schemas.SearchCar(
         availableCars[temp[i]].carId,
         availableCars[temp[i]].brand,
         availableCars[temp[i]].model,
         availableCars[temp[i]].yearOfProduction,
         availableCars[temp[i]].pricePerDayInUsdCents,
        priceWithDiscount / totalTripDays,
        totalTripDays,
        priceWithDiscount,
        totalTax,
         availableCars[temp[i]].securityDepositPerTripInUsdCents,
         availableCars[temp[i]].engineType,
         availableCars[temp[i]].milesIncludedPerDay,
        availableCars[temp[i]].createdBy,
        contracts.userService.getKYCInfo( availableCars[temp[i]].createdBy).name,
        contracts.userService.getKYCInfo( availableCars[temp[i]].createdBy).profilePhoto,
        carService.tokenURI( availableCars[temp[i]].carId),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        pickUp,
        dropOf,
         availableCars[temp[i]].insuranceIncluded,
        IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo( availableCars[temp[i]].locationHash),
        insuranceService.getCarInsuranceInfo( availableCars[temp[i]].carId),
        isGuestHasInsurance,
        RentalityDimoService(dimoService).getDimoTokenId( availableCars[temp[i]].carId),
        contracts.currencyConverterService.getUserCurrency( availableCars[temp[i]].createdBy)
      );
    }
    return (result, carService.totalSupply());
  }

  /// @notice Searches for available cars and sorts them by distance from the user.
  /// @dev This function first searches for available cars and then sorts the results by distance.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param user The address of the user searching for cars.
  /// @param startDateTime The start time for the search period.
  /// @param endDateTime The end time for the search period.
  /// @param searchParams The parameters to filter the search (e.g., car type, price).
  /// @param pickUpInfo The location info for car pick-up.
  /// @param returnInfo The location info for car return.
  /// @param deliveryServiceAddress The address of the delivery service contract.
  /// @return An array of SearchCarWithDistance structures containing available cars sorted by distance.
  function searchSortedCars(
    RentalityContract memory contracts,
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    address deliveryServiceAddress,
    address insuranceAddress,
    address dimoService,
    uint from,
    uint to
  ) public view returns (Schemas.SearchCarsWithDistanceDTO memory) {
    (Schemas.SearchCar[] memory cars, uint totalCarsAmount) =
      searchAvailableCarsForUser(
        contracts,
        user,
        startDateTime,
        endDateTime,
        searchParams,
        pickUpInfo,
        returnInfo,
        deliveryServiceAddress,
        insuranceAddress,
        dimoService,
        from,
        to
      );
      Schemas.SearchCarWithDistance[] memory carsWithDistance = 
        RentalityCarDelivery(deliveryServiceAddress).sortCarsByDistance(cars, searchParams.userLocation);
    return
     Schemas.SearchCarsWithDistanceDTO(
        carsWithDistance,
        totalCarsAmount
      );
  }
}
