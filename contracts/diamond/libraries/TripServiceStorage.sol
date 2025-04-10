// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";

library TripServiceStorage { 
    struct TripServiceFaucetStorage {
        uint _tripIdCounter;

        mapping(uint256 => Schemas.Trip) idToTripInfo;

        mapping(uint => bool) completedByAdmin;

        mapping(uint => uint) tripIdToEthSumInTripCreation;

        mapping(uint => uint[]) carIdToActiveTrips;
        mapping(uint => uint[]) carIdToTrips;
        mapping(address => uint[]) userToTrips;
        mapping(address => uint[]) userToActiveTrips;
        }

        function getTrip(uint tripId) internal view returns(Schemas.Trip memory) {
        TripServiceFaucetStorage storage s = accessStorage();
        return s.idToTripInfo[tripId];
        }

        function isCarEditable(uint carId) internal view returns (bool) {
             TripServiceFaucetStorage storage s = accessStorage();
             uint[] memory carTrips = s.carIdToActiveTrips[carId];

            for (uint i = 0; i < carTrips.length; i++) {
            Schemas.Trip memory tripInfo = s.idToTripInfo[i];

            if (
                tripInfo.carId == carId &&
                (tripInfo.status != Schemas.TripStatus.Finished &&
                tripInfo.status != Schemas.TripStatus.Canceled &&
                (tripInfo.status != Schemas.TripStatus.CheckedOutByHost && tripInfo.host != tripInfo.tripFinishedBy))
            ) {
                return false;
            }
    }

            return true;
  }

         function getActiveTrips(uint carId) internal view returns (uint[] memory) {
            TripServiceFaucetStorage storage s = accessStorage();
            return s.carIdToActiveTrips[carId];
        }
        function getCarTrips(uint carId) internal view returns (uint[] memory) {
            TripServiceFaucetStorage storage s = accessStorage();
            return s.carIdToTrips[carId];
        }
        function getActiveTripsByUser(address host) internal view returns (uint[] memory) {
            TripServiceFaucetStorage storage s = accessStorage();
            return s.userToActiveTrips[host];
        }
        function getTripsByUser(address host) internal view returns (uint[] memory) {
            TripServiceFaucetStorage storage s = accessStorage();
            return s.userToTrips[host];
        }
         function totalTripCount() internal view returns (uint) {
            TripServiceFaucetStorage storage s = accessStorage();
            return s._tripIdCounter;
        }
        function incrementTripIdCounter() internal {
            TripServiceFaucetStorage storage s = accessStorage();
            s._tripIdCounter++;
        }

         function accessStorage() internal pure returns (TripServiceFaucetStorage storage ds) {
        bytes32 position = LibDiamond.TRIP_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
}