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
    function getEType() public view returns(uint8) {
        return eType;
        }

    function setEType(uint8 _eType) public virtual;

    function addCar(uint256 carId, uint64[] memory params) public virtual;

    function updateCar(uint256 carId, uint64[] memory params) public virtual;

    function burnCar(uint256 carId) public virtual;

    function varifyFuelPrices(uint64[] memory prices) public virtual;

    function varifyStartParams(uint64[] memory params) public virtual;

    function varifyEndParams(uint64[] memory startParams, uint64[] memory endParams) public virtual;

    function calculateFuellevels(uint64[] memory fuelParams, uint256 carId) public virtual returns (uint64[] memory);

    function compareParams(uint64[] memory start, uint64[] memory end) public pure
    {
        isMatch(start.length == end.length);

        for (uint256 i = 0; i < start.length; i++)
        {
            isMatch(start[0] == end[0]);
        }
    }

    function getParamsAmount() public virtual returns (uint256);

    function extraCosts(uint64[] memory params) public virtual returns (uint64);

    function getResolveAmountInUsdCents(
        uint64[] memory fuelPrices,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays) public virtual returns (uint64, uint64);

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

