// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../abstract/IRentalityAccessControl.sol';
import '../proxy/UUPSOwnable.sol';
import '../RentalityTripService.sol';
import './abstract/IRentalityDiscount.sol';
import './abstract/IRentalityTaxes.sol';

/// @title Rentality Payment Service Contract
/// @notice This contract manages platform fees and allows the adjustment of the platform fee by the manager.
/// @dev It is connected to RentalityUserService to check if the caller is an admin.
contract RentalityPaymentService is UUPSOwnable {
    uint32 platformFeeInPPM;
    IRentalityAccessControl private userService;

    mapping(address => IRentalityDiscount) private discountAddressToDiscountContract;
    mapping(uint => IRentalityTaxes) private taxesIdToTaxesContract;

    address private currentDiscount;
    uint private taxesId;
    uint private defaultTax;

    modifier onlyAdmin() {
        require(userService.isAdmin(tx.origin), 'Only admin.');
        _;
    }

    /// @notice Get the current platform fee in parts per million (PPM).
    /// @return The current platform fee in PPM.
    function getPlatformFeeInPPM() public view returns (uint32) {
        return platformFeeInPPM;
    }

    /// @notice Set the platform fee in parts per million (PPM).
    /// @param valueInPPM The new value for the platform fee in PPM.
    /// @dev Only callable by an admin. The value must be positive and not exceed 1,000,000.
    function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
        require(valueInPPM > 0, "Make sure the value isn't negative");
        require(valueInPPM <= 1_000_000, "Value can't be more than 1000000");

        platformFeeInPPM = valueInPPM;
    }

    /// @notice Get the platform fee from a given value.
    /// @param value The value from which to calculate the platform fee.
    /// @return The platform fee calculated from the given value.
    function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
        return (value * platformFeeInPPM) / 1_000_000;
    }

    /// @notice Calculates the total sum with discount for a given trip duration and value.
    /// @param daysOfTrip The duration of the trip in days.
    /// @param value The total value of the trip.
    /// @param user the address of discount provider
    /// @return The total sum with discount applied.
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
        return discountAddressToDiscountContract[currentDiscount].calculateSumWithDiscount(user, daysOfTrip, value);
    }

    function calculateSumWithDiscountInPPM(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
        return discountAddressToDiscountContract[currentDiscount].calculateSumWithDiscountInPMM(user, daysOfTrip, value);
    }

    /// @notice Calculates the taxes for a given tax ID, trip duration, and value.
    /// @param taxId The ID of the tax.
    /// @param daysOfTrip The duration of the trip in days.
    /// @param value The total value of the trip.
    /// @return The calculated taxes.
    function calculateTaxes(uint taxId, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
        return taxesIdToTaxesContract[taxId].calculateTaxes(daysOfTrip, value);
    }

    function calculateTaxesInPMM(uint taxId, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
        return taxesIdToTaxesContract[taxId].calculateTaxesInPMM(daysOfTrip, value);
    }

    /// @notice Defines the type of taxes based on the location of a car.
    /// @param carService The address of the car service contract.
    /// @param carId The ID of the car.
    /// @return The ID of the taxes contract corresponding to the location of the car.
    function defineTaxesType(address carService, uint carId) public view returns (uint) {
        IRentalityGeoService geoService = IRentalityGeoService(RentalityCarToken(carService).getGeoServiceAddress());
        bytes32 cityHash = keccak256(abi.encode(geoService.getCarCity(carId)));
        bytes32 stateHash = keccak256(abi.encode(geoService.getCarState(carId)));
        bytes32 countryHash = keccak256(abi.encode(geoService.getCarCountry(carId)));

        for (uint i = 1; i <= taxesId; i++) {
            IRentalityTaxes taxContract = taxesIdToTaxesContract[i];
            (bytes32 locationHash, Schemas.TaxesLocationType taxesLocationType) = taxContract.getLocation();

            if (taxesLocationType == Schemas.TaxesLocationType.City) {
                if (locationHash == cityHash) return i;
            }
            if (taxesLocationType == Schemas.TaxesLocationType.State) {
                if (locationHash == stateHash) return i;
            }
            if (taxesLocationType == Schemas.TaxesLocationType.Country) {
                if (locationHash == countryHash) return i;
            }
        }

        return defaultTax;
    }

    /// @notice Adds a user discount.
    /// @param data The discount data.
    function addUserDiscount(bytes memory data) public {
        require(userService.isHost(tx.origin), 'Only host.');
        discountAddressToDiscountContract[currentDiscount].addUserDiscount(data);
    }

    /// @notice Gets the discount for a specific user.
    /// @param userAddress The address of the user.
    /// @return The discount information for the user.
    function getDiscount(address userAddress) public view returns (bytes memory) {
        return discountAddressToDiscountContract[currentDiscount].getDiscount(userAddress);
    }

    /// @notice Adds a taxes contract to the system.
    /// @param taxesContactAddress The address of the taxes contract.
    function addTaxesContract(address taxesContactAddress) public onlyAdmin {
        taxesId += 1;
        taxesIdToTaxesContract[taxesId] = IRentalityTaxes(taxesContactAddress);
    }

    /// @notice Adds a discount contract to the system.
    /// @param discountContactAddress The address of the discount contract.
    function addDiscountContract(address discountContactAddress) public onlyAdmin {
        discountAddressToDiscountContract[discountContactAddress] = IRentalityDiscount(discountContactAddress);
    }

    /// @notice Changes the current discount type.
    /// @param discountContract The address of the new discount contract.
    function changeCurrentDiscountType(address discountContract) public onlyAdmin {
        require(address(discountAddressToDiscountContract[discountContract]) != address(0), 'Discount contract not found.');
        currentDiscount = discountContract;
    }

    function setDefaultTax(uint _taxId) public onlyAdmin {
        defaultTax = _taxId;
    }

    /// @notice Constructor to initialize the RentalityPaymentService.
    /// @param _userService The address of the RentalityUserService contract
    function initialize(address _userService, address _floridaTaxes, address _baseDiscount) public initializer {
        userService = IRentalityAccessControl(_userService);
        platformFeeInPPM = 200_000;

        currentDiscount = _baseDiscount;
        discountAddressToDiscountContract[_baseDiscount] = IRentalityDiscount(_baseDiscount);

        taxesId = 1;
        defaultTax = 1;
        taxesIdToTaxesContract[taxesId] = IRentalityTaxes(_floridaTaxes);

        __Ownable_init();
    }
}
