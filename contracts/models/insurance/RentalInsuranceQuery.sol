// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './RentalInsuranceMain.sol';

contract RentalInsuranceQuery {
    RentalInsuranceMain public immutable rentalInsuranceMain;

    constructor(address rentalInsuranceMainAddress) {
        rentalInsuranceMain = RentalInsuranceMain(payable(rentalInsuranceMainAddress));
    }

    function getInsuranceRequirement(uint256 carId) external view returns (InsuranceRequirement memory) {
        return rentalInsuranceMain.getInsuranceRequirement(carId);
    }

    function getGuestInsurances(address user) external view returns (InsuranceInfo[] memory) {
        return rentalInsuranceMain.getGuestInsurances(user);
    }

    function getInsurancePriceByCar(uint256 carId) external view returns (uint256) {
        return rentalInsuranceMain.getInsurancePriceByCar(carId);
    }

    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256) {
        return rentalInsuranceMain.getInsurancePriceByTrip(tripId);
    }

    function getTripInsurances(uint256 tripId) external view returns (InsuranceInfo[] memory) {
        return rentalInsuranceMain.getTripInsurances(tripId);
    }

    function isGuestHasInsurance(address guest) external view returns (bool) {
        return rentalInsuranceMain.isGuestHasInsurance(guest);
    }

    function calculateInsuranceForTrip(
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime,
        address user
    ) external view returns (uint256) {
        return rentalInsuranceMain.calculateInsuranceForTrip(carId, startDateTime, endDateTime, user);
    }

    function getAllInsuranceRules() external view returns (InsuranceRule[] memory) {
        return rentalInsuranceMain.getAllInsuranceRules();
    }

    function getHostInsuranceRule(address host) external view returns (InsuranceRule memory) {
        return rentalInsuranceMain.getHostInsuranceRule(host);
    }

    function isInsuranceClaim(uint256 claimId) external view returns (bool) {
        return rentalInsuranceMain.isInsuranceClaim(claimId);
    }

    function getInsuranceClaims() external view returns (uint256[] memory) {
        return rentalInsuranceMain.getInsuranceClaims();
    }

    function getPaidToInsuranceByTripId(uint256 tripId) external view returns (uint256) {
        return rentalInsuranceMain.getPaidToInsuranceByTripId(tripId);
    }
}

