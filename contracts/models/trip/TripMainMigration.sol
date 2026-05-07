// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/booking/BookingBase.sol";
import "./TripTypes.sol";
import "./../car/CarTypes.sol";
import "../../infrastructure/upgradeable/UUPSOwnable.sol";

interface ITripMigrationUserAccess {
    function isRentalityPlatform(address user) external view returns (bool);
    function isAdmin(address user) external view returns (bool);
}

interface ITripMigrationEngineService {
    function verifyStartParams(uint64[] memory params, uint8 eType) external view;
    function verifyEndParams(uint64[] memory startParams, uint64[] memory endParams, uint8 eType) external view;
    function compareParams(uint64[] memory startParams, uint64[] memory endParams, uint8 eType) external view;
    function getResolveAmountInUsdCents(
        uint8 engineType,
        uint64 fuelPrice,
        uint64[] memory startParams,
        uint64[] memory endParams,
        uint64[] memory engineParams,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays
    ) external view returns (uint64, uint64);
}

interface ITripMigrationCarLookup {
    function getCarData(uint256 id) external view returns (CarData memory);
}

contract TripMainMigration is BookingBase, UUPSOwnable {
    ITripMigrationUserAccess public userAccess;
    ITripMigrationEngineService public engineService;
    ITripMigrationCarLookup public carLookup;

    mapping(uint256 => Trip) internal trips;
    mapping(uint256 => bool) internal completedByAdmin;
    mapping(uint256 => uint256) internal tripIdToEthSumInTripCreation;

    struct MigrationTripImport {
        Trip trip;
        bool completedByAdminFlag;
        uint256 ethSumInTripCreation;
    }

    event TripCreated(uint256 indexed tripId, uint256 indexed carId, address indexed guest, address host);
    event TripStatusUpdated(uint256 indexed tripId, TripStatus status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function migrationImportTrip(MigrationTripImport calldata item) external onlyOwner {
        Trip calldata trip = item.trip;
        uint256 tripId = trip.booking.id;

        if (tripId == 0 || exists(tripId)) {
            revert BookingDoesNotExist(tripId);
        }

        _validateBooking(
            trip.booking.resourceId,
            trip.booking.provider,
            trip.booking.customer,
            trip.booking.startDateTime,
            trip.booking.endDateTime
        );

        bookings[tripId] = trip.booking;
        trips[tripId] = trip;
        completedByAdmin[tripId] = item.completedByAdminFlag;
        tripIdToEthSumInTripCreation[tripId] = item.ethSumInTripCreation;

        resourceIdToBookings[trip.booking.resourceId].push(tripId);
        userToBookings[trip.booking.provider].push(tripId);
        userToBookings[trip.booking.customer].push(tripId);

        if (trip.status != TripStatus.Finished && trip.status != TripStatus.Canceled) {
            resourceIdToActiveBookings[trip.booking.resourceId].push(tripId);
            userToActiveBookings[trip.booking.provider].push(tripId);
            userToActiveBookings[trip.booking.customer].push(tripId);
        }

        if (tripId > nextBookingId) {
            nextBookingId = tripId;
        }

        emit BookingCreated(tripId, trip.booking.resourceId, trip.booking.provider, trip.booking.customer);
        emit TripCreated(tripId, trip.booking.resourceId, trip.booking.customer, trip.booking.provider);
        emit TripStatusUpdated(tripId, trip.status);
    }
}
