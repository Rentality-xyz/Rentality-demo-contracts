// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARentalityEngine.sol";
import "../RentalityUserService.sol";

contract RentalityEnginesService
{
    RentalityUserService private userService;
    uint8 private eTypeCounter = 1;
    mapping(uint8 => ARentalityEngine) private engineTypeToEngineContract;

    error Overflow();

    constructor(address[] memory engineServices) {
        if (engineServices.length >= type(uint8).max - 1)
        {
            revert Overflow();
        }

        for (uint256 i = 0; i < engineServices.length; i++) {
            engineTypeToEngineContract[eTypeCounter] = ARentalityEngine(engineServices[i]);
            engineTypeToEngineContract[eTypeCounter].setEType(eTypeCounter);
            eTypeCounter += 1;
        }
    }
    modifier onlyAdmin()
    {
        require(userService.isAdmin(msg.sender),"Only for Admin.");
        _;
    }
    modifier onlyManager()
    {
        require(userService.isManager(msg.sender),"Only for Manager.");
        _;
    }
    function addEngineService(address engineService) public onlyAdmin {
        if (eTypeCounter == type(uint8).max - 1)
        {
            revert Overflow();
        }
        engineTypeToEngineContract[eTypeCounter] = ARentalityEngine(engineService);
        engineTypeToEngineContract[eTypeCounter].setEType(eTypeCounter);
        eTypeCounter += 1;
    }

    function updateEngineService(address engineService, uint8 eType) public onlyAdmin{
        engineTypeToEngineContract[eType] = ARentalityEngine(engineService);
    }

    function getEngineAddressById(uint8 eType) public view returns (address) {
        return address (engineTypeToEngineContract[eType]);
    }


    function addCar(uint256 carId, uint8 eType, uint64[] memory params) public onlyManager
    {
        engineTypeToEngineContract[eType].addCar(carId, params);
    }

    function updateCar(uint256 carId, uint8 eType, uint64[] memory params) public onlyManager
    {
        engineTypeToEngineContract[eType].updateCar(carId, params);
    }

    function burnCar(uint256 carId, uint8 eType) public onlyManager
    {
        engineTypeToEngineContract[eType].burnCar(carId);
    }

    function varifyFuelPrices(uint64[] memory prices, uint8 eType) public {
        engineTypeToEngineContract[eType].varifyFuelPrices(prices);
    }

    function varifyStartParams(uint64[] memory params, uint8 eType) public {
        engineTypeToEngineContract[eType].varifyStartParams(params);
    }
    function calculateFuellevels(uint64[] memory fuelParams,uint8 eType, uint256 carId) public returns(uint64[] memory)
    {
        return engineTypeToEngineContract[eType].calculateFuellevels(fuelParams, carId);
    }

    function varifyEndParams(uint64[] memory startParams, uint64[] memory endParams, uint8 eType) public
    {
        engineTypeToEngineContract[eType].varifyEndParams(startParams, endParams);

    }
    function compareParams(uint64[] memory startParams, uint64[] memory endParams, uint8 eType) public view
    {
        engineTypeToEngineContract[eType].compareParams(startParams, endParams);

    }

    function getPanelParamsAmount(uint8 eType) public returns (uint256) {
       return engineTypeToEngineContract[eType].getParamsAmount();

    }

    function extraCosts(uint8 eType, uint64[] memory params) public returns (uint64) {
        return engineTypeToEngineContract[eType].extraCosts(params);
    }


    function getResolveAmountInUsdCents(
        uint8 engineType,
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public returns (uint64, uint64)
    {
       return engineTypeToEngineContract[engineType].getResolveAmountInUsdCents(
        fuelPrices,
        startParams,
        endParams,
        milesIncludedPerDay,
        pricePerDayInUsdCents,
        tripDays);
    }


}