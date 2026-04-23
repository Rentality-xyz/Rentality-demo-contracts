// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../common/CommonTypes.sol';
import './PricingMain.sol';
import './PricingTypes.sol';

contract PricingQuery {
    PricingMain public immutable pricingMain;

    constructor(address pricingMainAddress) {
        pricingMain = PricingMain(pricingMainAddress);
    }

    function getPlatformFeeInPPM() external view returns (uint32) {
        return pricingMain.getPlatformFeeInPPM();
    }

    function getPlatformFeeFrom(uint256 value) external view returns (uint256) {
        return pricingMain.getPlatformFeeFrom(value);
    }

    function getBaseDiscount(address user) external view returns (PricingBaseDiscount memory) {
        return pricingMain.getBaseDiscount(user);
    }

    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64) {
        return pricingMain.calculateSumWithDiscount(user, daysOfTrip, value);
    }

    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64) {
        return pricingMain.calculateTaxes(taxId, tripDays, totalCost);
    }

    function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
        external
        view
        returns (uint64 totalTax, PricingTaxValue[] memory taxes)
    {
        return pricingMain.calculateTaxesDTO(taxId, tripDays, totalCost);
    }

    function getTripTaxesDTO(uint256 tripId) external view returns (PricingTaxValue[] memory) {
        return pricingMain.getTripTaxesDTO(tripId);
    }

    function getTotalTripTax(uint256 tripId) external view returns (uint64) {
        return pricingMain.getTotalTripTax(tripId);
    }

    function getTaxesInfoById(uint256 taxId) external view returns (PricingTaxesInfo memory) {
        return pricingMain.getTaxesInfoById(taxId);
    }

    function defineTaxesType(address carServiceAddress, uint256 carId) external view returns (uint256) {
        return pricingMain.defineTaxesType(carServiceAddress, carId);
    }

    function taxExist(LocationInfo memory locationInfo) external view returns (uint256) {
        return pricingMain.taxExist(locationInfo);
    }
}
