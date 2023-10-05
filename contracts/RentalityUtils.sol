// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityCarToken.sol";
import "./IRentalityGateway.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import './RentalityGeoService.sol';

library RentalityUtils {

    uint256 constant multiplier = 10**7;

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
            return -mint * int256(multiplier); 
        }
        return mint * int256(multiplier); 
    }


    function indexOf(bytes memory haystack, string memory needle) internal pure returns (uint) {
        bytes memory bneedle = bytes(needle);
        if(bneedle.length > haystack.length) {
            return haystack.length;
        }

        bool found = false;
        uint i;
        for(i = 0; i <= haystack.length - bneedle.length; i++) {
            found = true;
            for(uint j = 0; j < bneedle.length; j++) {
                if(haystack[i+j] != bneedle[j]) {
                    found = false;
                    break;
                }
            }
            if(found) {
                break;
            }
        }
        return i;
    }

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

    function containWord(
        string memory where,
        string memory what
    ) internal pure returns (bool found) {
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);

        //require(whereBytes.length >= whatBytes.length);
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

    function getHashFromString(
        string memory str
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    function getCeilDays(uint64 startDateTime, uint64 endDateTime) public pure returns (uint64) {
        uint64 duration = endDateTime - startDateTime;
        return uint64(Math.ceilDiv(duration, 1 days));
    }

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
        }

        return chatInfoList;
    }

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

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }

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
}
