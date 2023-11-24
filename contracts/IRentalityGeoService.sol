// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IRentalityGeoService {
    function executeRequest(string memory addr, string memory key, uint256 carId) external returns (bytes32);
    function getCarCoordinateValidity(uint256 carId) external view returns (bool);
    function getCarCity(uint256 carId) external view returns (string memory);
    function getCarState(uint256 carId) external view returns (string memory);
    function getCarCountry(uint256 carId) external view returns (string memory);
}