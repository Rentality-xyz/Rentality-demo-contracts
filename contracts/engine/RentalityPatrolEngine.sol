// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./ARentalityEngine.sol";

contract RentalityPatrolEngine is ARentalityEngine
{

    struct PatrolEngine
    {
        uint64 tankVolumeInGal;
        uint64 fuelPricePerGalInUsdCents;
    }

    mapping(uint256 => PatrolEngine) private carIdToPatrolEngine;

    constructor(address _userService)
    {
        userService = RentalityUserService(_userService);
    }
    function setEType(uint8 _eType) public override {
        require(userService.isAdmin(tx.origin), "only Admin.");
        eType = _eType;
    }

    function addCar(uint256 carId, uint64[] memory params) public override onlyManager
    {
        isCorrectArgs((params[0] != 0 && params[1] != 0));

        PatrolEngine storage engine = carIdToPatrolEngine[carId];
        engine.tankVolumeInGal = params[0];
        engine.fuelPricePerGalInUsdCents = params[1];
    }

// @param params[0] fuelPricePerGalInUsdCents
    function updateCar(uint256 carId, uint64[] memory params) public override onlyManager
    {
        isCorrectArgs(params[0] != 0);
        carIdToPatrolEngine[carId].fuelPricePerGalInUsdCents = params[0];

    }

    function burnCar(uint256 carId) public override onlyManager
    {
        delete carIdToPatrolEngine[carId];
    }

    function extraCosts(uint64[] memory params) public pure override returns (uint64) {
        return 0;
    }

    function getEngineData(uint256 carId) public view returns(PatrolEngine memory) {
        return carIdToPatrolEngine[carId];
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
            startParams[0],
            carIdToPatrolEngine[carId].tankVolumeInGal,
            fuelPrices[0]
        ));
    }

    function getFuelResolveAmountInUsdCents(
        uint64 endFuelLevelInPercents,
        uint64 startFuelLevelInPercents,
        uint64 tankVolume,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64) {
        if (endFuelLevelInPercents >= startFuelLevelInPercents) return 0;

        return
            (((startFuelLevelInPercents - endFuelLevelInPercents) * tankVolume ) * 1000 / 100)
            * fuelPricePerGalInUsdCents / 1000;
    }

}