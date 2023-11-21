// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// For testing purposes
contract RentalityGeoMock {

    mapping(uint256 => bool) private carCoordinateValidity;
    mapping(uint256 => string) private carCity;
    mapping(uint256 => string) private carState;
    mapping(uint256 => string) private carCountry;


    function setCarCoordinateValidity(uint256 carId, bool validity) external {
        carCoordinateValidity[carId] = validity;
    }

    function setCarCity(uint256 carId, string memory city) external {
        carCity[carId] = city;
    }

    function setCarState(uint256 carId, string memory state) external {
        carState[carId] = state;
    }

    function setCarCountry(uint256 carId, string memory country) external {
        carCountry[carId] = country;
    }

    function executeRequest(
        string memory addr,
        string memory key,
        uint256 carId
    ) external returns (bytes32) {
        // Mock implementation, you can add your own logic if needed
        return bytes32(carId);
    }

    function getCarCoordinateValidity(uint256 carId) external view returns (bool) {
        return carCoordinateValidity[carId];
    }

    function getCarCity(uint256 carId) external view returns (string memory) {
        return carCity[carId];
    }

    function getCarState(uint256 carId) external view returns (string memory) {
        return carState[carId];
    }

    function getCarCountry(uint256 carId) external view returns (string memory) {
        return carCountry[carId];
    }
}