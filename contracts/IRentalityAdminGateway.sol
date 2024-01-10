// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/// @title Rentality Admin Gateway Interface
/// @dev Interface for the RentalityAdminGateway contract,
/// providing administrative functionalities for the Rentality platform.
interface IRentalityAdminGateway {

    /// @notice Withdraws the specified amount from the RentalityPlatform contract.
    /// @param amount The amount to withdraw.
    function withdrawFromPlatform(uint256 amount) external;

    /// @notice Withdraws the entire balance from the RentalityPlatform contract.
    function withdrawAllFromPlatform() external;

    /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
    /// @param valueInPPM The new platform fee value in PPM.
    function setPlatformFeeInPPM(uint32 valueInPPM) external;

}