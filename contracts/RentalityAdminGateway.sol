// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityPaymentService.sol';
import './RentalityPlatform.sol';
import './IRentalityAdminGateway.sol';

contract RentalityAdminGateway is UUPSOwnable, IRentalityAdminGateway {
    RentalityCarToken private carService;
    RentalityCurrencyConverter private currencyConverterService;
    RentalityTripService private tripService;
    RentalityUserService private userService;
    RentalityPlatform private rentalityPlatform;
    RentalityPaymentService private paymentService;
    RentalityClaimService private claimService;

    // unused, have to be here, because of proxy
    address private automationService;
    /// @notice Ensures that the caller is either an admin, the contract owner, or an admin from the origin transaction.
    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) || (tx.origin == owner()),
            'User is not an admin'
        );
        _;
    }

    /// @notice Retrieves the address of the RentalityCarToken contract.
    /// @return The address of the RentalityCarToken contract.
    function getCarServiceAddress() public view returns (address) {
        return address(carService);
    }

    /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityCarToken contract.
    function updateCarService(address contractAddress) public onlyAdmin {
        carService = RentalityCarToken(contractAddress);
    }
    /// @notice Retrieves the address of the RentalityPayment contract.
    /// @return The address of the RentalityPayment contract.
    function getPaymentService() public view returns (address) {
        return address(paymentService);
    }

    /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityPayment contract.
    function updatePaymentService(address contractAddress) public onlyAdmin {
        paymentService = RentalityPaymentService(contractAddress);
    }
    /// @notice Retrieves the address of the RentalityClaim contract.
    /// @return The address of the RentalityClaim contract.
    function getClaimServiceAddress() public view returns (address) {
        return address(claimService);
    }

    /// @notice Updates the address of the RentalityClaim contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityClaim contract.
    function updateClaimService(address contractAddress) public onlyAdmin {
        claimService = RentalityClaimService(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityPlatform contract.
    /// @return The address of the RentalityPlatform contract.
    function getRentalityPlatformAddress() public view returns (address) {
        return address(rentalityPlatform);
    }

    /// @notice Updates the address of the RentalityPlatform contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityPlatform contract.
    function updateRentalityPlatform(address contractAddress) public onlyAdmin {
        rentalityPlatform = RentalityPlatform(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityCurrencyConverter contract.
    /// @return The address of the RentalityCurrencyConverter contract.
    function getCurrencyConverterServiceAddress() public view returns (address) {
        return address(currencyConverterService);
    }

    /// @notice Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityCurrencyConverter contract.
    function updateCurrencyConverterService(address contractAddress) public onlyAdmin {
        currencyConverterService = RentalityCurrencyConverter(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityTripService contract.
    /// @return The address of the RentalityTripService contract.
    function getTripServiceAddress() public view returns (address) {
        return address(tripService);
    }

    /// @notice Updates the address of the RentalityTripService contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityTripService contract.
    function updateTripService(address contractAddress) public onlyAdmin {
        tripService = RentalityTripService(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityUserService contract.
    /// @return The address of the RentalityUserService contract.
    function getUserServiceAddress() public view returns (address) {
        return address(userService);
    }

    /// @notice Updates the address of the RentalityUserService contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityUserService contract.
    function updateUserService(address contractAddress) public onlyAdmin {
        userService = RentalityUserService(contractAddress);
    }

    /// @notice Updates the address of the GeoService contract.
    /// @param newGeoServiceAddress The new address of the GeoService contract.
    function updateGeoServiceAddress(address newGeoServiceAddress) public onlyAdmin {
        carService.updateGeoServiceAddress(newGeoServiceAddress);
    }

    /// @notice Updates the address of the GeoParser contract.
    /// @param newGeoParserAddress The new address of the GeoParser contract.
    function updateGeoParserAddress(address newGeoParserAddress) public onlyAdmin {
        carService.updateGeoParsesAddress(newGeoParserAddress);
    }

    /// @notice Withdraws the specified amount from the RentalityPlatform contract.
    /// @param amount The amount to withdraw.
    function withdrawFromPlatform(uint256 amount) public {
        rentalityPlatform.withdrawFromPlatform(amount);
    }

    /// @notice Withdraws the entire balance from the RentalityPlatform contract.
    function withdrawAllFromPlatform() public {
        rentalityPlatform.withdrawFromPlatform(address(this).balance);
    }
    /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
    /// @param valueInPPM The new platform fee value in PPM.
    function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
        paymentService.setPlatformFeeInPPM(valueInPPM);
    }

    /// @dev Sets the waiting time, only callable by administrators.
    /// @param timeInSec, set old value to this
    function setClaimsWaitingTime(uint timeInSec) public {
        claimService.setWaitingTime(timeInSec);
    }

    /// @dev get waiting time to approval
    /// @return waiting time to approval in sec
    function getClaimWaitingTime() public view returns (uint) {
        return claimService.getWaitingTime();
    }

    /// @notice Retrieves the platform fee in parts per million (PPM).
    /// @return The platform fee in PPM.
    function getPlatformFeeInPPM() public view returns (uint32) {
        return paymentService.getPlatformFeeInPPM();
    }

    /// @notice Retrieves the platform fee calculated from the given value.
    /// @param value The value from which to calculate the platform fee.
    /// @return The calculated platform fee.
    function getPlatformFeeFrom(uint256 value) private view returns (uint256) {
        return paymentService.getPlatformFeeFrom(value);
    }

    //  @dev Initializes the contract with the provided addresses for various services.
    //  @param carServiceAddress The address of the RentalityCarToken contract.
    //  @param currencyConverterServiceAddress The address of the RentalityCurrencyConverter contract.
    //  @param tripServiceAddress The address of the RentalityTripService contract.
    //  @param userServiceAddress The address of the RentalityUserService contract.
    //  @param rentalityPlatformAddress The address of the RentalityPlatform contract.
    //  @param paymentServiceAddress The address of the RentalityPaymentService contract.
    //  Requirements:
    //  - The contract must not have been initialized before.
    function initialize(
        address carServiceAddress,
        address currencyConverterServiceAddress,
        address tripServiceAddress,
        address userServiceAddress,
        address rentalityPlatformAddress,
        address paymentServiceAddress,
        address claimServiceAddress
    ) public initializer {
        carService = RentalityCarToken(carServiceAddress);
        currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
        tripService = RentalityTripService(tripServiceAddress);
        userService = RentalityUserService(userServiceAddress);
        rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
        paymentService = RentalityPaymentService(paymentServiceAddress);
        claimService = RentalityClaimService(claimServiceAddress);

        __Ownable_init();
    }
}
