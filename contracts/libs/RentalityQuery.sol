pragma solidity ^0.8.0;

import '../RentalityCarToken.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import '../RentalityTripService.sol';
import '../RentalityUserService.sol';
import '../RentalityPlatform.sol';
import '../features/RentalityClaimService.sol';
import '../RentalityAdminGateway.sol';
import '../Schemas.sol';
import '../RentalityGateway.sol';
import '../Schemas.sol';
import '../Schemas.sol';
import '../Schemas.sol';

library RentalityQuery {
  function isTripThatIntersect(
    RentalityContract memory contracts,
    uint256 tripId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    Schemas.Trip memory trip = contracts.tripService.getTrip(tripId);
    Schemas.CarInfo memory carInfo = contracts.carService.getCarInfoById(trip.carId);
    return
      (trip.endDateTime + carInfo.timeBufferBetweenTripsInSec > startDateTime) && (trip.startDateTime < endDateTime);
  }

  function getTripsForCarThatIntersect(
    RentalityContract memory contracts,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) public view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    RentalityTripService tripService = contracts.tripService;

    uint32 timeBuffer = contracts.carService.getCarInfoById(carId).timeBufferBetweenTripsInSec;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isCarThatIntersect(contracts, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isCarThatIntersect(contracts, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        result[currentIndex] = tripService.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }

  function isCarThatIntersect(
    RentalityContract memory contracts,
    uint256 tripId,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    Schemas.Trip memory trip = contracts.tripService.getTrip(tripId);
    return (trip.carId == carId) && (trip.endDateTime > startDateTime) && (trip.startDateTime < endDateTime);
  }

  /// @dev Retrieves an array of trips associated with a specific car ID.
  /// @param carId The ID of the car.
  /// @return trips An array of trips associated with the specified car ID.
  function getTripsByCar(
    RentalityContract memory contracts,
    uint256 carId
  ) public view returns (Schemas.Trip[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).carId == carId) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).carId == carId) {
        Schemas.Trip memory currentItem = tripService.getTrip(i);
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }

  function getTripsByGuest(
    RentalityContract memory contracts,
    address guest
  ) public view returns (Schemas.TripDTO[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).guest == guest) {
        itemCount += 1;
      }
    }

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).guest == guest) {
        result[currentIndex] = getTripDTO(contracts, i);

        currentIndex += 1;
      }
    }

    return result;
  }

  function getTripsByHost(
    RentalityContract memory contracts,
    address host
  ) public view returns (Schemas.TripDTO[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).host == host) {
        itemCount += 1;
      }
    }

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).host == host) {
        result[currentIndex] = getTripDTO(contracts, i);
        currentIndex += 1;
      }
    }

    return result;
  }

  function getClaimsByTrip(
    RentalityContract memory contracts,
    uint256 tripId
  ) public view returns (Schemas.FullClaimInfo[] memory) {
    RentalityClaimService claimService = contracts.claimService;
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    uint256 arraySize = 0;
    for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
      Schemas.Claim memory claim = claimService.getClaim(i);
      if (claim.tripId == tripId) {
        arraySize += 1;
      }
    }
    uint256 counter = 0;

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);

    for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
      Schemas.Claim memory claim = claimService.getClaim(i);

      if (claim.tripId == tripId) {
        Schemas.Trip memory trip = tripService.getTrip(tripId);
        Schemas.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        string memory guestPhoneNumber = userService.getKYCInfo(trip.guest).mobilePhoneNumber;
        string memory hostPhoneNumber = userService.getKYCInfo(trip.host).mobilePhoneNumber;

        uint valueInEth = currencyConverterService.getFromUsd(
          trip.paymentInfo.currencyType,
          claim.amountInUsdCents,
          trip.paymentInfo.currencyRate,
          trip.paymentInfo.currencyDecimals
        );

        claimInfos[counter++] = Schemas.FullClaimInfo(
          claim,
          trip.host,
          trip.guest,
          guestPhoneNumber,
          hostPhoneNumber,
          carInfo,
          valueInEth
        );
      }
    }

    return claimInfos;
  }

  function getClaimsByHost(
    RentalityContract memory contracts,
    address host
  ) public view returns (Schemas.FullClaimInfo[] memory) {
    RentalityClaimService claimService = contracts.claimService;
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    uint256 arraySize = 0;

    for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
      Schemas.Claim memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

      if (trip.host == host) {
        arraySize++;
      }
    }

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
    uint256 counter = 0;

    for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
      Schemas.Claim memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

      if (trip.host == host) {
        uint valueInEth = currencyConverterService.getFromUsd(
          trip.paymentInfo.currencyType,
          claim.amountInUsdCents,
          trip.paymentInfo.currencyRate,
          trip.paymentInfo.currencyDecimals
        );
        claimInfos[counter++] = Schemas.FullClaimInfo(
          claim,
          host,
          trip.guest,
          userService.getKYCInfo(trip.guest).mobilePhoneNumber,
          userService.getKYCInfo(host).mobilePhoneNumber,
          carService.getCarInfoById(trip.carId),
          valueInEth
        );
      }
    }

    return claimInfos;
  }

  function getClaimsByGuest(
    RentalityContract memory contracts,
    address guest
  ) public view returns (Schemas.FullClaimInfo[] memory) {
    RentalityClaimService claimService = contracts.claimService;
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    uint256 arraySize = 0;

    for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
      Schemas.Claim memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

      if (trip.guest == guest) {
        arraySize++;
      }
    }

    Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
    uint256 counter = 0;

    for (uint256 i = 1; i <= claimService.getClaimsAmount(); i++) {
      Schemas.Claim memory claim = claimService.getClaim(i);
      Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

      if (trip.guest == guest) {
        uint valueInEth = currencyConverterService.getFromUsd(
          trip.paymentInfo.currencyType,
          claim.amountInUsdCents,
          trip.paymentInfo.currencyRate,
          trip.paymentInfo.currencyDecimals
        );
        claimInfos[counter++] = Schemas.FullClaimInfo(
          claim,
          trip.host,
          guest,
          userService.getKYCInfo(guest).mobilePhoneNumber,
          userService.getKYCInfo(trip.host).mobilePhoneNumber,
          carService.getCarInfoById(trip.carId),
          valueInEth
        );
      }
    }

    return claimInfos;
  }

  function searchAvailableCarsForUser(
    RentalityContract memory contracts,
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams
  ) public view returns (Schemas.SearchCar[] memory result) {
    // if (startDateTime < block.timestamp){
    //     return new RentalityCarToken.CarInfo[](0);
    // }
    RentalityCarToken carService = contracts.carService;
    Schemas.CarInfo[] memory availableCars = carService.fetchAvailableCarsForUser(user, searchParams);
    if (availableCars.length == 0) return new Schemas.SearchCar[](0);

    Schemas.Trip[] memory trips = getTripsThatIntersect(contracts, startDateTime, endDateTime);
    Schemas.CarInfo[] memory temp;
    uint256 resultCount;

    if (trips.length == 0) {
      temp = availableCars;
      resultCount = availableCars.length;
    } else {
      temp = new Schemas.CarInfo[](availableCars.length);
      resultCount = 0;

      for (uint i = 0; i < availableCars.length; i++) {
        bool hasIntersectTrip = false;

        for (uint j = 0; j < trips.length; j++) {
          if (
            trips[j].status == Schemas.TripStatus.Created ||
            trips[j].status == Schemas.TripStatus.Finished ||
            trips[j].status == Schemas.TripStatus.Canceled ||
            (trips[j].status == Schemas.TripStatus.CheckedOutByGuest && trips[j].host == trips[j].tripFinishedBy)
          ) {
            continue;
          }

          if (trips[j].carId == availableCars[i].carId) {
            hasIntersectTrip = true;
            break;
          }
        }

        if (!hasIntersectTrip) {
          temp[resultCount] = availableCars[i];
          resultCount++;
        }
      }
    }
    result = new Schemas.SearchCar[](resultCount);

    for (uint i = 0; i < resultCount; i++) {
      uint64 totalTripDays = uint64(Math.ceilDiv(endDateTime - startDateTime, 1 days));
      totalTripDays = totalTripDays == 0 ? 1 : totalTripDays;

      uint64 priceWithDiscount = contracts.paymentService.calculateSumWithDiscount(
        carService.ownerOf(temp[i].carId),
        totalTripDays,
        temp[i].pricePerDayInUsdCents
      );

      uint taxId = contracts.paymentService.defineTaxesType(address(contracts.carService), temp[i].carId);

      uint64 taxes = taxId == 0 ? 0 : contracts.paymentService.calculateTaxes(taxId, totalTripDays, priceWithDiscount);

      result[i] = Schemas.SearchCar(
        temp[i].carId,
        temp[i].brand,
        temp[i].model,
        temp[i].yearOfProduction,
        temp[i].pricePerDayInUsdCents,
        priceWithDiscount / totalTripDays,
        totalTripDays,
        priceWithDiscount,
        taxes,
        temp[i].securityDepositPerTripInUsdCents,
        temp[i].engineType,
        temp[i].milesIncludedPerDay,
        temp[i].createdBy,
        contracts.userService.getKYCInfo(temp[i].createdBy).name,
        contracts.userService.getKYCInfo(temp[i].createdBy).profilePhoto,
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarCity(temp[i].carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarCountry(temp[i].carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarState(temp[i].carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarLocationLatitude(temp[i].carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarLocationLongitude(temp[i].carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(temp[i].carId),
        carService.tokenURI(temp[i].carId)
      );
    }
    return result;
  }
  // Updated function getCarDetails with RentalityContract parameter
  function getCarDetails(
    RentalityContract memory contracts,
    uint carId
  ) public view returns (Schemas.CarDetails memory details) {
    RentalityCarToken carService = contracts.carService;
    IRentalityGeoService geo = IRentalityGeoService(carService.getGeoServiceAddress());
    RentalityUserService userService = contracts.userService;

    Schemas.CarInfo memory car = carService.getCarInfoById(carId);

    details = Schemas.CarDetails(
      carId,
      userService.getKYCInfo(car.createdBy).name,
      userService.getKYCInfo(car.createdBy).profilePhoto,
      car.createdBy,
      car.brand,
      car.model,
      car.yearOfProduction,
      car.pricePerDayInUsdCents,
      car.securityDepositPerTripInUsdCents,
      car.milesIncludedPerDay,
      car.engineType,
      car.engineParams,
      geo.getCarCoordinateValidity(carId),
      car.currentlyListed,
      geo.getCarTimeZoneId(carId),
      geo.getCarCity(carId),
      geo.getCarCountry(carId),
      geo.getCarState(carId),
      geo.getCarLocationLatitude(carId),
      geo.getCarLocationLongitude(carId)
    );
  }

  // Updated function getCarsOwnedByUserWithEditability with RentalityContract parameter
  function getCarsOwnedByUserWithEditability(
    RentalityContract memory contracts
  ) public view returns (Schemas.CarInfoDTO[] memory) {
    RentalityCarToken carService = contracts.carService;

    Schemas.CarInfo[] memory carInfoes = carService.getCarsOwnedByUser(tx.origin);

    Schemas.CarInfoDTO[] memory result = new Schemas.CarInfoDTO[](carInfoes.length);
    for (uint i = 0; i < carInfoes.length; i++) {
      result[i].carInfo = carInfoes[i];
      result[i].metadataURI = carService.tokenURI(carInfoes[i].carId);
      result[i].isEditable = isCarEditable(contracts, carInfoes[i].carId);
    }

    return result;
  }

  // Updated function isCarEditable with RentalityContract parameter
  function isCarEditable(RentalityContract memory contracts, uint carId) public view returns (bool) {
    RentalityTripService tripService = contracts.tripService;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      Schemas.Trip memory tripInfo = tripService.getTrip(i);

      if (
        tripInfo.carId == carId &&
        (tripInfo.status != Schemas.TripStatus.Finished && tripInfo.status != Schemas.TripStatus.Canceled)
      ) {
        return false;
      }
    }

    return true;
  }

  // Updated function getTripDTO with RentalityContract parameter
  function getTripDTO(RentalityContract memory contracts, uint tripId) public view returns (Schemas.TripDTO memory) {
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

    return
      Schemas.TripDTO(
        trip,
        userService.getKYCInfo(trip.guest).profilePhoto,
        userService.getKYCInfo(trip.host).profilePhoto,
        carService.tokenURI(trip.carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(trip.carId),
        userService.getKYCInfo(trip.host).licenseNumber,
        userService.getKYCInfo(trip.host).expirationDate,
        userService.getKYCInfo(trip.guest).licenseNumber,
        userService.getKYCInfo(trip.guest).expirationDate,
        car.model,
        car.brand,
        car.yearOfProduction
      );
  }

  // Refactoring for getClaim with RentalityContract
  function getClaim(
    RentalityContract memory contracts,
    uint256 claimId
  ) public view returns (Schemas.FullClaimInfo memory) {
    RentalityClaimService claimService = contracts.claimService;
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    Schemas.Claim memory claim = claimService.getClaim(claimId);
    Schemas.Trip memory trip = tripService.getTrip(claim.tripId);
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

    string memory guestPhoneNumber = userService.getKYCInfo(trip.guest).mobilePhoneNumber;
    string memory hostPhoneNumber = userService.getKYCInfo(trip.host).mobilePhoneNumber;

    uint valueInCurrency = currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      claim.amountInUsdCents,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );

    return Schemas.FullClaimInfo(claim, trip.host, trip.guest, guestPhoneNumber, hostPhoneNumber, car, valueInCurrency);
  }

  function getTripsThatIntersect(
    RentalityContract memory contracts,
    uint64 startDateTime,
    uint64 endDateTime
  ) public view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    RentalityTripService tripService = contracts.tripService;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isTripThatIntersect(contracts, currentId, startDateTime, endDateTime)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isTripThatIntersect(contracts, currentId, startDateTime, endDateTime)) {
        result[currentIndex] = tripService.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }

  //// Refactoring for getTripContactInfo with RentalityContract
  //    function getTripContactInfo(RentalityContract memory contracts, uint256 tripId)
  //    public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
  //    {
  //        RentalityTripService tripService = contracts.tripService;
  //        RentalityUserService userService = contracts.userService;
  //
  //        require(userService.isHostOrGuest(tx.origin), "User is not a host or guest");
  //
  //        Schemas.Trip memory trip = tripService.getTrip(tripId);
  //
  //        Schemas.KYCInfo memory guestInfo = userService.getKYCInfo(trip.guest);
  //        Schemas.KYCInfo memory hostInfo = userService.getKYCInfo(trip.host);
  //
  //        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
  //    }
}
