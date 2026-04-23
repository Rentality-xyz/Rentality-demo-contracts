/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../common/CommonTypes.sol";
import "./CarTypes.sol";

library CarLib {
    error InvalidCarPrice();
    error InvalidMilesIncluded();

    int128 internal constant EARTH_RADIUS = 3_959;
    int128 internal constant COORDINATE_ACCURACY = 10000000000000;
    int128 internal constant REAL_FBITS = 40;
    int128 internal constant REAL_ONE = int128(1) << uint128(REAL_FBITS);
    int128 internal constant REAL_PI = 3454217652358;
    int128 internal constant REAL_HALF_PI = REAL_PI / 2;
    int128 internal constant REAL_TWO_PI = REAL_PI * 2;
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
        return _realFromInt(int88(int128(_parseInt(coordinates)))) / COORDINATE_ACCURACY;
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
        int128 a = _realMul(_realSin(dLat / 2), _realSin((dLat / 2))) +
            _realMul(
                _realMul(
                    _realMul(_realSin(dLon / 2), _realSin((dLon / 2))),
                    _realCos(_deg2rad(lat1))
                ),
                _realCos(_deg2rad(lat2))
            );
        int128 y = REAL_ONE - a;
        int128 c = 2 *
            _realAtan2(int128(uint128(_realSqrtInt(uint128(a)))), int128(uint128(_realSqrtInt(uint128(y)))));
        return _realToInt(c * EARTH_RADIUS);
    }

    function _deg2rad(int128 degrees) private pure returns (int128) {
        return _realDiv(_realMul(degrees, REAL_PI), _realFromInt(180));
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

    function _realFromInt(int88 integerPart) private pure returns (int128) {
        return int128(integerPart) * REAL_ONE;
    }

    function _realToInt(int128 realValue) private pure returns (int88) {
        return int88(realValue / REAL_ONE);
    }

    function _realAbs(int128 realValue) private pure returns (int128) {
        return realValue >= 0 ? realValue : -realValue;
    }

    function _realMul(int128 realA, int128 realB) private pure returns (int128) {
        return int128((realA * realB) >> uint128(REAL_FBITS));
    }

    function _realDiv(int128 numerator, int128 denominator) private pure returns (int128) {
        return int128((numerator * REAL_ONE) / denominator);
    }

    function _realSin(int128 realArg) private pure returns (int128) {
        return _realSinLimited(realArg, 15);
    }

    function _realSinLimited(int128 realArg, int88 maxIterations) private pure returns (int128) {
        if (realArg < 0) {
            realArg += REAL_TWO_PI;
        }
        realArg = realArg % REAL_TWO_PI;

        int128 accumulator = REAL_ONE;
        require(maxIterations > 0 && maxIterations <= 70, "Invalid iteration count");

        for (int88 iteration = maxIterations - 1; iteration >= 0; iteration--) {
            int128 denominator = _realFromInt((2 * iteration + 2) * (2 * iteration + 3));
            if (denominator == 0) {
                continue;
            }

            int128 term = _realDiv(_realMul(realArg, realArg), denominator);
            accumulator = REAL_ONE - _realMul(term, accumulator);
        }

        return _realMul(realArg, accumulator);
    }

    function _realCos(int128 realArg) private pure returns (int128) {
        return _realSin(realArg + REAL_HALF_PI);
    }

    function _realAtanSmall(int128 realArg) private pure returns (int128) {
        int128 realArgSquared = _realMul(realArg, realArg);

        return
            _realMul(
                _realMul(
                    _realMul(
                        _realMul(
                            _realMul(
                                _realMul(-12606780422, realArgSquared) + 57120178819,
                                realArgSquared
                            ) - 127245381171,
                            realArgSquared
                        ) + 212464129393,
                        realArgSquared
                    ) - 365662383026,
                    realArgSquared
                ) + 1099483040474,
                realArg
            );
    }

    function _realAtan2(int128 realY, int128 realX) private pure returns (int128) {
        int128 atanResult;
        int128 realAbsX = _realAbs(realX);
        int128 realAbsY = _realAbs(realY);

        if (realAbsX > realAbsY) {
            atanResult = _realAtanSmall(_realDiv(realAbsY, realAbsX));
        } else {
            atanResult = REAL_HALF_PI - _realAtanSmall(_realDiv(realAbsX, realAbsY));
        }

        if (realX < 0) {
            if (realY < 0) {
                atanResult -= REAL_PI;
            } else {
                atanResult = REAL_PI - atanResult;
            }
        } else if (realY < 0) {
            atanResult = -atanResult;
        }

        return atanResult;
    }

    function _realSqrtInt(uint128 x) private pure returns (uint128 y) {
        uint128 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

