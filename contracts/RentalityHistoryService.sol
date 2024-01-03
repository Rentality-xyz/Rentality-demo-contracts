// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./RentalityTripService.sol";
import "./RentalityClaimService.sol";

/// @title RentalityTransactionInfo
/// @notice Contract for managing transaction information related to a trip service on the Rentality platform.
contract RentalityHistoryService is UUPSAccess, Initializable {

    // Struct to store transaction history details for a trip
    struct TransactionHistory {
        uint256 rentalityFee;
        uint256 depositRefund;
        // Earnings from the trip (cancellation or completion)
        uint256 tripEarnings;
        // Timestamp of the transaction
        uint256 dateTime;
        // Status before trip cancellation, will be 'Finished' in case of completed trip.
        RentalityTripService.TripStatus statusBeforeCancellation;
    }

    // Mapping to store transaction history for each trip ID
    mapping(uint256 => TransactionHistory) private tripIdToTransactionHistory;

    /// @notice Function to save transaction information for a canceled trip.
    /// @param tripId Trip ID for which the transaction information is saved.
    /// @param statusBeforeCancellation Status before the trip cancellation.
    /// @param hostFee Host fee for the transaction.
    /// @param platformFee Platform fee for the transaction.
    /// @param guestRefund Amount refunded to the guest.
    function saveCanceledTripInfo(
        uint256 tripId,
        RentalityTripService.TripStatus statusBeforeCancellation,
        uint256 hostFee,
        uint256 platformFee,
        uint256 guestRefund
    ) public {
        require(userService.isManager(msg.sender), "Manager only.");

        TransactionHistory memory info = TransactionHistory(
            platformFee,
            guestRefund,
            hostFee,
            block.timestamp,
            statusBeforeCancellation
        );

        tripIdToTransactionHistory[tripId] = info;
    }

    /// @dev Function to save transaction information for a finished trip.
    /// @param tripId Trip ID for which the transaction information is saved.
    /// @param rentalityFee Rentality fee for the transaction.
    /// @param depositRefund Amount refunded as deposit.
    /// @param tripEarnings Earnings from the completed trip.
    function saveFinishedTripInfo(
        uint256 tripId,
        uint256 rentalityFee,
        uint256 depositRefund,
        uint256 tripEarnings
    ) public {
        require(userService.isManager(msg.sender), "Manager only.");

        TransactionHistory memory trInfo = TransactionHistory(
            rentalityFee,
            depositRefund,
            tripEarnings,
            block.timestamp,
            RentalityTripService.TripStatus.Finished
        );
        tripIdToTransactionHistory[tripId] = trInfo;
    }

    /// @dev Function to retrieve transaction history for a given trip ID.
    /// @param tripId Trip ID for which transaction history is retrieved.
    /// @return TransactionHistory structure containing details of the transaction.
    function getTransactionHistory(uint256 tripId) public view returns (TransactionHistory memory) {
        return tripIdToTransactionHistory[tripId];
    }

    function initialize(address _userService) public initializer {
        userService = IRentalityAccessControl(_userService);
    }
}
