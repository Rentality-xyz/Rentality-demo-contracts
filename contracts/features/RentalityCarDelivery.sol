// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../RentalityUserService.sol';
import '../libs/RealMath.sol';
import '../libs/RentalityUtils.sol';
import '../Schemas.sol';

int128 constant EARTH_RADIUS = 3_959;
int128 constant COORDINATE_ACCURACY = 10000000000000;
/// @title RentalityCarDelivery
/// @notice Contract for managing car delivery functionality
/// @dev SAFETY: only pure functions in RealMath library
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityCarDelivery is Initializable, UUPSAccess {
  mapping(address => Schemas.DeliveryPrices) private userToDeliveryPrice;
  Schemas.DeliveryPrices private defaultPrices;

  /// @notice Sets delivery prices for a user
  /// @param underTwentyFiveMilesInUsdCents Price in USD cents for distances under 25 miles
  /// @param aboveTwentyFiveMilesInUsdCents Price in USD cents for distances above 25 miles
  function setUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    require(userService.isHost(tx.origin), 'Only host.');
    userToDeliveryPrice[tx.origin] = Schemas.DeliveryPrices(
      underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents,
      true
    );
  }

  /// @notice Retrieves delivery prices for a user
  /// @param user Address of the user
  /// @return DeliveryPrices struct containing the user's delivery prices
  function getUserDeliveryPrices(address user) public view returns (Schemas.DeliveryPrices memory) {
    return userToDeliveryPrice[user].initialized ? userToDeliveryPrice[user] : defaultPrices;
  }

  /// @notice Calculates the total price for a delivery based on given delivery data and user's location
  /// @param deliveryData Delivery location details
  /// @param homeLat Latitude of user's home location
  /// @param homeLon Longitude of user's home location
  /// @return Total price in USD cents
  function calculatePriceByDeliveryDataInUsdCents(
    Schemas.DeliveryLocations memory deliveryData,
    string memory homeLat,
    string memory homeLon
  ) public view returns (uint64) {
    int128 pickUpDistance = calculateDistance(deliveryData.pickUpLat, deliveryData.pickUpLon, homeLat, homeLon);
    int128 returnDistance = calculateDistance(deliveryData.returnLat, deliveryData.returnLon, homeLat, homeLon);
    uint64 total = 0;
    Schemas.DeliveryPrices memory userPrices = userToDeliveryPrice[tx.origin];
    if (!userPrices.initialized) {
      userPrices = defaultPrices;
    }
    if (pickUpDistance > 25) {
      total += uint64(uint128(pickUpDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    } else {
      total += uint64(uint128(pickUpDistance)) * userPrices.underTwentyFiveMilesInUsdCents;
    }
    if (returnDistance > 25) {
      total += uint64(uint128(returnDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    } else {
      total += uint64(uint128(returnDistance)) * userPrices.aboveTwentyFiveMilesInUsdCents;
    }
    return total;
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
  ) public pure returns (int128) {
    return calculateDistanceFromReal(toReal(lat1), toReal(lon1), toReal(lat2), toReal(lon2));
  }

  /// @notice Converts latitude/longitude coordinates from string to Real
  /// @param coordinates String representation of coordinates
  /// @return Real representation of coordinates
  function toReal(string memory coordinates) internal pure returns (int128) {
    return RealMath.toReal(int88(int128(RentalityUtils.parseInt(coordinates)))) / COORDINATE_ACCURACY;
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

  function getEmptyLocations() public pure returns (Schemas.DeliveryLocations memory) {
    return Schemas.DeliveryLocations('', '', '', '');
  }

  /// @notice Initializes the contract with the provided user service address
  /// @param _userService Address of the user service contract
  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    defaultPrices = Schemas.DeliveryPrices(250, 300, true);
  }
}
