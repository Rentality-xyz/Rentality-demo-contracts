// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityPaymentService.sol";
import "./RentalityCarToken.sol";
import "./RentalityUtils.sol";
import "./RentalityUserService.sol";
//deployed 26.05.2023 11:15 to sepolia at 0x417886Ca72048E92E8Bf2082cf193ab8DB4ED09f
contract RentalityTripService {
    using Counters for Counters.Counter;
    Counters.Counter private _tripIdCounter;

    enum TripStatus {
        Created,
        Approved,
        CheckedInByHost,
        CheckedInByGuest,
        CheckedOutByGuest,
        CheckedOutByHost,
        Finished,
        Canceled
    }

    enum CurrencyType {
        ETH
    }

    struct PaymentInfo {
        uint256 tripId;
        address from;
        address to;
        uint64 totalDayPriceInUsdCents;
        uint64 taxPriceInUsdCents;
        uint64 depositInUsdCents;
        uint64 resolveAmountInUsdCents;
        CurrencyType currencyType;
        int256 ethToCurrencyRate;
        uint8 ethToCurrencyDecimals;
        uint64 resolveFuelAmountInUsdCents;
        uint64 resolveMilesAmountInUsdCents;
    }

    struct Trip {
        uint256 tripId;
        uint256 carId;
        TripStatus status;
        address guest;
        address host;
        string guestName;
        string hostName;
        uint64 pricePerDayInUsdCents;
        uint64 startDateTime;
        uint64 endDateTime;
        string startLocation;
        string endLocation;
        uint64 milesIncludedPerDay;
        uint64 fuelPricePerGalInUsdCents;
        PaymentInfo paymentInfo;
        uint approvedDateTime;
        uint rejectedDateTime;
        address rejectedBy;
        uint checkedInByHostDateTime;
        uint64 startFuelLevelInGal;
        uint64 startOdometr;
        uint checkedInByGuestDateTime;
        uint checkedOutByGuestDateTime;
        uint64 endFuelLevelInGal;
        uint64 endOdometr;
        uint checkedOutByHostDateTime;
    }

    struct AvailableCarResponse {
        RentalityCarToken.CarInfo car;
        string hostPhotoUrl;
        string hostName;
    }

    mapping(uint256 => Trip) private idToTripInfo;

    event TripCreated(uint256 tripId);
    event TripStatusChanged(uint256 tripId, TripStatus newStatus);

    RentalityCurrencyConverter private currencyConverterService;
    RentalityCarToken private carService;
    RentalityPaymentService private paymentService;
    RentalityUserService private userService;

    constructor(
        address currencyConverterServiceAddress,
        address carServiceAddress,
        address paymentServiceAddress,
        address userServiceAddress
    ) {
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
        paymentService = RentalityPaymentService(paymentServiceAddress);
        carService = RentalityCarToken(carServiceAddress);
        userService = RentalityUserService(userServiceAddress);
    }

    function totalTripCount() public view returns (uint) {
        return _tripIdCounter.current();
    }

    function createNewTrip(
        uint256 carId,
        address guest,
        address host,
        uint64 pricePerDayInUsdCents,
        uint64 startDateTime,
        uint64 endDateTime,
        string memory startLocation,
        string memory endLocation,
        uint64 milesIncludedPerDay,
        uint64 fuelPricePerGalInUsdCents,
        PaymentInfo memory paymentInfo
    ) public {
        _tripIdCounter.increment();
        uint256 newTripId = _tripIdCounter.current();
        if (milesIncludedPerDay == 0) {
            milesIncludedPerDay = 2 ** 32 - 1;
        }
        paymentInfo.tripId = newTripId;

        string memory guestName = userService.getKYCInfo(tx.origin).name;
        string memory hostName = userService.getKYCInfo(host).name;

        idToTripInfo[newTripId] = Trip(
            newTripId,
            carId,
            TripStatus.Created,
            guest,
            host,
            guestName,
            hostName,
            pricePerDayInUsdCents,
            startDateTime,
            endDateTime,
            startLocation,
            endLocation,
            milesIncludedPerDay,
            fuelPricePerGalInUsdCents,
            paymentInfo,
            0,
            0,
            address(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        emit TripCreated(newTripId);
    }

    function approveTrip(uint256 tripId) public {
        require(
            idToTripInfo[tripId].host == tx.origin,
            "Only host of the trip can approve it"
        );
        require(
            idToTripInfo[tripId].status == TripStatus.Created,
            "The trip is not in status Created"
        );

        idToTripInfo[tripId].status = TripStatus.Approved;
        idToTripInfo[tripId].approvedDateTime = block.timestamp;

        emit TripStatusChanged(tripId, TripStatus.Approved);
    }

    function rejectTrip(uint256 tripId) public {
        require(
            idToTripInfo[tripId].host == tx.origin ||
            idToTripInfo[tripId].guest == tx.origin,
            "Only host or guest of the trip can reject it"
        );
        require(
            idToTripInfo[tripId].status == TripStatus.Created ||
            idToTripInfo[tripId].status == TripStatus.Approved ||
            idToTripInfo[tripId].status == TripStatus.CheckedInByHost,
            "The trip is not in status Created, Approved or CheckedInByHost"
        );

        idToTripInfo[tripId].status = TripStatus.Canceled;
        idToTripInfo[tripId].rejectedDateTime = block.timestamp;
        idToTripInfo[tripId].rejectedBy = tx.origin;

        emit TripStatusChanged(tripId, TripStatus.Canceled);
    }

    function searchAvailableCarsForUser(
        address user,
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) public view returns (AvailableCarResponse[] memory) {
// if (startDateTime < block.timestamp){
//     return new RentalityCarToken.CarInfo[](0);
// }
        RentalityCarToken.CarInfo[] memory availableCars = carService.fetchAvailableCarsForUser(user, searchParams);
        if (availableCars.length == 0) return new AvailableCarResponse[](0);

        Trip[] memory trips = getTripsThatIntersect(startDateTime, endDateTime);
        RentalityCarToken.CarInfo[] memory temp;
        uint256 resultCount;

        if (trips.length == 0)
        {
            temp = availableCars;
            resultCount = availableCars.length;
        }
        else
        {
            temp = new RentalityCarToken.CarInfo[](availableCars.length);
            resultCount = 0;

            for (uint i = 0; i < availableCars.length; i++) {
                bool hasIntersectTrip = false;

                for (uint j = 0; j < trips.length; j++) {
                    if (
                        trips[j].status == TripStatus.Created ||
                        trips[j].status == TripStatus.Finished ||
                        trips[j].status == TripStatus.Canceled
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
        AvailableCarResponse[] memory result = new AvailableCarResponse[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            string memory hostPhotoUrl = userService.getKYCInfo(temp[i].createdBy).profilePhoto;
            string memory hostName = userService.getKYCInfo(temp[i].createdBy).name;
            result[i] = AvailableCarResponse(temp[i], hostPhotoUrl, hostName);
        }
        return result;
    }

    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        Trip memory trip = getTrip(tripId);
        require(trip.host == tx.origin, "For host only");

        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 startFuelLevelInGal = (carInfo.tankVolumeInGal *
            startFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.Approved,
            "The trip is not in status Approved"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedInByHost;
        idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
        idToTripInfo[tripId].startFuelLevelInGal = startFuelLevelInGal;
        idToTripInfo[tripId].startOdometr = startOdometr;

        emit TripStatusChanged(tripId, TripStatus.CheckedInByHost);
    }

    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        RentalityTripService.Trip memory trip = getTrip(tripId);
        require(trip.guest == tx.origin, "Only for guest");

        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 startFuelLevelInGal = (carInfo.tankVolumeInGal *
            startFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.CheckedInByHost,
            "The trip is not in status CheckedInByHost"
        );
        require(
            idToTripInfo[tripId].startFuelLevelInGal == startFuelLevelInGal,
            "Start fuel level does not match"
        );
        require(
            idToTripInfo[tripId].startOdometr == startOdometr,
            "Start odometr does not match"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedInByGuest;
        idToTripInfo[tripId].checkedInByGuestDateTime = block.timestamp;

        emit TripStatusChanged(tripId, TripStatus.CheckedInByGuest);
    }

    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        RentalityTripService.Trip memory trip = getTrip(tripId);
        require(
            trip.guest == tx.origin, "For trip guest only"
        );
        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 endFuelLevelInGal = (carInfo.tankVolumeInGal *
            endFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.CheckedInByGuest,
            "The trip is not in status CheckedInByGuest"
        );
        require(
            idToTripInfo[tripId].startOdometr <= endOdometr,
            "End odometr should be greater than start odometr"
        );
        idToTripInfo[tripId].status = TripStatus.CheckedOutByGuest;
        idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;
        idToTripInfo[tripId].endFuelLevelInGal = endFuelLevelInGal;
        idToTripInfo[tripId].endOdometr = endOdometr;

        emit TripStatusChanged(tripId, TripStatus.CheckedOutByGuest);
    }

    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        RentalityTripService.Trip memory trip = getTrip(tripId);
        require(
            trip.host == tx.origin, "For trip host only"
        );
        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 endFuelLevelInGal = (carInfo.tankVolumeInGal *
            endFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.CheckedOutByGuest,
            "The trip is not in status CheckedOutByGuest"
        );
        require(
            idToTripInfo[tripId].endFuelLevelInGal == endFuelLevelInGal,
            "End fuel level does not match"
        );
        require(
            idToTripInfo[tripId].endOdometr == endOdometr,
            "End odometr does not match"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedOutByHost;
        idToTripInfo[tripId].checkedOutByHostDateTime = block.timestamp;

        emit TripStatusChanged(tripId, TripStatus.CheckedOutByHost);
    }

    function finishTrip(uint256 tripId) public {
//require(idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,"The trip is not in status CheckedOutByHost");
        require(
            idToTripInfo[tripId].status == TripStatus.CheckedOutByHost,
            "The trip is not in status CheckedOutByHost"
        );
        idToTripInfo[tripId].status = TripStatus.Finished;

        (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = getResolveAmountInUsdCents(
            idToTripInfo[tripId]
        );
        idToTripInfo[tripId]
        .paymentInfo
        .resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
        idToTripInfo[tripId]
        .paymentInfo
        .resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

        uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;

        if (
            resolveAmountInUsdCents >
            idToTripInfo[tripId].paymentInfo.depositInUsdCents
        ) {
            resolveAmountInUsdCents = idToTripInfo[tripId]
                .paymentInfo
                .depositInUsdCents;
        }
        idToTripInfo[tripId]
        .paymentInfo
        .resolveAmountInUsdCents = resolveAmountInUsdCents;

        emit TripStatusChanged(tripId, TripStatus.Finished);
    }


    function getResolveAmountInUsdCents(
        Trip memory tripInfo
    ) public pure returns (uint64, uint64) {
        uint64 tripDays = RentalityUtils.getCeilDays(tripInfo.startDateTime, tripInfo.endDateTime);

        return
            getResolveAmountInUsdCents(
            tripInfo.startOdometr,
            tripInfo.endOdometr,
            tripInfo.milesIncludedPerDay,
            tripInfo.pricePerDayInUsdCents,
            tripDays,
            tripInfo.startFuelLevelInGal,
            tripInfo.endFuelLevelInGal,
            tripInfo.fuelPricePerGalInUsdCents
        );
    }

    function getResolveAmountInUsdCents(
        uint64 startOdometr,
        uint64 endOdometr,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays,
        uint64 startFuelLevelInGal,
        uint64 endFuelLevelInGal,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64, uint64) {
        return (
            getDrivenMilesResolveAmountInUsdCents(
            startOdometr,
            endOdometr,
            milesIncludedPerDay,
            pricePerDayInUsdCents,
            tripDays
        ),
            getFuelResolveAmountInUsdCents(
            startFuelLevelInGal,
            endFuelLevelInGal,
            fuelPricePerGalInUsdCents
        ));
    }

    function getDrivenMilesResolveAmountInUsdCents(
        uint64 startOdometr,
        uint64 endOdometr,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays
    ) public pure returns (uint64) {
        if (endOdometr - startOdometr <= milesIncludedPerDay * tripDays)
            return 0;

        return
            ((endOdometr - startOdometr - milesIncludedPerDay * tripDays) *
                pricePerDayInUsdCents) / milesIncludedPerDay;
    }

    function getFuelResolveAmountInUsdCents(
        uint64 startFuelLevelInGal,
        uint64 endFuelLevelInGal,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64) {
        if (endFuelLevelInGal >= startFuelLevelInGal) return 0;

        return
            (startFuelLevelInGal - endFuelLevelInGal) *
            fuelPricePerGalInUsdCents;
    }

    function getTrip(uint256 tripId) public view returns (Trip memory) {
        return idToTripInfo[tripId];
    }

    function getTripsByGuest(
        address guest
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].guest == guest) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].guest == guest) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function getTripsByHost(address host) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].host == host) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].host == host) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function getTripsByCar(uint256 carId) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].carId == carId) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].carId == carId) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isCarThatIntersect(
        uint256 tripId,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) private view returns (bool) {
        return
            (idToTripInfo[tripId].carId == carId) &&
            (idToTripInfo[tripId].endDateTime > startDateTime) &&
            (idToTripInfo[tripId].startDateTime < endDateTime);
    }

    function getTripsForCarThatIntersect(
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isCarThatIntersect(currentId, carId, startDateTime, endDateTime)
            ) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isCarThatIntersect(currentId, carId, startDateTime, endDateTime)
            ) {
                result[currentIndex] = idToTripInfo[currentId];
                currentIndex += 1;
            }
        }

        return result;
    }

    function isTripThatIntersect(
        uint256 tripId,
        uint64 startDateTime,
        uint64 endDateTime
    ) private view returns (bool) {
        return
            (idToTripInfo[tripId].endDateTime > startDateTime) &&
            (idToTripInfo[tripId].startDateTime < endDateTime);
    }

    function getTripsThatIntersect(
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isTripThatIntersect(currentId, startDateTime, endDateTime)
            ) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isTripThatIntersect(currentId, startDateTime, endDateTime)
            ) {
                result[currentIndex] = idToTripInfo[currentId];
                currentIndex += 1;
            }
        }

        return result;
    }

    function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress){
        return (idToTripInfo[tripId].host, idToTripInfo[tripId].guest);
    }
}
