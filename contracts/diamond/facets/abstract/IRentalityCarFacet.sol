
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Schemas} from '../../../Schemas.sol';

interface IRentalityCarTokenFacet {
    function totalSupply() external view returns (uint);

    function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);

    function isUniqueVinNumber(string memory carVinNumber) external view returns (bool);

    function addCar(Schemas.CreateCarRequest memory request, address user) external returns (uint);

    function updateCarInfoWithLocation(
        Schemas.UpdateCarInfoRequest memory request,
        Schemas.SignedLocationInfo memory location
    ) external;

    function getListingMoment(uint carId) external view returns (uint);

    function updateCarTokenUri(uint256 carId, string memory tokenUri, address user) external;

    function burnCar(uint256 carId) external;
}