// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../RentalityUserService.sol";

abstract contract ARentalityEngine {

    error WrongEngineArgs();
    error EngineParamsNotMatch();

    RentalityUserService internal userService;
    uint8 internal eType;

    modifier onlyManager()
    {
        require(userService.isManager(msg.sender), "Only for Manager.");
        _;
    }

    function setEType(uint8 _eType) public virtual;

    function addCar(uint256 carId, uint64[] memory params) public virtual;

    function updateCar(uint256 carId, uint64[] memory params) public virtual;

    function burnCar(uint256 carId) public virtual;

    function extraCosts(uint64[] memory params) public virtual returns (uint64);

    function getResolveAmountInUsdCents(
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint256 carId,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public virtual returns (uint64, uint64);

    function getEType() public view returns(uint8) {
        return eType;
    }

    function getDrivenMilesResolveAmountInUsdCents(
        uint64 startOdometr,
        uint64 endOdometr,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public virtual pure returns (uint64) {
        if (
            endOdometr - startOdometr
            <= milesIncludedPerDay * tripDays)
            return 0;

        return
            ((endOdometr - startOdometr - milesIncludedPerDay * tripDays) *
                pricePerDayInUsdCents) / milesIncludedPerDay;
    }


    function verifyResourcePrice(uint64[] memory prices) public pure virtual {
        isCorrectArgs(prices[0] != 0);
    }

    // @param  start fuel level in percents;
    // @param  start Odometr;
    function verifyStartParams(uint64[] memory params) public virtual {
        isCorrectArgs(params.length == getParamsAmount() &&
        (params[0] >= 0 && params[0] <= 100));

    }

    // @param  start fuel level in Gallon;
    // @param  start Odometr;
    function verifyEndParams(uint64[] memory startParams, uint64[] memory endParams) public virtual
    {
        isCorrectArgs(startParams.length == getParamsAmount() &&
        endParams.length == getParamsAmount());

        isCorrectArgs(endParams[0] >= 0 && endParams[0] <= 100);

        uint64 startOdometr = startParams[1];
        uint64 endOdometr = endParams[1];

        require(endOdometr >= startOdometr, "End odometr can not be less.");
    }


    function compareParams(uint64[] memory start, uint64[] memory end) public pure
    {
        isMatch(start.length == end.length);

        for (uint256 i = 0; i < start.length; i++)
        {
            isMatch(start[0] == end[0]);
        }
    }
    function getParamsAmount() public virtual returns (uint256)
    {
        return 2;
    }



    function isCorrectArgs(bool eq) internal pure {
        if (!eq)
        {
            revert WrongEngineArgs();
        }

    }

    function isMatch(bool eq) internal pure {
        if (!eq)
        {
            revert EngineParamsNotMatch();
        }

    }
}

