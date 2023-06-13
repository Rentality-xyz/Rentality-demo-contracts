// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
    }

    struct Trip {
        uint256 tripId;
        uint256 carId;
        TripStatus status;
        address guest;
        address host;
        uint256 pricePerDayInUsdCents;
        uint startDateTime;
        uint endDateTime;
        string startLocation;
        string endLocation;
        uint64 milesIncluded;
        uint64 fuelPricePerGalInUsdCents;
        PaymentInfo paymentInfo;
        uint approvedDateTime;
        uint checkedInByHostDateTime;
        uint64 startFuelLevelInGal;
        uint64 startOdometr;
        uint checkedInByGuestDateTime;
        uint checkedOutByGuestDateTime;
        uint64 endFuelLevelInGal;
        uint64 endOdometr;
        uint checkedOutByHostDateTime;
    }

    mapping(uint256 => Trip) private idToTripInfo;

    constructor() {}

    function totalTripCount() public view returns (uint) {
        return _tripIdCounter.current();
    }

    function createNewTrip(
        uint256 carId,
        address guest,
        address host,
        uint64 pricePerDayInUsdCents,
        uint startDateTime,
        uint endDateTime,
        string memory startLocation,
        string memory endLocation,
        uint64 milesIncluded,
        uint64 fuelPricePerGalInUsdCents,
        PaymentInfo memory paymentInfo
    ) public {
        _tripIdCounter.increment();
        uint256 newTripId = _tripIdCounter.current();
        if (milesIncluded == 0) {
            milesIncluded = 2 ** 32 - 1;
        }
        paymentInfo.tripId = newTripId;

        idToTripInfo[newTripId] = Trip(
            newTripId,
            carId,
            TripStatus.Created,
            guest,
            host,
            pricePerDayInUsdCents,
            startDateTime,
            endDateTime,
            startLocation,
            endLocation,
            milesIncluded,
            fuelPricePerGalInUsdCents,
            paymentInfo,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );
    }

    function approveTrip(uint256 tripId) public {
        require(
            idToTripInfo[tripId].status == TripStatus.Created,
            "The trip is not in status Created"
        );

        idToTripInfo[tripId].status = TripStatus.Approved;
        idToTripInfo[tripId].approvedDateTime = block.timestamp;
    }

    function rejectTrip(uint256 tripId) public {
        require(
            idToTripInfo[tripId].status == TripStatus.Created,
            "The trip is not in status Created"
        );

        idToTripInfo[tripId].status = TripStatus.Canceled;
    }

    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInGal,
        uint64 startOdometr
    ) public {
        require(
            idToTripInfo[tripId].status == TripStatus.Approved,
            "The trip is not in status Approved"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedInByHost;
        idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
        idToTripInfo[tripId].startFuelLevelInGal = startFuelLevelInGal;
        idToTripInfo[tripId].startOdometr = startOdometr;
    }

    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInGal,
        uint64 startOdometr
    ) public {
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
    }

    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInGal,
        uint64 endOdometr
    ) public {
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
    }

    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInGal,
        uint64 endOdometr
    ) public {
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
    }

    function finishTrip(uint256 tripId) public {
        //require(idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,"The trip is not in status CheckedOutByHost");
        require(
            idToTripInfo[tripId].status == TripStatus.CheckedOutByHost,
            "The trip is not in status CheckedOutByHost"
        );
        idToTripInfo[tripId].status = TripStatus.Finished;

        uint64 resolveDrivenMilesAmountInUsdCents = 0;

        if (
            idToTripInfo[tripId].endOdometr -
                idToTripInfo[tripId].startOdometr >
            idToTripInfo[tripId].milesIncluded
        ) {
            resolveDrivenMilesAmountInUsdCents = (uint64)(
                ((idToTripInfo[tripId].endOdometr -
                    idToTripInfo[tripId].startOdometr -
                    idToTripInfo[tripId].milesIncluded) *
                    idToTripInfo[tripId].pricePerDayInUsdCents) /
                    idToTripInfo[tripId].milesIncluded
            );
        }

        uint64 resolveFuelAmountInUsdCents = 0;
        if (
            idToTripInfo[tripId].endFuelLevelInGal <
            idToTripInfo[tripId].startFuelLevelInGal
        ) {
            resolveFuelAmountInUsdCents = ((idToTripInfo[tripId]
                .startFuelLevelInGal - idToTripInfo[tripId].endFuelLevelInGal) *
                idToTripInfo[tripId].fuelPricePerGalInUsdCents);
        }

        uint64 resolveAmountInUsdCents = resolveDrivenMilesAmountInUsdCents +
            resolveFuelAmountInUsdCents;
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

    function getTripsByCar(
        uint256 carTokenId
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].carId == carTokenId) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].carId == carTokenId) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }
}
