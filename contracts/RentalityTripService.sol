// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

contract RentalityTripService {
    using Counters for Counters.Counter;
    Counters.Counter private _tripIdCounter;

    enum TripStatus {
        Created,
        CheckedInByHost,
        CheckedInByGuest,
        CheckedOutByGuest,
        CheckedOutByHost,
        Finished,
        Canceled
    }

    struct TripPaymentInfo {
        uint256 totalDayPrice;
        uint256 taxPrice;
        uint256 deposit;
    }

    struct Trip {
        uint256 carId;
        uint256 tripRequestId;
        TripStatus status;
        address guest;
        address host;
        uint startDateTime;
        uint endDateTime;
        string startLocation;
        string endLocation;
        uint256 milesIncluded;
        uint256 totalDayPrice;
        uint256 taxPrice;
        uint256 deposit;
        bool isAccepted;
        uint checkedInByHostDateTime;
        uint startFuelLevel;
        uint startOdometr;
        uint checkedInByGuestDateTime;
        uint checkedOutByGuestDateTime;
        uint endFuelLevel;
        uint endOdometr;
        uint checkedOutByHostDateTime;
        uint256 resolveAmount;
    }

    mapping(uint256 => Trip) private idToTripInfo;

    constructor() {}

    function totalTripCount() public view returns (uint) {
        return _tripIdCounter.current();
    }

    function addTrip(
        uint256 carId,
        uint256 tripRequestId,
        address guest,
        address host,
        uint startDateTime,
        uint endDateTime,
        string memory startLocation,
        string memory endLocation,
        uint256 milesIncluded,
        TripPaymentInfo memory tripPaymentInfo,
        bool isAccepted
    ) public {
        _tripIdCounter.increment();
        uint256 newTripId = _tripIdCounter.current();

        idToTripInfo[newTripId] = Trip(
            carId,
            tripRequestId,
            isAccepted ? TripStatus.Created : TripStatus.Canceled,
            guest,
            host,
            startDateTime,
            endDateTime,
            startLocation,
            endLocation,
            milesIncluded,
            tripPaymentInfo.totalDayPrice,
            tripPaymentInfo.taxPrice,
            tripPaymentInfo.deposit,
            isAccepted,
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

    function checkInByHost(
        uint256 tripId,
        uint startFuelLevel,
        uint startOdometr
    ) public {
        require(
            idToTripInfo[tripId].status != TripStatus.Created,
            "The trip is not in status Created"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedInByHost;
        idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
        idToTripInfo[tripId].startFuelLevel = startFuelLevel;
        idToTripInfo[tripId].startOdometr = startOdometr;
    }

    function checkInByGuest(
        uint256 tripId,
        uint startFuelLevel,
        uint startOdometr
    ) public {
        require(
            idToTripInfo[tripId].status != TripStatus.CheckedInByHost,
            "The trip is not in status CheckedInByHost"
        );
        require(
            idToTripInfo[tripId].startFuelLevel == startFuelLevel,
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
        uint endFuelLevel,
        uint endOdometr
    ) public {
        require(
            idToTripInfo[tripId].status != TripStatus.CheckedInByGuest,
            "The trip is not in status CheckedInByGuest"
        );
        idToTripInfo[tripId].status = TripStatus.CheckedOutByGuest;
        idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;
        idToTripInfo[tripId].endFuelLevel = endFuelLevel;
        idToTripInfo[tripId].endOdometr = endOdometr;
    }

    function checkOutByHost(
        uint256 tripId,
        uint endFuelLevel,
        uint endOdometr
    ) public {
        require(
            idToTripInfo[tripId].status != TripStatus.CheckedOutByGuest,
            "The trip is not in status CheckedOutByGuest"
        );
        require(
            idToTripInfo[tripId].endFuelLevel == endFuelLevel,
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
        require(
            idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,
            "The trip is not in status CheckedOutByHost"
        );

        idToTripInfo[tripId].status = TripStatus.Finished;
    }

    function resolveIssue(uint256 tripId, uint256 fuelPricePerGal) public {
        require(
            idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,
            "The trip is not in status CheckedOutByHost"
        );

        idToTripInfo[tripId].status = TripStatus.Finished;
        uint256 resolveFuelAmount = (idToTripInfo[tripId].endFuelLevel -
            idToTripInfo[tripId].startFuelLevel) * fuelPricePerGal;
        if (resolveFuelAmount < 0) {
            resolveFuelAmount = 0;
        }
        uint256 resolveDrivenMilesAmount = ((idToTripInfo[tripId].endOdometr -
            idToTripInfo[tripId].startOdometr -
            idToTripInfo[tripId].milesIncluded) *
            idToTripInfo[tripId].totalDayPrice) /
            idToTripInfo[tripId].milesIncluded;
        idToTripInfo[tripId].resolveAmount =
            resolveFuelAmount +
            resolveDrivenMilesAmount;
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
