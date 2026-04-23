// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../upgradeable/UUPSOwnable.sol';

contract RentalityEnginesService is UUPSOwnable {
  constructor() {
    _disableInitializers();
  }

  function initialize(address /*userAccessAddress*/, address[] memory /*engineServices*/) public initializer {
    __Ownable_init();
  }

  function verifyCreateParams(uint8 /*eType*/, uint64[] memory params) public pure {
    require(params.length > 0, 'Engine params required');
  }

  function verifyStartParams(uint64[] memory params, uint8 /*eType*/) public pure {
    require(params.length > 0, 'Start params required');
  }

  function verifyEndParams(uint64[] memory startParams, uint64[] memory endParams, uint8 /*eType*/) public pure {
    require(startParams.length == endParams.length, 'Wrong engine params length');
  }

  function compareParams(uint64[] memory startParams, uint64[] memory endParams, uint8 /*eType*/) public pure {
    require(startParams.length == endParams.length, 'Wrong engine params length');
  }

  function getPanelParamsAmount(uint8 /*eType*/) public pure returns (uint256) {
    return 2;
  }

  function getFuelPriceFromEngineParams(uint8 /*eType*/, uint64[] memory /*engineParams*/) public pure returns (uint64) {
    return 0;
  }

  function getResolveAmountInUsdCents(
    uint8 /*engineType*/,
    uint64 /*fuelPrice*/,
    uint64[] memory /*startParams*/,
    uint64[] memory /*endParams*/,
    uint64[] memory /*engineParams*/,
    uint64 /*milesIncludedPerDay*/,
    uint64 /*pricePerDayInUsdCents*/,
    uint64 /*tripDays*/
  ) public pure returns (uint64, uint64) {
    return (0, 0);
  }
}
