/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '../RentalityCarToken.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import '../RentalityTripService.sol';
import '../RentalityUserService.sol';
import '../RentalityPlatform.sol';
import '../features/RentalityClaimService.sol';
import '../RentalityAdminGateway.sol';
import {IRentalityGeoService} from '../abstract/IRentalityGeoService.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
import '../Schemas.sol';
import './RentalityUtils.sol';
import './RentalityQuery.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
import '../engine/RentalityEnginesService.sol';
import '../payments/RentalityBaseDiscount.sol';
import '../investment/RentalityInvestment.sol';
import {RentalityCarInvestmentPool} from '../investment/RentalityInvestmentPool.sol';

library RentalityViewLib {
  // @notice Retrieves all trips based on the provided filter and pagination.
  /// @param filter The filter to apply to the trips.
  /// @param page The current page number.
  /// @param itemsPerPage The number of items per page.
  /// @return A structure containing the filtered trips and total page count.
  function getAllTrips(
    RentalityContract memory contracts,
    Schemas.TripFilter memory filter,
    RentalityPromoService promoService,
    uint page,
    uint itemsPerPage
  ) public view returns (Schemas.AllTripsDTO memory) {
    uint totalTripsCount = contracts.tripService.totalTripCount();

    uint[] memory matchedTrips = new uint[](totalTripsCount);

    uint counter = 0;
    for (uint i = 1; i <= totalTripsCount; i++) {
      if (isTripMatch(contracts, filter, contracts.tripService.getTrip(i))) {
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
      Schemas.Trip memory trip = contracts.tripService.getTrip(matchedTrips[i]);
      Schemas.CarInfo memory car = contracts.carService.getCarInfoById(trip.carId);
      result[i - startIndex] = Schemas.AdminTripDTO(
        trip,
        contracts.carService.tokenURI(trip.carId),
        IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getLocationInfo(car.locationHash),
        promoService.getPromoTripInfo(trip.tripId, trip.guest)
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
    RentalityContract memory contracts,
    Schemas.TripFilter memory filter,
    Schemas.Trip memory trip
  ) internal view returns (bool) {
    IRentalityGeoService geoService = IRentalityGeoService(contracts.carService.getGeoServiceAddress());
    Schemas.LocationInfo memory locationInfo = geoService.getLocationInfo(
      contracts.carService.getCarInfoById(trip.carId).locationHash
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
          contracts.tripService.completedByAdmin(trip.tripId))));
  }

  function getFilterInfo(
    RentalityContract memory contracts,
    uint64 duration
  ) public view returns (Schemas.FilterInfoDTO memory) {
    uint64 maxCarPrice = 0;
    RentalityCarToken carService = contracts.carService;
    uint minCarYearOfProduction = carService.getCarInfoById(1).yearOfProduction;

    for (uint i = 2; i <= carService.totalSupply(); i++) {
      Schemas.CarInfo memory car = carService.getCarInfoById(i);

      uint64 sumWithDiscount = contracts.paymentService.calculateSumWithDiscount(
        carService.ownerOf(i),
        duration,
        car.pricePerDayInUsdCents
      );
      if (sumWithDiscount > maxCarPrice) maxCarPrice = sumWithDiscount;
      if (car.yearOfProduction < minCarYearOfProduction) minCarYearOfProduction = car.yearOfProduction;
    }
    return Schemas.FilterInfoDTO(maxCarPrice, minCarYearOfProduction);
  }
  function calculateClaimValue(RentalityContract memory addresses, uint claimId) public view returns (uint) {
    Schemas.ClaimV2 memory claim = addresses.claimService.getClaim(claimId);
    if (claim.status == Schemas.ClaimStatus.Paid || claim.status == Schemas.ClaimStatus.Cancel) return 0;

    uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);
    (uint result, , ) = addresses.currencyConverterService.getFromUsdCentsLatest(
      addresses.tripService.getTrip(claim.tripId).paymentInfo.currencyType,
      claim.amountInUsdCents + commission
    );

    return result;
  }

  function validatePayClaim(Schemas.Trip memory trip, Schemas.Claim memory claim, address user) public pure {
    require((claim.isHostClaims && user == trip.guest) || user == trip.host, 'Guest or host.');
    require(claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel, 'Wrong Status.');
  }


  function calculatePercentage(
    uint invested,
    uint totalPrice,
    RentalityCurrencyConverter converter
  ) public view returns (uint, uint) {
    uint percentages = invested == 0 ? 0 : Math.ceilDiv(invested * 100, totalPrice);
    (uint investInUsd, , ) = converter.getToUsdLatest(address(0), invested);
    return (percentages, investInUsd);
  }

  function getAllMyTokensWithTotalPrice(
    address user,
    RentalityInvestmentNft nftContract
  ) public view returns (uint[] memory, uint, uint, uint) {
    uint[] memory result = new uint[](nftContract.balanceOf(user));
    uint counter = 0;
    uint totalPrice = 0;
    (uint totalSupply, uint totalHolders) = nftContract.totalSupplyWithTotalHolders();
    for (uint i = 1; i <= totalSupply; i++)
      if (nftContract.ownerOf(i) == user) {
        result[counter] = i;
        counter += 1;
        totalPrice += nftContract.tokenIdToPriceInEth(i);
      }
    return (result, totalPrice, totalHolders, totalSupply);
  }

  function getUniqCarsBrand(RentalityCarToken carService) public view returns (string[] memory) {
    uint totalSupply = carService.totalSupply();
    uint realAmount = 0;
    string[] memory brandsArray = new string[](totalSupply);
    for (uint i = 1; i <= totalSupply; i++) {
      Schemas.CarInfo memory car = carService.getCarInfoById(i);
      string memory carBrand =  RentalityUtils.toLower(car.brand);

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
    RentalityCarToken carService,
    string memory brand
  ) public view returns (string[] memory modelsArray) {
    uint totalSupply = carService.totalSupply();
    uint realAmount = 0;
    bytes32 hashedBrand = keccak256(abi.encodePacked(RentalityUtils.toLower(brand)));
    modelsArray = new string[](totalSupply);
    for (uint i = 1; i <= totalSupply; i++) {
      Schemas.CarInfo memory car = carService.getCarInfoById(i);
      string memory carModel = RentalityUtils.toLower(car.model);
      if (keccak256(abi.encodePacked(RentalityUtils.toLower(car.brand))) == hashedBrand && car.currentlyListed)
        if (_isUniqInStringInArray(modelsArray, carModel, realAmount)) {
          modelsArray[realAmount] = carModel;
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
    RentalityContract memory contracts,
    uint carId,
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    address deliveryServiceAddress,
    address insuranceServiceAddress,
    address dimoService
  ) public view returns (Schemas.AvailableCarDTO memory) {
    Schemas.CarInfo memory temp = contracts.carService.getCarInfoById(carId);
    RentalityCarToken carService = contracts.carService;

    uint fuelPrice = contracts.carService.getEngineService().getFuelPriceFromEngineParams(temp.engineType, temp.engineParams);

    uint64 totalTripDays = uint64(Math.ceilDiv(endDateTime - startDateTime, 1 days));
    totalTripDays = totalTripDays == 0 ? 1 : totalTripDays;

    Schemas.DeliveryPrices memory deliveryPrices = RentalityCarDelivery(deliveryServiceAddress).getUserDeliveryPrices(
      temp.createdBy
    );
    Schemas.LocationInfo memory location = IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo(
      temp.locationHash
    );
    int128 distance = RentalityCarDelivery(deliveryServiceAddress).calculateDistance(
      location.latitude,
      location.longitude,
      pickUpInfo.latitude,
      pickUpInfo.longitude
    );
    uint64 priceWithDiscount = contracts.paymentService.calculateSumWithDiscount(
      carService.ownerOf(carId),
      totalTripDays,
      temp.pricePerDayInUsdCents
    );
    uint64 pickUp = 0;
    uint64 dropOf = 0;
    if (bytes(pickUpInfo.latitude).length != 0 || bytes(returnInfo.longitude).length != 0) {
      (pickUp, dropOf) = RentalityCarDelivery(deliveryServiceAddress).calculatePricesByDeliveryDataInUsdCents(
        pickUpInfo,
        returnInfo,
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarLocationLatitude(
          carService.getCarInfoById(temp.carId).locationHash
        ),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarLocationLongitude(
          carService.getCarInfoById(temp.carId).locationHash
        ),
        temp.createdBy
      );
    }

    uint taxId = contracts.paymentService.defineTaxesType(address(contracts.carService), carId);

    (uint64 totalTax, Schemas.TaxValue[] memory taxes) = taxId == 0
      ? (0,new Schemas.TaxValue[](0))
      : contracts.paymentService.calculateTaxesDTO(taxId, totalTripDays, priceWithDiscount + pickUp + dropOf);

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
        contracts.userService.getKYCInfo(temp.createdBy).name,
        contracts.userService.getKYCInfo(temp.createdBy).profilePhoto,
        carService.tokenURI(temp.carId),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        pickUp,
        dropOf,
        temp.insuranceIncluded,
        IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo(temp.locationHash),
        RentalityInsurance(insuranceServiceAddress).getCarInsuranceInfo(temp.carId),
        fuelPrice,
        contracts.paymentService.getBaseDiscount().getParsedDiscount(contracts.carService.ownerOf(carId)),
        distance,
        RentalityInsurance(insuranceServiceAddress).isGuestHasInsurance(user),
        RentalityDimoService(dimoService).getDimoTokenId(temp.carId),
        taxes,
        totalTax,
        contracts.currencyConverterService.getUserCurrency(contracts.carService.ownerOf(carId))
      );
  }
}
