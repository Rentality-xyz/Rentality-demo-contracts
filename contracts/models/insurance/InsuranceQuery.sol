// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './InsuranceMain.sol';

contract InsuranceQuery {
    InsuranceMain public immutable insuranceMain;

    constructor(address insuranceMainAddress) {
        insuranceMain = InsuranceMain(payable(insuranceMainAddress));
    }

    function getInsuranceRequirement(uint256 carId) external view returns (InsuranceRequirement memory) {
        return insuranceMain.getInsuranceRequirement(carId);
    }

    function getGuestInsurances(address user) external view returns (InsuranceInfo[] memory) {
        return insuranceMain.getGuestInsurances(user);
    }

    function getInsurancePriceByCar(uint256 carId) external view returns (uint256) {
        return insuranceMain.getInsurancePriceByCar(carId);
    }

    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256) {
        return insuranceMain.getInsurancePriceByTrip(tripId);
    }

    function getTripInsurances(uint256 tripId) external view returns (InsuranceInfo[] memory) {
        return insuranceMain.getTripInsurances(tripId);
    }

    function isGuestHasInsurance(address guest) external view returns (bool) {
        return insuranceMain.isGuestHasInsurance(guest);
    }

    function calculateInsuranceForTrip(
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime,
        address user
    ) external view returns (uint256) {
        return insuranceMain.calculateInsuranceForTrip(carId, startDateTime, endDateTime, user);
    }

    function getAllInsuranceRules() external view returns (InsuranceRule[] memory) {
        return insuranceMain.getAllInsuranceRules();
    }

    function getHostInsuranceRule(address host) external view returns (InsuranceRule memory) {
        return insuranceMain.getHostInsuranceRule(host);
    }

    function isInsuranceClaim(uint256 claimId) external view returns (bool) {
        return insuranceMain.isInsuranceClaim(claimId);
    }

    function getInsuranceClaims() external view returns (uint256[] memory) {
        return insuranceMain.getInsuranceClaims();
    }

    function getPaidToInsuranceByTripId(uint256 tripId) external view returns (uint256) {
        return insuranceMain.getPaidToInsuranceByTripId(tripId);
    }
}

