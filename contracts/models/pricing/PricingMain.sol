// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/pricing/PricingBase.sol';
import '../profile/UserProfileTypes.sol';
import '../common/CommonTypes.sol';
import './PricingTypes.sol';
import './PricingMainFacet1.sol';

interface IPricingAccess {
    function isAdmin(address user) external view returns (bool);
    function isRentalityPlatform(address user) external view returns (bool);
    function isHost(address user) external view returns (bool);
    function manageRole(UserProfileRole newRole, address user, bool grant) external;
}

contract PricingMain is PricingBase, UUPSOwnable {
    IPricingAccess public userAccess;
    PricingMainFacet1 public pricingMainFacet1;

    error OnlyAdmin();
    error OnlyPlatform();

    event PlatformFeeUpdated(uint32 valueInPPM);
    event PricingFacetUpdated(address indexed pricingMainFacet1Address);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyAdmin() {
        if (address(userAccess) == address(0) || !(userAccess.isAdmin(msg.sender) || userAccess.isAdmin(tx.origin))) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyPlatform() {
        if (address(userAccess) == address(0) || !userAccess.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    function initialize(
        address userAccessAddress,
        address pricingMainFacet1Address
    ) public initializer {
        __Ownable_init();

        userAccess = IPricingAccess(userAccessAddress);
        pricingMainFacet1 = PricingMainFacet1(pricingMainFacet1Address);
        _setPlatformFeeInPPM(200_000);
    }

    function setPlatformFeeInPPM(uint32 valueInPPM) external onlyAdmin {
        _setPlatformFeeInPPM(valueInPPM);
        emit PlatformFeeUpdated(valueInPPM);
    }

    function setDefaultDiscount(PricingBaseDiscount memory data) external onlyAdmin {
        pricingMainFacet1.setDefaultDiscount(data);
    }

    function addBaseDiscount(address user, PricingBaseDiscount memory data) external onlyPlatform {
        if (!userAccess.isHost(user)) {
            userAccess.manageRole(UserProfileRole.Host, user, true);
        }

        pricingMainFacet1.addBaseDiscount(user, data);
    }

    function getBaseDiscount(address user) public view returns (PricingBaseDiscount memory) {
        return pricingMainFacet1.getBaseDiscount(user);
    }

    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
        return pricingMainFacet1.calculateSumWithDiscount(user, daysOfTrip, value);
    }

    function setDefaultDiscountToFalse() external onlyAdmin {
        pricingMainFacet1.setDefaultDiscountToFalse();
    }

    function addTaxes(
        string memory location,
        PricingTaxesLocationType locationType,
        PricingTaxValue[] memory taxValues
    ) external onlyAdmin returns (uint256) {
        return pricingMainFacet1.addTaxes(location, locationType, taxValues);
    }

    function setDefaultTax(uint256 taxId) external onlyAdmin {
        pricingMainFacet1.setDefaultTax(taxId);
    }

    function defineTaxesType(address carServiceAddress, uint256 carId) public view returns (uint256) {
        return pricingMainFacet1.defineTaxesType(carServiceAddress, carId);
    }

    function calculateAndSaveTaxes(uint256 taxId, uint64 daysOfTrip, uint64 value, uint256 tripId)
        external
        onlyPlatform
        returns (uint64)
    {
        return pricingMainFacet1.calculateAndSaveTaxes(taxId, daysOfTrip, value, tripId);
    }

    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64) {
        return pricingMainFacet1.calculateTaxes(taxId, tripDays, totalCost);
    }

    function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
        external
        view
        returns (uint64 totalTax, PricingTaxValue[] memory taxValues)
    {
        return pricingMainFacet1.calculateTaxesDTO(taxId, tripDays, totalCost);
    }

    function getTripTaxesDTO(uint256 tripId) external view returns (PricingTaxValue[] memory) {
        return pricingMainFacet1.getTripTaxesDTO(tripId);
    }

    function getTotalTripTax(uint256 tripId) external view returns (uint64) {
        return pricingMainFacet1.getTotalTripTax(tripId);
    }

    function getTaxesInfoById(uint256 taxId) external view returns (PricingTaxesInfo memory) {
        return pricingMainFacet1.getTaxesInfoById(taxId);
    }

    function taxExist(LocationInfo memory locationInfo) external view returns (uint256) {
        return pricingMainFacet1.taxExist(locationInfo);
    }

    function setTaxLocations(uint256[] memory taxes, string[] memory locations) external onlyAdmin {
        pricingMainFacet1.setTaxLocations(taxes, locations);
    }

    function setTaxesLocations(uint256[] memory taxIds, string[] memory locations) external onlyAdmin {
        pricingMainFacet1.setTaxesLocations(taxIds, locations);
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = IPricingAccess(userAccessAddress);
    }

    function updatePricingMainFacet1(address pricingMainFacet1Address) external onlyOwner {
        pricingMainFacet1 = PricingMainFacet1(pricingMainFacet1Address);
        emit PricingFacetUpdated(pricingMainFacet1Address);
    }

}



