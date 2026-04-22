// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../common/CommonTypes.sol';
import './RentalPricingMain.sol';
import './RentalPricingTypes.sol';

contract RentalPricingQuery {
    RentalPricingMain public immutable rentalPricingMain;

    constructor(address rentalPricingMainAddress) {
        rentalPricingMain = RentalPricingMain(rentalPricingMainAddress);
    }

    function getPlatformFeeInPPM() external view returns (uint32) {
        return rentalPricingMain.getPlatformFeeInPPM();
    }

    function getPlatformFeeFrom(uint256 value) external view returns (uint256) {
        return rentalPricingMain.getPlatformFeeFrom(value);
    }

    function getBaseDiscount(address user) external view returns (RentalBaseDiscount memory) {
        return rentalPricingMain.getBaseDiscount(user);
    }

    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64) {
        return rentalPricingMain.calculateSumWithDiscount(user, daysOfTrip, value);
    }

    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64) {
        return rentalPricingMain.calculateTaxes(taxId, tripDays, totalCost);
    }

    function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
        external
        view
        returns (uint64 totalTax, RentalTaxValue[] memory taxes)
    {
        return rentalPricingMain.calculateTaxesDTO(taxId, tripDays, totalCost);
    }

    function getTripTaxesDTO(uint256 tripId) external view returns (RentalTaxValue[] memory) {
        return rentalPricingMain.getTripTaxesDTO(tripId);
    }

    function getTotalTripTax(uint256 tripId) external view returns (uint64) {
        return rentalPricingMain.getTotalTripTax(tripId);
    }

    function getTaxesInfoById(uint256 taxId) external view returns (RentalTaxesInfo memory) {
        return rentalPricingMain.getTaxesInfoById(taxId);
    }

    function defineTaxesType(address carServiceAddress, uint256 carId) external view returns (uint256) {
        return rentalPricingMain.defineTaxesType(carServiceAddress, carId);
    }

    function taxExist(LocationInfo memory locationInfo) external view returns (uint256) {
        return rentalPricingMain.taxExist(locationInfo);
    }
}
