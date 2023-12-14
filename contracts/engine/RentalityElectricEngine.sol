// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ARentalityEngine.sol";


contract RentalityElectricEngine is ARentalityEngine {

    struct ChargePriceScaleInUsdCents
    {
        uint64 fromEmptyToTwenty;
        uint64 fromTwentyOneToFifteen;
        uint64 fromFifteenToOneEighteen;
        uint64 fromEighteenToOneHundred;
    }

    mapping(uint256 => ChargePriceScaleInUsdCents) private carIdToElectricEngine;

    constructor(address _userService) {
        userService = RentalityUserService(_userService);
    }

    function setEType(uint8 _eType) public override onlyManager {
        require(userService.isAdmin(tx.origin), "Only Admin.");
        eType = _eType;
    }

    function addCar(uint256 carId, uint64[] memory params) public override onlyManager {
        isCorrectArgs(params.length == 4);

        ChargePriceScaleInUsdCents storage engine = carIdToElectricEngine[carId];
        engine.fromEmptyToTwenty = params[0];
        engine.fromTwentyOneToFifteen = params[1];
        engine.fromFifteenToOneEighteen = params[2];
        engine.fromEighteenToOneHundred = params[3];
    }

    function updateCar(uint256 carId, uint64[] memory params) public override onlyManager {
        isCorrectArgs(params.length == 4);

        carIdToElectricEngine[carId].fromEmptyToTwenty = params[0];
        carIdToElectricEngine[carId].fromTwentyOneToFifteen = params[1];
        carIdToElectricEngine[carId].fromFifteenToOneEighteen = params[2];
        carIdToElectricEngine[carId].fromEighteenToOneHundred = params[3];
    }

    function burnCar(uint256 carId) public override onlyManager {
        delete carIdToElectricEngine[carId];
    }


    function extraCosts(uint64[] memory params) public pure override returns (uint64) {
        return 0;
    }

    function getResolveAmountInUsdCents(
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint256 carId,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public view override returns (uint64, uint64)
    {
        return (
            getDrivenMilesResolveAmountInUsdCents(
            startParams[1],
            endParams[1],
            milesIncludedPerDay,
            pricePerDayInUsdCents,
            tripDays
        ),

            getFuelResolveAmountInUsdCents(
            endParams[0],
            carId
        ));
    }


    function getFuelResolveAmountInUsdCents(
        uint64 endFuelLevelInPercents,
        uint256 carId
    ) public view returns (uint64) {
        if (endFuelLevelInPercents >= 0 && endFuelLevelInPercents <= 20)
        {
            return carIdToElectricEngine[carId].fromEmptyToTwenty;
        }
        else if (endFuelLevelInPercents >= 21 && endFuelLevelInPercents <= 50)
        {
            return carIdToElectricEngine[carId].fromTwentyOneToFifteen;
        }
        else if (endFuelLevelInPercents >= 51 && endFuelLevelInPercents <= 80)
        {
            return carIdToElectricEngine[carId].fromFifteenToOneEighteen;
        }

        return carIdToElectricEngine[carId].fromEighteenToOneHundred;

    }

}