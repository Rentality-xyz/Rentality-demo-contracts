// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from '../../Schemas.sol';
import { RealMath } from '../../libs/RealMath.sol';
import { LibDiamond } from './LibDiamond.sol';
import {RentalityUtilsDiamond} from './getters/RentalityUtilsDiamond.sol';



int128 constant EARTH_RADIUS = 3_959;
int128 constant COORDINATE_ACCURACY = 10000000000000;
/// @title RentalityCarDelivery

library DeliveryStorage {
    struct DeliveryFaucetStorage {
        mapping(address => Schemas.DeliveryPrices) userToDeliveryPrice;
        Schemas.DeliveryPrices defaultPrices;
    }


  /// @notice Calculates the total price for a delivery based on given delivery data and user's location
  /// @param pickUpLoc Delivery pickUp location details
  /// @param returnLoc Delivery return location details
  /// @param homeLat Latitude of user's home location
  /// @param homeLon Longitude of user's home location
  /// @return Total price in USD cents
  function calculatePriceByDeliveryDataInUsdCents(
    Schemas.LocationInfo memory pickUpLoc,
    Schemas.LocationInfo memory returnLoc,
    string memory homeLat,
    string memory homeLon,
    address user
  ) internal view returns (uint64) {
    DeliveryFaucetStorage storage s = accessStorage();
    int128 pickUpDistance = calculateDistance(pickUpLoc.latitude, pickUpLoc.longitude, homeLat, homeLon);
    int128 returnDistance = calculateDistance(returnLoc.latitude, returnLoc.longitude, homeLat, homeLon);
    uint64 total = 0;
    Schemas.DeliveryPrices memory userPrices = s.userToDeliveryPrice[user];
    if (!userPrices.initialized) {
      userPrices = s.defaultPrices;
    }
    if (pickUpDistance > 25) {
      total += uint64(uint128(pickUpDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    } else {
      total += uint64(uint128(pickUpDistance)) * userPrices.underTwentyFiveMilesInUsdCents;
    }
    if (returnDistance > 25) {
      total += uint64(uint128(returnDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    } else {
      total += uint64(uint128(returnDistance)) * userPrices.underTwentyFiveMilesInUsdCents;
    }

    return total;
  }

   /// @notice Retrieves delivery prices for a user
  /// @param user Address of the user
  /// @return DeliveryPrices struct containing the user's delivery prices
  function getUserDeliveryPrices(address user) internal view returns (Schemas.DeliveryPrices memory) {
    DeliveryFaucetStorage storage s = accessStorage();
    return s.userToDeliveryPrice[user].initialized ? s.userToDeliveryPrice[user] : s.defaultPrices;
  }

  function calculatePricesByDeliveryDataInUsdCents(
    Schemas.LocationInfo memory pickUpLoc,
    Schemas.LocationInfo memory returnLoc,
    string memory homeLat,
    string memory homeLon,
    address user
  ) internal view returns (uint64, uint64) {
    DeliveryFaucetStorage storage s = accessStorage();
    int128 pickUpDistance = (bytes(pickUpLoc.latitude).length == 0)
      ? int128(0)
      : calculateDistance(pickUpLoc.latitude, pickUpLoc.longitude, homeLat, homeLon);
    int128 returnDistance = (bytes(returnLoc.latitude).length == 0)
      ? int128(0)
      : calculateDistance(returnLoc.latitude, returnLoc.longitude, homeLat, homeLon);
    uint64 pickUp = 0;
    uint64 dropOf = 0;
    Schemas.DeliveryPrices memory userPrices = s.userToDeliveryPrice[user];
    if (!userPrices.initialized) {
      userPrices = s.defaultPrices;
    }
    if (pickUpDistance > 25) {
      pickUp += uint64(uint128(pickUpDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    } else {
      pickUp += uint64(uint128(pickUpDistance)) * userPrices.underTwentyFiveMilesInUsdCents;
    }
    if (returnDistance > 25) {
      dropOf += uint64(uint128(returnDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    } else {
      dropOf += uint64(uint128(returnDistance)) * userPrices.underTwentyFiveMilesInUsdCents;
    }
    return (pickUp, dropOf);
  }

  /// @notice Calculates the distance between two points on the Earth's surface using Haversine formula
  /// @param lat1 Latitude of first point
  /// @param lon1 Longitude of first point
  /// @param lat2 Latitude of second point
  /// @param lon2 Longitude of second point
  /// @return Distance in meters
  function calculateDistance(
    string memory lat1,
    string memory lon1,
    string memory lat2,
    string memory lon2
  ) internal pure returns (int128) {
    if (bytes(lat1).length == 0 || bytes(lat2).length == 0) {
      return 0;
    }
    return calculateDistanceFromReal(toReal(lat1), toReal(lon1), toReal(lat2), toReal(lon2));
  }

  /// @notice Converts latitude/longitude coordinates from string to Real
  /// @param coordinates String representation of coordinates
  /// @return Real representation of coordinates
  function toReal(string memory coordinates) internal pure returns (int128) {
    return RealMath.toReal(int88(int128(RentalityUtilsDiamond.parseInt(coordinates)))) / COORDINATE_ACCURACY;
  }

  /// @notice Calculates distance between two points on Earth's surface using Real coordinates
  /// @param lat1 Latitude of first point
  /// @param lon1 Longitude of first point
  /// @param lat2 Latitude of second point
  /// @param lon2 Longitude of second point
  /// @return Distance in meters
  function calculateDistanceFromReal(
    int128 lat1,
    int128 lon1,
    int128 lat2,
    int128 lon2
  ) internal pure returns (int128) {
    if (lat1 == lat2 && lon2 == lon1) {
      return 0;
    }
    int128 dLat = deg2rad(lat2 - lat1);
    int128 dLon = deg2rad(lon2 - lon1);
    int128 a = RealMath.mul(RealMath.sin(dLat / 2), RealMath.sin((dLat / 2))) +
      RealMath.mul(
        RealMath.mul(RealMath.mul(RealMath.sin(dLon / 2), RealMath.sin((dLon / 2))), RealMath.cos(deg2rad(lat1))),
        RealMath.cos(deg2rad(lat2))
      );
    int128 y = RealMath.REAL_ONE - a;
    int128 c = 2 *
      RealMath.atan2(int128(uint128(RealMath.sqrt1(uint128(a)))), int128(uint128(RealMath.sqrt1(uint128(y)))));
    return RealMath.fromReal(c * EARTH_RADIUS);
  }

  /// @notice Converts degrees to radians
  /// @param degrees Value in degrees
  /// @return Value in radians
  function deg2rad(int128 degrees) internal pure returns (int128) {
    return RealMath.div(RealMath.mul(degrees, RealMath.REAL_PI), RealMath.toReal(180));
  }

  function sortCarsByDistance(
    Schemas.SearchCar[] memory cars,
    Schemas.LocationInfo memory pickUpLocation
  ) internal pure returns (Schemas.SearchCarWithDistance[] memory result) {
    int max = 0;

    result = new Schemas.SearchCarWithDistance[](cars.length);
    for (uint i = 0; i < cars.length; i++) {
      int distance = calculateDistance(
        cars[i].locationInfo.latitude,
        cars[i].locationInfo.longitude,
        pickUpLocation.latitude,
        pickUpLocation.longitude
      );
      if (distance >= max) {
        max = distance;
        result[i] = Schemas.SearchCarWithDistance(cars[i], distance);
      } else {
        for (uint j = 0; j < i; j++) {
          if (result[j].distance >= distance) {
            for (uint n = i; n > j; n--) {
              result[n] = result[n - 1];
            }
            result[j] = Schemas.SearchCarWithDistance(cars[i], distance);
            break;
          }
          /// TODO: uncomment after update to 0.8.25
          //            assembly {
          //              // shifting by memcopy all calculated values from j..i to j + 1..i + 1
          //              mcopy(
          //                add(
          //                  /*  mem pointer where we will save data
          //                                     result is location of array, add 32 to skip pointer */
          //                  add(32, result),
          //                  mul(32, add(j, 1))
          //                ),
          //                /* mem pointer read from*/
          //                add(add(32, result), mul(32, j)),
          //                /* amount bytes to copy, 32 is size of pointers*/
          //                mul(32, i)
          //              )
          //            }
          //            result[j] = Schemas.SearchCarWithDistance(cars[i], distance);
          //            break;
          //          }
        }
      }
    }
  }
   function accessStorage() internal pure returns (DeliveryFaucetStorage storage cs) {
        bytes32 position = LibDiamond.DELIVERY_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}