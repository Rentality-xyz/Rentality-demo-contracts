// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './InsuranceTypes.sol';

interface IInsurance {
    function getInsuranceRequirement(uint256 objectId) external view returns (InsuranceRequirement memory);
    function getInsurancePaidByBooking(uint256 bookingId) external view returns (uint256);
    function hasActiveGeneralInsurance(address user) external view returns (bool);
}
