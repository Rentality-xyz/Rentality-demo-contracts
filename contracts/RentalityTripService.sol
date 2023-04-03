// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

contract RentalityTripService {
    using Counters for Counters.Counter;
    Counters.Counter private _tripIdCounter;

    struct Trip {
        uint256 carId;
        address guest;
        address host;
        uint256 startDateTime;
        uint256 endDateTime;
        string startLocation;
        string endLocation;
        uint256 milesIncluded;
        uint256 totalDayPrice;
        uint256 taxPrice;
        uint256 deposit;
        bool isAccepted;
        bool isCheckedInByHost;
        uint256 checkedInByHostDateTime;
        uint256 startFuelLevel;
        uint256 startOdometr;
        bool isCheckedInByGuest;
        uint256 checkedInByGuestDateTime;
        bool isCheckedOutByGuest;
        uint256 checkedOutByGuestDateTime;
        uint256 endFuelLevel;
        uint256 endOdometr;
        bool isCheckedOutByHost;
        uint256 checkedOutByHostDateTime;
        bool isFinished;
        uint256 resolveAmount;
    }

    mapping(uint256 => Trip) private idToTripInfo;

    constructor() {}

    function totalTripCount() public view returns (uint) {
        return _tripIdCounter.current();
    }

    function addTrip(
        uint256 carId,
        address guest,
        address host,
        uint256 startDateTime,
        uint256 endDateTime,
        string memory startLocation,
        string memory endLocation,
        uint256 milesIncluded, 
        uint256 totalDayPrice,
        uint256 taxPrice,
        uint256 deposit,
        bool isAccepted
    ) public {
        _tripIdCounter.increment();
        uint256 newTripId = _tripIdCounter.current();

        idToTripInfo[newTripId] = Trip(
            carId,
            guest,
            host,
            startDateTime,
            endDateTime,
            startLocation,
            endLocation,
            milesIncluded,
            totalDayPrice,
            taxPrice,
            deposit,
            isAccepted,
            false,
            0,
            0,
            0,
            false,
            0,
            false,
            0,
            0,
            0,
            false,
            0,
            false,
            0
        );
    }

    function checkInByHost( uint256 tripId, uint256 startFuelLevel, uint256 startOdometr ) public {
        idToTripInfo[tripId].isCheckedInByHost = true;
        idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
        idToTripInfo[tripId].startFuelLevel = startFuelLevel;
        idToTripInfo[tripId].startOdometr = startOdometr;
    }

    function checkInByGuest(
        uint256 tripId,
        uint256 startFuelLevel,
        uint256 startOdometr
    ) public {
        require( idToTripInfo[tripId].startFuelLevel == startFuelLevel, "Start fuel level does not match" );
        require( idToTripInfo[tripId].startOdometr == startOdometr, "Start odometr does not match" );

        idToTripInfo[tripId].isCheckedInByGuest = true;
        idToTripInfo[tripId].checkedInByGuestDateTime = block.timestamp;
    }

    function checkOutByGuest( uint256 tripId, uint256 endFuelLevel, uint256 endOdometr) public {
        idToTripInfo[tripId].isCheckedOutByGuest = true;
        idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;
        idToTripInfo[tripId].endFuelLevel = endFuelLevel;
        idToTripInfo[tripId].endOdometr = endOdometr;
    }

    function checkOutByHost( uint256 tripId, uint256 endFuelLevel, uint256 endOdometr ) public {
        require( idToTripInfo[tripId].endFuelLevel == endFuelLevel, "End fuel level does not match" );
        require( idToTripInfo[tripId].endOdometr == endOdometr, "End odometr does not match" );

        idToTripInfo[tripId].isCheckedOutByHost = true;
        idToTripInfo[tripId].checkedOutByHostDateTime = block.timestamp;
    }

    function finishTrip(uint256 tripId) public {
        require(!idToTripInfo[tripId].isFinished, "The trip is already finished" );

        idToTripInfo[tripId].isFinished = true;
    }

    function resolveIssue(uint256 tripId, uint256 fuelPricePerGal) public {
        require( !idToTripInfo[tripId].isFinished, "The trip is already finished" );

        idToTripInfo[tripId].isFinished = true;
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

    function getTripsByGuest( address guest ) public view returns (Trip[] memory) {
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

    function getTripsByCar( uint256 carTokenId ) public view returns (Trip[] memory) {
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
