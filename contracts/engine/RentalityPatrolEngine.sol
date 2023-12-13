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
    function setEType(uint8 _eType) public override onlyManager {
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

    // @param prices[0] patrol price per gallon In Usd Cents
    function varifyFuelPrices(uint64[] memory prices) public pure override {
        isCorrectArgs(prices[0] != 0);
    }

    // @param  start fuel level in Gallon;
    // @param  start Odometr;
    function varifyStartParams(uint64[] memory params) public pure override {
        isCorrectArgs(params.length == getParamsAmount());

    }

    function calculateFuellevels(uint64[] memory fuelParams, uint256 carId) public override returns(uint64[] memory) {
        uint64 startFuelLevelInGal = (carIdToPatrolEngine[carId].tankVolumeInGal *
            fuelParams[0]) / 1000;
        fuelParams[0] = startFuelLevelInGal;
        return fuelParams;
    }

    // @param  start fuel level in Gallon;
    // @param  start Odometr;
    function varifyEndParams(uint64[] memory startParams, uint64[] memory endParams) public pure override
    {
        isCorrectArgs(startParams.length == getParamsAmount() && endParams.length == getParamsAmount());
        uint64 endOdometr = endParams[0];
        uint64 startOdometr = startParams[0];

        require(endOdometr >= startOdometr, "End odometr can not be less.");

    }

    function getParamsAmount() public pure override returns(uint256) {
        return 2;

    }

    function extraCosts(uint64[] memory params) public pure override returns (uint64) {
        return 0;
    }

    function getResolveAmountInUsdCents(
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public pure override returns (uint64, uint64)
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
            fuelPrices[0]
        ));
    }

    function getDrivenMilesResolveAmountInUsdCents(
        uint64 startOdometr,
        uint64 endOdometr,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public pure returns (uint64) {
        if (
            endOdometr - startOdometr
            <= milesIncludedPerDay * tripDays)
            return 0;

        return
            ((endOdometr - startOdometr - milesIncludedPerDay * tripDays) *
                pricePerDayInUsdCents) / milesIncludedPerDay;
    }

    function getFuelResolveAmountInUsdCents(
        uint64 endFuelLevelInGal,
        uint64 startFuelLevelInGal,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64) {
        if (endFuelLevelInGal >= startFuelLevelInGal) return 0;

        return
            (startFuelLevelInGal - endFuelLevelInGal) *
            fuelPricePerGalInUsdCents;
    }

}