// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityUserService.sol";

/// @title RentalityClaimService - Manages claims and related operations.
/// @dev This contract allows users with manager roles to create, reject, and pay claims.
contract RentalityClaimService {
    // Private variables for platform configuration
    uint8 private platformFeeInPercent;
    uint256 private waitingTimeForApproveInSec = 259_200;
    uint256 private claimId;

    // Mapping to store claims using claimId as the key
    mapping(uint256 => Claim) private claimIdToClaim;

    // Reference to RentalityUserService contract
    RentalityUserService private userService;

    constructor(uint8 platformFee, address _userService)
    {
        platformFeeInPercent = platformFee;
        userService = RentalityUserService(_userService);
    }

    // Struct to represent additional information about a claim
    struct FullClaimInfo {
        Claim claim;
        string carBrand;
        string carModel;
        uint32 carYearOfProduction;
    }

    // Struct to represent a claim
    struct Claim {
        uint256 tripId;
        uint256 claimId;
        uint256 deadlineDateInSec;
        ClaimType claimType;
        Status status;
        string description;
        uint256 amountInUsdCents;
        uint256 payDateInSec;
        address RejectedBy; // if so
        uint256 rejectedDateInSec; // if so
    }

    // Struct to represent a request to create a new claim
    struct CreateClaimRequest {
        uint256 tripId;
        ClaimType claimType;
        string description;
        uint256 amountInUsdCents;
    }

    // Enumeration for types of claims
    enum ClaimType {
        Tolls,
        Tickets,
        LateReturn,
        Cleanliness,
        Smoking,
        ExteriorDamage,
        InteriorDamage,
        Other
    }

    // Enumeration for claim statuses
    enum Status {
        NotPaid,
        Paid,
        Cancel,
        Overdue
    }

    // Modifier to restrict access to only managers contracts
    modifier onlyManager() {
        require(userService.isManager(msg.sender), "Only manager.");
        _;
    }

    /// @dev Sets the platform fee, only callable by administrators.
    /// @param newPlatfromFeeInPercent New platform fee in percentage.
    function setPlatfromFee(uint8 newPlatfromFeeInPercent) public {
        require(userService.isAdmin(msg.sender), "Only admin.");
        platformFeeInPercent = newPlatfromFeeInPercent;
    }

    /// @dev Gets the current platform fee.
    /// @return Current platform fee in percentage.
    function getPlatformFee() public view returns (uint8) {
        return platformFeeInPercent;
    }

    /// @dev Creates a new claim, only callable by managers contracts.
    /// @param request Details of the claim to be created.
    function createClaim(CreateClaimRequest memory request) public onlyManager {
        require(request.amountInUsdCents > 0, "Amount cannot be null.");

        claimId += 1;

        uint256 deadline = block.timestamp + waitingTimeForApproveInSec;

        Claim memory newClaim = Claim(
            request.tripId,
            claimId,
            deadline,
            request.claimType,
            Status.NotPaid,
            request.description,
            request.amountInUsdCents,
            0,
            address(0),
            0
        );
        claimIdToClaim[claimId] = newClaim;
    }

    /// @dev Rejects a claim, only callable by managers contracts.
    /// @param _claimId ID of the claim to be rejected.
    /// @param rejectedBy Address of the user rejecting the claim.
    function rejectClaim(uint256 _claimId, address rejectedBy) public onlyManager {
        Claim storage claim = claimIdToClaim[_claimId];
        require(claim.status != Status.Paid && claim.status != Status.Cancel, "Wrong claim status.");

        claim.status = Status.Cancel;
        claim.RejectedBy = rejectedBy;
        claim.rejectedDateInSec = block.timestamp;
    }

    /// @dev Pays a claim, only callable by managers contracts.
    /// @param _claimId ID of the claim to be paid.
    function payClaim(uint256 _claimId) public onlyManager {
        Claim storage claim = claimIdToClaim[_claimId];

        uint256 time = block.timestamp;

        claim.payDateInSec = time;
        claim.status = Status.Paid;
    }

    /// @dev Updates the status of a claim based on the current timestamp.
    /// @param _claimId ID of the claim to be updated.
    function updateClaim(uint256 _claimId) public {
        Claim storage claim = claimIdToClaim[_claimId];

        uint256 time = block.timestamp;

        if (time >= claim.deadlineDateInSec) {
            claim.status = Status.Overdue;
        }
    }

    /// @dev Gets the details of a claim by its ID.
    /// @param _claimId ID of the claim.
    /// @return Details of the claim.
    function getClaim(uint256 _claimId) public view returns (Claim memory) {
        return claimIdToClaim[_claimId];
    }

    /// @dev Gets the total number of claims.
    /// @return Total number of claims.
    function getClaimsAmount() public view returns (uint256) {
        return claimId;
    }

    /// @dev Checks if a claim with a specific ID exists.
    /// @param _claimId ID of the claim.
    /// @return True if the claim exists, false otherwise.
    function exists(uint256 _claimId) public view returns (bool) {
        return claimIdToClaim[_claimId].deadlineDateInSec > 0;
    }
}
