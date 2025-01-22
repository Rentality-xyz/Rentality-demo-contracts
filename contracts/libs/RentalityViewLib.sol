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
import {IRentalityGeoService} from '../abstract/IRentalityGeoService.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
import '../Schemas.sol';
import './RentalityUtils.sol';
import './RentalityQuery.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
import '../engine/RentalityEnginesService.sol';
import '../payments/RentalityBaseDiscount.sol';

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
        Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
        if (claim.status == Schemas.ClaimStatus.Paid || claim.status == Schemas.ClaimStatus.Cancel) return 0;

        uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);
        (uint result, , ) = addresses.currencyConverterService.getFromUsdLatest(
            addresses.tripService.getTrip(claim.tripId).paymentInfo.currencyType,
            claim.amountInUsdCents + commission
        );

        return result;
    }

    function validatePayClaim(Schemas.Trip memory trip, Schemas.Claim memory claim, address user) public view {
        require((claim.isHostClaims && user == trip.guest) || user == trip.host, 'Guest or host.');
        require(claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel, 'Wrong Status.');
    }
}