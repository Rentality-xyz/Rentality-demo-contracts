pragma solidity ^0.8.20;

import "../common/CommonTypes.sol";
import "./CarTypes.sol";
import "../common/RealMath.sol";

library CarLib {
    error InvalidCarPrice();
    error InvalidMilesIncluded();

    int128 internal constant EARTH_RADIUS = 3_959;
    int128 internal constant COORDINATE_ACCURACY = 10000000000000;
    uint256 internal constant COORDINATE_MULTIPLIER = 10 ** 7;

    function validatePricing(uint64 pricePerDayInUsdCents, uint64 milesIncludedPerDay) internal pure {
        if (pricePerDayInUsdCents == 0) {
            revert InvalidCarPrice();
        }

        if (milesIncludedPerDay == 0) {
            revert InvalidMilesIncluded();
        }
    }

    function hashVin(string memory carVinNumber) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(carVinNumber));
    }

    function buildName(
        string memory requestedName,
        string memory brand,
        string memory model
    ) internal pure returns (string memory) {
        return bytes(requestedName).length > 0 ? requestedName : string.concat(brand, " ", model);
    }

    function updateListingMoment(
        mapping(uint256 => uint256) storage listingMomentById,
        uint256 id,
        bool wasListed,
        bool isListedNow
    ) internal {
        if (!wasListed && isListedNow) {
            listingMomentById[id] = block.timestamp;
        }

        if (wasListed && !isListedNow) {
            listingMomentById[id] = 0;
        }
    }

    function calculateDeliveryPrices(
        LocationInfo memory pickUpLocation,
        LocationInfo memory returnLocation,
        string memory homeLat,
        string memory homeLon,
        DeliveryPrices memory prices
    ) internal pure returns (uint64 pickUp, uint64 dropOf) {
        int128 pickUpDistance = bytes(pickUpLocation.latitude).length == 0
            ? int128(0)
            : calculateDistance(pickUpLocation.latitude, pickUpLocation.longitude, homeLat, homeLon);
        int128 returnDistance = bytes(returnLocation.latitude).length == 0
            ? int128(0)
            : calculateDistance(returnLocation.latitude, returnLocation.longitude, homeLat, homeLon);

        pickUp = _calculateDeliveryFee(pickUpDistance, prices);
        dropOf = _calculateDeliveryFee(returnDistance, prices);
    }

    function calculateDistance(
        string memory lat1,
        string memory lon1,
        string memory lat2,
        string memory lon2
    ) internal pure returns (int128) {
        if (bytes(lat1).length == 0 || bytes(lat2).length == 0) {
            return 0;
        }

        return _calculateDistanceFromReal(_toReal(lat1), _toReal(lon1), _toReal(lat2), _toReal(lon2));
    }

    function _calculateDeliveryFee(int128 distance, DeliveryPrices memory prices) private pure returns (uint64) {
        if (distance > 25) {
            return uint64(uint128(distance)) * prices.aboveTwentyFiveMilesInUsdCents;
        }

        return uint64(uint128(distance)) * prices.underTwentyFiveMilesInUsdCents;
    }

    function _toReal(string memory coordinates) private pure returns (int128) {
        return RealMath.toReal(int88(int128(_parseInt(coordinates)))) / COORDINATE_ACCURACY;
    }

    function _calculateDistanceFromReal(
        int128 lat1,
        int128 lon1,
        int128 lat2,
        int128 lon2
    ) private pure returns (int128) {
        if (lat1 == lat2 && lon2 == lon1) {
            return 0;
        }

        int128 dLat = _deg2rad(lat2 - lat1);
        int128 dLon = _deg2rad(lon2 - lon1);
        int128 a = RealMath.mul(RealMath.sin(dLat / 2), RealMath.sin((dLat / 2))) +
            RealMath.mul(
                RealMath.mul(
                    RealMath.mul(RealMath.sin(dLon / 2), RealMath.sin((dLon / 2))),
                    RealMath.cos(_deg2rad(lat1))
                ),
                RealMath.cos(_deg2rad(lat2))
            );
        int128 y = RealMath.REAL_ONE - a;
        int128 c = 2 *
            RealMath.atan2(int128(uint128(RealMath.sqrt1(uint128(a)))), int128(uint128(RealMath.sqrt1(uint128(y)))));
        return RealMath.fromReal(c * EARTH_RADIUS);
    }

    function _deg2rad(int128 degrees) private pure returns (int128) {
        return RealMath.div(RealMath.mul(degrees, RealMath.REAL_PI), RealMath.toReal(180));
    }

    function _parseInt(string memory value) private pure returns (int256) {
        bytes memory source = bytes(value);
        int256 parsed = 0;
        bool decimals = false;

        for (uint256 i = 0; i < source.length; i++) {
            uint8 charCode = uint8(source[i]);
            if (charCode >= 48 && charCode <= 57) {
                if (decimals && i - 1 - _indexOf(source, 46) > 6) {
                    break;
                }
                parsed = parsed * 10 + int256(uint256(charCode) - 48);
            } else if (charCode == 46) {
                decimals = true;
            }
        }

        if (_indexOf(source, 45) == 0) {
            return -parsed * int256(COORDINATE_MULTIPLIER);
        }

        return parsed * int256(COORDINATE_MULTIPLIER);
    }

    function _indexOf(bytes memory haystack, uint8 needle) private pure returns (uint256) {
        for (uint256 i = 0; i < haystack.length; i++) {
            if (uint8(haystack[i]) == needle) {
                return i;
            }
        }

        return haystack.length;
    }
}

