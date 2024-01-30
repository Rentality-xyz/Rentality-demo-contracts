// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '../Schemas.sol';
import '../RentalityClaimService.sol';
import '../RentalityTripService.sol';
import '../IRentalityGeoService.sol';


library RentalityQuery {

    /// @dev Checks if a specific trip has intersecting trips within a given time range.
    //  @param TripService to getTrip by id
    /// @param tripId The ID of the trip to check.
    /// @param startDateTime The start date and time of the time range.
    /// @param endDateTime The end date and time of the time range.
    /// @return hasIntersectingTrips A boolean indicating whether the trip has intersecting trips within the specified time range.
    function isTripThatIntersect(
        address tripService,
        address carService,
        uint256 tripId,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal view returns (bool) {
        Schemas.Trip memory trip = RentalityTripService(tripService).getTrip(tripId);
        Schemas.CarInfo memory carInfo = RentalityCarToken(carService).getCarInfoById(trip.carId);
        return
            (trip.endDateTime + carInfo.timeBufferBetweenTripsInSec > startDateTime) && (trip.startDateTime < endDateTime);
    }

    /// @dev Retrieves an array of trips that intersect with a given time range.
    //  @param TripService to getTrip by id
    /// @param startDateTime The start date and time of the time range.
    /// @param endDateTime The end date and time of the time range.
    /// @return intersectingTrips An array of trips that intersect with the specified time range.
    function getTripsThatIntersect(
        address tripServiceAddress,
        address carServiceAddress,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (Schemas.Trip[] memory) {
        uint itemCount = 0;
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (isTripThatIntersect(tripServiceAddress, carServiceAddress, currentId, startDateTime, endDateTime)) {
                itemCount += 1;
            }
        }

        Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (isTripThatIntersect(tripServiceAddress, carServiceAddress, currentId, startDateTime, endDateTime)) {
                result[currentIndex] = tripService.getTrip(currentId);
                currentIndex += 1;
            }
        }

        return result;
    }

    //  @dev Checks if a specific car has intersecting trip within a given time range.
    //  @param TripService to getTrip by id
    //  @param tripId The ID of the trip to check.
    //  @param startDateTime The start date and time of the time range.
    //  @param endDateTime The end date and time of the time range.
    //  @return hasIntersectingTrips A boolean indicating whether the car has intersecting trips within the specified time range.
    function isCarThatIntersect(
        address tripService,
        uint256 tripId,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) private view returns (bool) {
        Schemas.Trip memory trip = RentalityTripService(tripService).getTrip(tripId);
        return (trip.carId == carId) && (trip.endDateTime > startDateTime) && (trip.startDateTime < endDateTime);
    }

    ///  @dev Checks if a specific car ID has intersecting trips within a given time range.
    //  @param TripService to getTrip by id
    ///  @param carId The ID of the car to check.
    ///  @param startDateTime The start date and time of the time range.
    ///  @param endDateTime The end date and time of the time range.
    ///  @return trips An array of intersecting trips for the specified car within the specified time range.
    function getTripsForCarThatIntersect(
        address tripServiceAddress,
        address carServiceAddress,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (Schemas.Trip[] memory) {
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
        RentalityCarToken carService = RentalityCarToken(carServiceAddress);
        uint itemCount = 0;

        uint32 timeBuffer = carService.getCarInfoById(carId).timeBufferBetweenTripsInSec;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (isCarThatIntersect(tripServiceAddress, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
                itemCount += 1;
            }
        }

        Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (isCarThatIntersect(tripServiceAddress, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
                result[currentIndex] = tripService.getTrip(currentId);
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific guest address.
    /// @param guest The address of the guest.
    /// @return trips An array of trips associated with the specified guest.
    function getTripsByGuest(
        address tripServiceAddress,
        address guest
    ) public view returns (Schemas.Trip[] memory) {
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
        uint itemCount = 0;

        for (uint i = 1; i <= tripService.totalTripCount(); i++) {
            if (tripService.getTrip(i).guest == guest) {
                itemCount += 1;
            }
        }

        Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 1; i <= tripService.totalTripCount(); i++) {
            if (tripService.getTrip(i).guest == guest) {
                Schemas.Trip memory currentItem = tripService.getTrip(i);
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific host address.
    /// @param host The address of the host.
    /// @return trips An array of trips associated with the specified host.
    function getTripsByHost(address tripServiceAddress, address host) public view returns (Schemas.Trip[] memory) {
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
        uint itemCount = 0;

        for (uint i = 1; i <= tripService.totalTripCount(); i++) {
            if (tripService.getTrip(i).host == host) {
                itemCount += 1;
            }
        }

        Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 1; i <= tripService.totalTripCount(); i++) {
            if (tripService.getTrip(i).host == host) {
                Schemas.Trip memory currentItem = tripService.getTrip(i);
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific car ID.
    /// @param carId The ID of the car.
    /// @return trips An array of trips associated with the specified car ID.
    function getTripsByCar(address tripServiceAddress, uint256 carId) public view returns (Schemas.Trip[] memory) {
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
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

    /// @notice Gets an array of claims associated with a specific trip.
    /// @dev Returns an array of detailed claim information for the given trip.
    /// @param tripId ID of the trip.
    /// @return Array of detailed claim information.
    function getClaimsByTrip(
        address claimServiceAddress,
        address tripServiceAddress,
        address carServiceAddress,
        address userServiceAddress,
        uint256 tripId
    ) public view returns (Schemas.FullClaimInfo[] memory) {
        RentalityClaimService claimService = RentalityClaimService(claimServiceAddress);
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
        RentalityCarToken carService = RentalityCarToken(carServiceAddress);
        RentalityUserService userService = RentalityUserService(userServiceAddress);

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

                claimInfos[counter++] = Schemas.FullClaimInfo(
                    claim,
                    trip.host,
                    trip.guest,
                    guestPhoneNumber,
                    hostPhoneNumber,
                    carInfo
                );
            }
        }

        return claimInfos;
    }

    /// @notice Retrieves all claims by host.
    /// @return An array of FullClaimInfo containing information about each claim.
    function getClaimsByHost(
        address claimServiceAddress,
        address tripServiceAddress,
        address carServiceAddress,
        address userServiceAddress,
        address host
    ) public view returns (Schemas.FullClaimInfo[] memory) {
        RentalityClaimService claimService = RentalityClaimService(claimServiceAddress);
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
        RentalityCarToken carService = RentalityCarToken(carServiceAddress);
        RentalityUserService userService = RentalityUserService(userServiceAddress);

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

                claimInfos[counter++] = Schemas.FullClaimInfo(
                    claim,
                    host,
                    trip.guest,
                    userService.getKYCInfo(trip.guest).mobilePhoneNumber,
                    userService.getKYCInfo(host).mobilePhoneNumber,
                    carService.getCarInfoById(trip.carId)
                );
            }
        }

        return claimInfos;
    }

    ///  @notice Retrieves all claims by guest.
    ///  @return An array of FullClaimInfo containing information about each claim.
    function getClaimsByGuest(
        address claimServiceAddress,
        address tripServiceAddress,
        address carServiceAddress,
        address userServiceAddress,
        address guest
    ) public view returns (Schemas.FullClaimInfo[] memory) {
        RentalityClaimService claimService = RentalityClaimService(claimServiceAddress);
        RentalityTripService tripService = RentalityTripService(tripServiceAddress);
        RentalityCarToken carService = RentalityCarToken(carServiceAddress);
        RentalityUserService userService = RentalityUserService(userServiceAddress);

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

                claimInfos[counter++] = Schemas.FullClaimInfo(
                    claim,
                    trip.host,
                    guest,
                    userService.getKYCInfo(guest).mobilePhoneNumber,
                    userService.getKYCInfo(trip.host).mobilePhoneNumber,
                    carService.getCarInfoById(trip.carId)
                );
            }
        }

        return claimInfos;
    }

    /// @notice Checks if a car is available for a specific user based on search parameters.
    /// @dev Determines availability based on several conditions, including ownership and search parameters.
    /// @param carId The ID of the car being checked.
    /// @param searchCarParams The parameters used to filter available cars.
    /// @return A boolean indicating whether the car is available for the user.
    function isCarAvailableForUser(
        uint256 carId,
        Schemas.SearchCarParams memory searchCarParams,
        address carServiceAddress,
        address geoServiceAddress
    ) public view returns (bool) {
        RentalityCarToken carService = RentalityCarToken(carServiceAddress);
        IRentalityGeoService geoService = IRentalityGeoService(geoServiceAddress);

        Schemas.CarInfo memory car = carService.getCarInfoById(carId);
        return
            (bytes(searchCarParams.brand).length == 0 ||
                RentalityUtils.containWord(RentalityUtils.toLower(car.brand), RentalityUtils.toLower(searchCarParams.brand))) &&
            (bytes(searchCarParams.model).length == 0 ||
                RentalityUtils.containWord(RentalityUtils.toLower(car.model), RentalityUtils.toLower(searchCarParams.model))) &&
            (bytes(searchCarParams.country).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(geoService.getCarCountry(carId)),
                    RentalityUtils.toLower(searchCarParams.country)
                )) &&
            (bytes(searchCarParams.state).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(geoService.getCarState(carId)),
                    RentalityUtils.toLower(searchCarParams.state)
                )) &&
            (bytes(searchCarParams.city).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(geoService.getCarCity(carId)),
                    RentalityUtils.toLower(searchCarParams.city)
                )) &&
            (searchCarParams.yearOfProductionFrom == 0 || car.yearOfProduction >= searchCarParams.yearOfProductionFrom) &&
            (searchCarParams.yearOfProductionTo == 0 || car.yearOfProduction <= searchCarParams.yearOfProductionTo) &&
            (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
                car.pricePerDayInUsdCents >= searchCarParams.pricePerDayInUsdCentsFrom) &&
            (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
                car.pricePerDayInUsdCents <= searchCarParams.pricePerDayInUsdCentsTo);
    }

    /// @dev Searches for available cars for a user within a specified time range and search parameters.
    /// @param user The address of the user for whom to search available cars.
    /// @param startDateTime The start date and time of the search period.
    /// @param endDateTime The end date and time of the search period.
    /// @param searchParams The search parameters for filtering available cars.
    /// @return An array of available car information matching the search criteria.
    function searchAvailableCarsForUser(
        address user,
        uint64 startDateTime,
        uint64 endDateTime,
        Schemas.SearchCarParams memory searchParams,
        address carServiceAddress,
        address userServiceAddress,
        address tripServiceAddress
    ) public view returns (Schemas.AvailableCarResponse[] memory) {
// if (startDateTime < block.timestamp){
//     return new RentalityCarToken.CarInfo[](0);
// }
        RentalityCarToken carService = RentalityCarToken(carServiceAddress);
        RentalityUserService userService = RentalityUserService(userServiceAddress);
        Schemas.CarInfo[] memory availableCars = carService.fetchAvailableCarsForUser(user, searchParams);
        if (availableCars.length == 0) return new Schemas.AvailableCarResponse[](0);

        Schemas.Trip[] memory trips = getTripsThatIntersect(tripServiceAddress, carServiceAddress, startDateTime, endDateTime);
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
                        trips[j].status == Schemas.TripStatus.Canceled
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
        Schemas.AvailableCarResponse[] memory result = new Schemas.AvailableCarResponse[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            string memory hostPhotoUrl = userService.getKYCInfo(temp[i].createdBy).profilePhoto;
            string memory hostName = userService.getKYCInfo(temp[i].createdBy).name;
            result[i] = Schemas.AvailableCarResponse(temp[i], hostPhotoUrl, hostName);
        }
        return result;
    }

}