// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityCarToken.sol";
import "./IRentalityGateway.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library RentalityUtils {
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
}
