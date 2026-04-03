// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/asset/AssetTypes.sol";
import "./CarTypes.sol";

interface ICarMain {
    function exists(uint256 id) external view returns (bool);
    function getAsset(uint256 id) external view returns (Asset memory);
    function getCarData(uint256 id) external view returns (CarData memory);
    function totalSupply() external view returns (uint256);
    function getListingMoment(uint256 id) external view returns (uint256);
    function getGeoVerifierAddress() external view returns (address);
    function getEngineValidatorAddress() external view returns (address);
}

contract CarQuery {
    ICarMain public immutable carMain;

    constructor(address carMainAddress) {
        carMain = ICarMain(carMainAddress);
    }

    function getCar(uint256 id) external view returns (CarInfo memory) {
        return CarInfo({asset: carMain.getAsset(id), car: carMain.getCarData(id)});
    }

    function getCarData(uint256 id) external view returns (CarData memory) {
        return carMain.getCarData(id);
    }

    function totalSupply() external view returns (uint256) {
        return carMain.totalSupply();
    }

    function getGeoVerifierAddress() external view returns (address) {
        return carMain.getGeoVerifierAddress();
    }

    function getEngineValidatorAddress() external view returns (address) {
        return carMain.getEngineValidatorAddress();
    }

    function getListingMoment(uint256 id) external view returns (uint256) {
        return carMain.getListingMoment(id);
    }

    function getAllCars() external view returns (CarInfo[] memory) {
        return _collectCars(address(0), false, false);
    }

    function getCarsOfOwner(address owner) external view returns (CarInfo[] memory) {
        return _collectCars(owner, true, false);
    }

    function getAvailableCarsForUser(address user) external view returns (CarInfo[] memory) {
        return _collectCars(user, false, true);
    }

    function _collectCars(
        address user,
        bool onlyOwnerCars,
        bool onlyAvailableForUser
    ) internal view returns (CarInfo[] memory) {
        uint256 supply = carMain.totalSupply();
        uint256 count;

        for (uint256 i = 1; i <= supply; i++) {
            if (!carMain.exists(i)) {
                continue;
            }

            Asset memory asset = carMain.getAsset(i);
            CarData memory car = carMain.getCarData(i);

            if (onlyOwnerCars && asset.owner != user) {
                continue;
            }

            if (onlyAvailableForUser && (!car.currentlyListed || asset.owner == user)) {
                continue;
            }

            count++;
        }

        CarInfo[] memory result = new CarInfo[](count);
        uint256 index;

        for (uint256 i = 1; i <= supply; i++) {
            if (!carMain.exists(i)) {
                continue;
            }

            Asset memory asset = carMain.getAsset(i);
            CarData memory car = carMain.getCarData(i);

            if (onlyOwnerCars && asset.owner != user) {
                continue;
            }

            if (onlyAvailableForUser && (!car.currentlyListed || asset.owner == user)) {
                continue;
            }

            result[index++] = CarInfo({asset: asset, car: car});
        }

        return result;
    }
}



