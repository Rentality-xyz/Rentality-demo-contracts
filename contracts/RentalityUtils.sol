// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityCarToken.sol";
import "./IRentalityGateway.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import './RentalityGeoService.sol';

/// @title RentalityUtils Library
/// @notice
/// This library provides utility functions for handling coordinates, string manipulation,
/// and parsing responses related to geolocation data. It includes functions for checking
/// coordinates within a specified bounding box, parsing strings, converting between data types,
/// and URL encoding. The library is used in conjunction with other Rentality contracts.
library RentalityUtils {
    // Constant multiplier for converting decimal coordinates to integers
    uint256 constant multiplier = 10 ** 7;
    /// @notice Checks if a set of coordinates falls within a specified bounding box.
    /// @param locationLat Latitude of the location to check.
    /// @param locationLng Longitude of the location to check.
    /// @param northeastLat Latitude of the northeast corner of the bounding box.
    /// @param northeastLng Longitude of the northeast corner of the bounding box.
    /// @param southwestLat Latitude of the southwest corner of the bounding box.
    /// @param southwestLng Longitude of the southwest corner of the bounding box.
    /// @return Returns true if the coordinates are within the bounding box, false otherwise.
    function checkCoordinates(
        string memory locationLat,
        string memory locationLng,
        string memory northeastLat,
        string memory northeastLng,
        string memory southwestLat,
        string memory southwestLng
    ) external pure returns (bool) {
        int256 lat = parseInt(locationLat);
        int256 lng = parseInt(locationLng);
        int256 neLat = parseInt(northeastLat);
        int256 neLng = parseInt(northeastLng);
        int256 swLat = parseInt(southwestLat);
        int256 swLng = parseInt(southwestLng);

        return (lat >= swLat && lat <= neLat && lng >= swLng && lng <= neLng);
    }
    /// @notice Parses an integer from a string.
    /// @param _a The input string to parse.
    /// @return Returns the parsed integer value.
    function parseInt(string memory _a) internal pure returns (int256) {
        bytes memory bresult = bytes(_a);
        int256 mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
                if (decimals) {
                    if (i - 1 - indexOf(bresult, ".") > 6) break;
                    mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
                } else {
                    mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
                }
            } else if (uint8(bresult[i]) == 46) decimals = true;
        }
        if (indexOf(bresult, "-") == 0) {
            return - mint * int256(multiplier);
        }
        return mint * int256(multiplier);
    }
    /// @notice Finds the index of a substring in a given string.
    /// @param haystack The string to search within.
    /// @param needle The substring to search for.
    /// @return Returns the index of the first occurrence of the substring, or the length of the string if not found.
    function indexOf(bytes memory haystack, string memory needle) internal pure returns (uint) {
        bytes memory bneedle = bytes(needle);
        if (bneedle.length > haystack.length) {
            return haystack.length;
        }

        bool found = false;
        uint i;
        for (i = 0; i <= haystack.length - bneedle.length; i++) {
            found = true;
            for (uint j = 0; j < bneedle.length; j++) {
                if (haystack[i + j] != bneedle[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                break;
            }
        }
        return i;
    }
    /// @notice Converts a string to lowercase.
    /// @param str The input string to convert.
    /// @return Returns the lowercase version of the input string.
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    /// @notice Checks if a string contains a specific word.
    /// @param where The string to search within.
    /// @param what The word to search for.
    /// @return found Returns true if the word is found, false otherwise.
    function containWord(string memory where, string memory what) internal pure returns (bool found) {
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);

        if (whereBytes.length < whatBytes.length) {
            return false;
        }

        found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes[i + j] != whatBytes[j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }
    /// @notice Generates a hash from a string.
    /// @param str The input string to hash.
    /// @return Returns the keccak256 hash of the input string.
    function getHashFromString(string memory str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
    /// @notice Calculates the ceiling of the division of two numbers.
    /// @param startDateTime The numerator of the division.
    /// @param endDateTime The denominator of the division.
    /// @return Returns the result of the division rounded up to the nearest whole number.
    function getCeilDays(uint64 startDateTime, uint64 endDateTime) public pure returns (uint64) {
        uint64 duration = endDateTime - startDateTime;
        return uint64(Math.ceilDiv(duration, 1 days));
    }
    /// @notice Populates an array of chat information using data from trips, user service, and car service.
    /// @param trips Array of RentalityTripService.Trip structures.
    /// @param userService RentalityUserService contract instance.
    /// @param carService RentalityCarToken contract instance.
    /// @return chatInfoList Array of IRentalityGateway.ChatInfo structures.
    function populateChatInfo(
        RentalityTripService.Trip[] memory trips,
        RentalityUserService userService,
        RentalityCarToken carService
    ) public view returns (IRentalityGateway.ChatInfo[] memory) {
        IRentalityGateway.ChatInfo[] memory chatInfoList = new IRentalityGateway.ChatInfo[](trips.length);

        for (uint i = 0; i < trips.length; i++) {
            RentalityUserService.KYCInfo memory guestInfo = userService.getKYCInfo(trips[i].guest);
            RentalityUserService.KYCInfo memory hostInfo = userService.getKYCInfo(trips[i].host);

            chatInfoList[i].tripId = trips[i].tripId;
            chatInfoList[i].guestAddress = trips[i].guest;
            chatInfoList[i].guestName = string(abi.encodePacked(guestInfo.name, " ", guestInfo.surname));
            chatInfoList[i].guestPhotoUrl = guestInfo.profilePhoto;
            chatInfoList[i].hostAddress = trips[i].host;
            chatInfoList[i].hostName = string(abi.encodePacked(hostInfo.name, " ", hostInfo.surname));
            chatInfoList[i].hostPhotoUrl = hostInfo.profilePhoto;
            chatInfoList[i].tripStatus = uint256(trips[i].status);

            RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trips[i].carId);
            chatInfoList[i].carBrand = carInfo.brand;
            chatInfoList[i].carModel = carInfo.model;
            chatInfoList[i].carYearOfProduction = carInfo.yearOfProduction;
            chatInfoList[i].carMetadataUrl = carService.tokenURI(trips[i].carId);
            chatInfoList[i].startDateTime = trips[i].startDateTime;
            chatInfoList[i].endDateTime = trips[i].endDateTime;
        }

        return chatInfoList;
    }
    /// @notice Parses a response string containing geolocation data.
    /// @param response The response string to parse.
    /// @return result Parsed geolocation data in RentalityGeoService.ParsedGeolocationData structure.
    function parseResponse(string memory response) public pure returns (RentalityGeoService.ParsedGeolocationData memory) {
        RentalityGeoService.ParsedGeolocationData memory result;

        string[] memory pairs = splitString(response);
        for (uint256 i = 0; i < pairs.length; i++) {
            string[] memory keyValue = splitKeyValue(pairs[i]);
            string memory key = keyValue[0];
            string memory value = keyValue[1];
            if (compareStrings(key, "status")) {
                result.status = value;
            } else if (compareStrings(key, "locationLat")) {
                result.locationLat = value;
            } else if (compareStrings(key, "locationLng")) {
                result.locationLng = value;
            } else if (compareStrings(key, "northeastLat")) {
                result.northeastLat = value;
            } else if (compareStrings(key, "northeastLng")) {
                result.northeastLng = value;
            } else if (compareStrings(key, "southwestLat")) {
                result.southwestLat = value;
            } else if (compareStrings(key, "southwestLng")) {
                result.southwestLng = value;
            } else if (compareStrings(key, "locality")) {
                result.city = value;
            } else if (compareStrings(key, "adminAreaLvl1")) {
                result.state = value;
            } else if (compareStrings(key, "country")) {
                result.country = value;
            }
        }

        return result;
    }
    /// @notice Splits a string into an array of substrings based on a delimiter.
    /// @param input The input string to split.
    /// @return parts Array of substrings.
    function splitString(string memory input) internal pure returns (string[] memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory delimiterBytes = bytes("|");

        uint256 delimiterCount = 0;
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (inputBytes[i] == delimiterBytes[0]) {
                delimiterCount++;
            }
        }

        string[] memory parts = new string[](delimiterCount);

        uint256 partIndex = 0;
        uint256 startNewString = 0;

        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (inputBytes[i] == delimiterBytes[0]) {
                bytes memory newString = new bytes(i - startNewString);
                uint256 newStringIndex = 0;
                for (uint256 j = startNewString; j < i; j++) {
                    newString[newStringIndex] = inputBytes[j];
                    newStringIndex++;
                    startNewString++;
                }
                startNewString++;
                parts[partIndex] = string(newString);
                partIndex++;
            }
        }

        return parts;
    }
    /// @notice Splits a key-value pair string into an array of key and value.
    /// @param input The input string to split.
    /// @return parts Array containing key and value.
    function splitKeyValue(string memory input) internal pure returns (string[] memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory delimiterBytes = bytes("^");

        uint256 delimiterIndex = 0;
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (inputBytes[i] == delimiterBytes[0]) {
                delimiterIndex = i;
            }
        }

        string[] memory parts = new string[](2);
        bytes memory keyString = new bytes(delimiterIndex);

        for (uint256 i = 0; i < delimiterIndex; i++) {
            keyString[i] = inputBytes[i];
        }
        parts[0] = string(keyString);

        bytes memory valueString = new bytes(inputBytes.length - delimiterIndex - 1);

        uint256 startValueString = 0;
        for (uint256 i = (delimiterIndex + 1); i < inputBytes.length; i++) {
            valueString[startValueString] = inputBytes[i];
            startValueString++;
        }

        parts[1] = string(valueString);

        return parts;
    }
    /// @notice Compares two strings for equality.
    /// @param a The first string.
    /// @param b The second string.
    /// @return Returns true if the strings are equal, false otherwise.
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }
    /// @notice URL encodes a string.
    /// @param input The input string to encode.
    /// @return output The URL-encoded string.
    function urlEncode(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        string memory output = "";

        for (uint256 i = 0; i < inputBytes.length; i++) {
            bytes memory spaceBytes = bytes(" ");
            if (inputBytes[i] == spaceBytes[0]) {
                output = string(
                    abi.encodePacked(
                        output,
                        "%",
                        bytes1(uint8(inputBytes[i]) / 16 + 48),
                        bytes1(uint8(inputBytes[i]) % 16 + 48)
                    )
                );
            }
            else {
                output = string(
                    abi.encodePacked(
                        output,
                        bytes1(inputBytes[i])
                    )
                );
            }
        }
        return output;
    }

    /// @dev Converts a bytes32 data to a bytes array.
    /// @param _data The input bytes32 data to convert.
    /// @return Returns the packed representation of the input data as a bytes array.
    function toBytes(bytes32 _data) public pure returns (bytes memory) {
        return abi.encodePacked(_data);
    }

    /// @dev Checks if a specific trip has intersecting trips within a given time range.
    //  @param TripService to getTrip by id
    /// @param tripId The ID of the trip to check.
    /// @param startDateTime The start date and time of the time range.
    /// @param endDateTime The end date and time of the time range.
    /// @return hasIntersectingTrips A boolean indicating whether the trip has intersecting trips within the specified time range.
    function isTripThatIntersect(
        RentalityTripService tripService,
        uint256 tripId,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal view returns (bool)
    {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        return
            (trip.endDateTime > startDateTime) &&
            (trip.startDateTime < endDateTime);

    }
    /// @dev Retrieves an array of trips that intersect with a given time range.
    //  @param TripService to getTrip by id
    /// @param startDateTime The start date and time of the time range.
    /// @param endDateTime The end date and time of the time range.
    /// @return intersectingTrips An array of trips that intersect with the specified time range.
    function getTripsThatIntersect(
        RentalityTripService tripService,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (RentalityTripService.Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isTripThatIntersect(tripService, currentId, startDateTime, endDateTime)
            ) {
                itemCount += 1;
            }
        }

        RentalityTripService.Trip[] memory result = new RentalityTripService.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isTripThatIntersect(tripService, currentId, startDateTime, endDateTime)
            ) {
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
        RentalityTripService tripService,
        uint256 tripId,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) private view returns (bool) {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        return
            (trip.carId == carId) &&
            (trip.endDateTime > startDateTime) &&
            (trip.startDateTime < endDateTime);
    }
///  @dev Checks if a specific car ID has intersecting trips within a given time range.
//  @param TripService to getTrip by id
///  @param carId The ID of the car to check.
///  @param startDateTime The start date and time of the time range.
///  @param endDateTime The end date and time of the time range.
///  @return trips An array of intersecting trips for the specified car within the specified time range.
    function getTripsForCarThatIntersect(
        RentalityTripService tripService,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (RentalityTripService.Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isCarThatIntersect(tripService, currentId, carId, startDateTime, endDateTime)
            ) {
                itemCount += 1;
            }
        }

        RentalityTripService.Trip[] memory result = new RentalityTripService.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isCarThatIntersect(tripService, currentId, carId, startDateTime, endDateTime)
            ) {
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
        RentalityTripService tripService,
        address guest
    ) public view returns (RentalityTripService.Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (tripService.getTrip(currentId).guest == guest) {
                itemCount += 1;
            }
        }

        RentalityTripService.Trip[] memory result = new RentalityTripService.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (tripService.getTrip(currentId).guest == guest) {
                RentalityTripService.Trip memory currentItem = tripService.getTrip(currentId);
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific host address.
    /// @param host The address of the host.
    /// @return trips An array of trips associated with the specified host.
    function getTripsByHost(RentalityTripService tripService, address host) public view returns (RentalityTripService.Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (tripService.getTrip(currentId).host == host) {
                itemCount += 1;
            }
        }

        RentalityTripService.Trip[] memory result = new RentalityTripService.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (tripService.getTrip(currentId).host == host) {
                RentalityTripService.Trip memory currentItem = tripService.getTrip(currentId);
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific car ID.
    /// @param carId The ID of the car.
    /// @return trips An array of trips associated with the specified car ID.
    function getTripsByCar(RentalityTripService tripService, uint256 carId) public view returns (RentalityTripService.Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (tripService.getTrip(currentId).carId == carId) {
                itemCount += 1;
            }
        }

        RentalityTripService.Trip[] memory result = new RentalityTripService.Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < tripService.totalTripCount(); i++) {
            uint currentId = i + 1;
            if (tripService.getTrip(currentId).carId == carId) {
                RentalityTripService.Trip memory currentItem = tripService.getTrip(currentId);
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    ///  @dev Calculates the resolved amount in USD cents for a trip.
    ///  @param tripInfo The information about the trip.
    /// @return Returns the resolved amounts for miles and fuel in USD cents as a tuple.
    function getResolveAmountInUsdCents(
        uint8 eType,
        RentalityTripService.Trip memory tripInfo,
        RentalityEnginesService engineService
    ) public view returns (uint64, uint64) {
        uint64 tripDays = getCeilDays(tripInfo.startDateTime, tripInfo.endDateTime);

        return
            engineService.getResolveAmountInUsdCents(
            eType,
            tripInfo.fuelPrices,
            tripInfo.startParamLevels,
            tripInfo.endParamLevels,
            tripInfo.carId,
            tripInfo.milesIncludedPerDay,
            tripInfo.pricePerDayInUsdCents,
            tripDays

        );
    }
}