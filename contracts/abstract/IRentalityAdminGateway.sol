// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Rentality Admin Gateway Interface
/// @dev Interface for the RentalityAdminGateway contract,
/// providing administrative functionalities for the Rentality platform.
interface IRentalityAdminGateway {
  /// @notice Retrieves the address of the RentalityCarToken contract.
  /// @return The address of the RentalityCarToken contract.
  function getCarServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCarToken contract.
  function updateCarService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityPayment contract.
  /// @return The address of the RentalityPayment contract.
  function getPaymentService() external view returns (address);

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPayment contract.
  function updatePaymentService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityClaim contract.
  /// @return The address of the RentalityClaim contract.
  function getClaimServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityClaim contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityClaim contract.
  function updateClaimService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityPlatform contract.
  /// @return The address of the RentalityPlatform contract.
  function getRentalityPlatformAddress() external view returns (address);

  /// @notice Updates the address of the RentalityPlatform contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPlatform contract.
  function updateRentalityPlatform(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityCurrencyConverter contract.
  /// @return The address of the RentalityCurrencyConverter contract.
  function getCurrencyConverterServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCurrencyConverter contract.
  function updateCurrencyConverterService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityTripService contract.
  /// @return The address of the RentalityTripService contract.
  function getTripServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityTripService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityTripService contract.
  function updateTripService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityUserService contract.
  /// @return The address of the RentalityUserService contract.
  function getUserServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityUserService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityUserService contract.
  function updateUserService(address contractAddress) external;

  /// @notice Withdraws the specified amount from the RentalityPlatform contract.
  /// @param amount The amount to withdraw.
  function withdrawFromPlatform(uint256 amount, address currencyType) external;

  /// @notice Withdraws the entire balance from the RentalityPlatform contract.
  function withdrawAllFromPlatform(address currencyType) external;

  /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
  /// @param valueInPPM The new platform fee value in PPM.
  function setPlatformFeeInPPM(uint32 valueInPPM) external;

  /// @notice Updates the address of the GeoService contract.
  /// @param newGeoServiceAddress The new address of the GeoService contract.
  function updateGeoServiceAddress(address newGeoServiceAddress) external;

  /// @dev Sets the waiting time, only callable by administrators.
  /// @param timeInSec, set old value to this
  function setClaimsWaitingTime(uint timeInSec) external;

  /// @dev get waiting time to approval
  /// @return waiting time to approval in sec
  function getClaimWaitingTime() external view returns (uint);

  /// @notice Get the platform fee in parts per million (PPM).
  /// @return The platform fee in PPM.
  function getPlatformFeeInPPM() external view returns (uint32);

  /// @notice Confirms check-out for a trip.
  /// @param tripId The ID of the trip.
  function payToHost(uint256 tripId) external;

  /// @notice Rejects a trip request. Only callable by hosts.
  /// @param tripId The ID of the trip to reject.
  function refundToGuest(uint256 tripId) external;

  /// @dev Sets the Civic verifier and gatekeeper network for identity verification.
  /// @param _civicVerifier The address of the Civic verifier contract.
  /// @param _civicGatekeeperNetwork The identifier of the Civic gatekeeper network.
  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) external;

  /// @notice Sets a new message for the Terms and Conditions (TC) and updates the corresponding hashed message.
  /// @dev This function can only be called by an admin.
  /// @param message The new message for the TC.
  // function setNewTCMessage(string memory message) external;
}
