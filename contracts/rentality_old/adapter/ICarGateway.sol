// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Schemas.sol";

interface ICarGateway {
    function updateEventServiceAddress(address eventEmitterAddress) external;
    function updateEngineServiceAddress(address engineValidatorAddress) external;
    function getGeoServiceAddress() external view returns (address);
    function tokenURI(uint256 carId) external view returns (string memory);
    function updateGeoServiceAddress(address geoVerifierAddress) external;
    function getEngineService() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory);
    function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);
    function isUniqueVinNumber(string memory carVinNumber) external view returns (bool);
    function addCar(Schemas.CreateCarRequest memory request, address user) external returns (uint256);
    function updateCarInfo(
        Schemas.UpdateCarInfoRequest memory request,
        Schemas.LocationInfo memory location,
        bool updateLocation,
        address user
    ) external;
    function getListingMoment(uint256 carId) external view returns (uint256);
    function updateCarTokenUri(uint256 carId, string memory tokenUri, address user) external;
    function burnCar(uint256 carId) external;
    function getAllCars() external view returns (Schemas.CarInfo[] memory);
    function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);
    function isCarAvailableForUser(
        uint256 carId,
        address sender,
        Schemas.SearchCarParams memory searchCarParams
    ) external view returns (bool);
    function fetchAvailableCarsForUser(
        address user,
        Schemas.SearchCarParams memory searchCarParams,
        uint256 from,
        uint256 to
    ) external view returns (Schemas.CarInfo[] memory);
    function ownerOf(uint256 carId) external view returns (address);
    function exists(uint256 carId) external view returns (bool);
    function getCarsOwnedByUser(address user) external view returns (Schemas.CarInfo[] memory);
    function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) external view;
    function balanceOf(address owner) external view returns (uint256);
}


