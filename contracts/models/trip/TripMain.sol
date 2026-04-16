// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/booking/BookingBase.sol";
import "./TripTypes.sol";
import "./../car/CarTypes.sol";
import "../../infrastructure/upgradeable/UUPSOwnable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface ITripUserAccess {
    function isRentalityPlatform(address user) external view returns (bool);
    function isAdmin(address user) external view returns (bool);
}

interface ITripEngineService {
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

interface ITripCarLookup {
    function getCarData(uint256 id) external view returns (CarData memory);
}

contract TripMain is BookingBase, UUPSOwnable {
    ITripUserAccess public userAccess;
    ITripEngineService public engineService;
    ITripCarLookup public carLookup;

    mapping(uint256 => Trip) internal trips;
    mapping(uint256 => bool) internal completedByAdmin;
    mapping(uint256 => uint256) internal tripIdToEthSumInTripCreation;

    error OnlyPlatform();
    error OnlyAdmin();
    error InvalidTripHost(uint256 tripId, address caller);
    error InvalidTripGuest(uint256 tripId, address caller);
    error InvalidTripStatus(uint256 tripId, TripStatus currentStatus, TripStatus expectedStatus);
    error TripCancellationNotAllowed(uint256 tripId, TripStatus currentStatus);
    error CarOnAnotherActiveTrip(uint256 tripId, uint256 conflictingTripId);

    event TripCreated(uint256 indexed tripId, uint256 indexed carId, address indexed guest, address host);
    event TripStatusUpdated(uint256 indexed tripId, TripStatus status);

    modifier onlyPlatform() {
        if (address(userAccess) == address(0) || !userAccess.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    modifier onlyAdmin() {
        if (address(userAccess) == address(0) || !(userAccess.isAdmin(msg.sender) || userAccess.isAdmin(tx.origin))) {
            revert OnlyAdmin();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address userAccessAddress,
        address engineServiceAddress,
        address carLookupAddress
    ) public initializer {
        __Ownable_init();
        userAccess = ITripUserAccess(userAccessAddress);
        engineService = ITripEngineService(engineServiceAddress);
        carLookup = ITripCarLookup(carLookupAddress);
    }

    function createTrip(CreateTripRecordRequest calldata request) external onlyPlatform returns (uint256) {
        uint64 milesIncludedPerDay = request.milesIncludedPerDay;
        if (milesIncludedPerDay == 0) {
            milesIncludedPerDay = type(uint32).max;
        }

        uint256 tripId = _createBooking(
            request.carId,
            request.host,
            request.guest,
            request.startDateTime,
            request.endDateTime
        );

        TripPaymentInfo memory paymentInfo = request.paymentInfo;
        paymentInfo.tripId = tripId;

        trips[tripId] = Trip({
            booking: bookings[tripId],
            status: TripStatus.Created,
            guestName: request.guestName,
            hostName: request.hostName,
            pricePerDayInUsdCents: request.pricePerDayInUsdCents,
            engineType: request.engineType,
            milesIncludedPerDay: milesIncludedPerDay,
            fuelPrice: request.fuelPrice,
            paymentInfo: paymentInfo,
            approvedDateTime: 0,
            rejectedDateTime: 0,
            guestInsuranceCompanyName: "",
            guestInsurancePolicyNumber: "",
            rejectedBy: address(0),
            checkedInByHostDateTime: 0,
            startParamLevels: new uint64[](request.panelParamsCount),
            checkedInByGuestDateTime: 0,
            tripStartedBy: address(0),
            checkedOutByGuestDateTime: 0,
            tripFinishedBy: address(0),
            endParamLevels: new uint64[](request.panelParamsCount),
            checkedOutByHostDateTime: 0,
            transactionInfo: TripTransactionInfo({
                rentalityFee: 0,
                depositRefund: 0,
                tripEarnings: 0,
                dateTime: 0,
                statusBeforeCancellation: TripStatus.Created
            }),
            finishDateTime: 0,
            pickUpHash: request.pickUpHash,
            returnHash: request.returnHash
        });

        tripIdToEthSumInTripCreation[tripId] = request.ethSumInTripCreation;

        emit TripCreated(tripId, request.carId, request.guest, request.host);
        emit TripStatusUpdated(tripId, TripStatus.Created);
        return tripId;
    }

    function approveTrip(uint256 tripId, address user) external onlyPlatform bookingExists(tripId) {
        Trip storage trip = trips[tripId];
        if (trip.booking.provider != user) {
            revert InvalidTripHost(tripId, user);
        }
        if (trip.status != TripStatus.Created) {
            revert InvalidTripStatus(tripId, trip.status, TripStatus.Created);
        }

        trip.status = TripStatus.Approved;
        trip.approvedDateTime = block.timestamp;

        emit TripStatusUpdated(tripId, TripStatus.Approved);
    }

    function rejectTrip(
        uint256 tripId,
        uint256 rentalityFee,
        uint256 depositRefund,
        uint256 tripEarnings,
        address user
    ) external onlyPlatform bookingExists(tripId) {
        Trip storage trip = trips[tripId];
        TripStatus status = trip.status;

        bool controversialSituation = userAccess.isAdmin(user) && status == TripStatus.CheckedOutByHost;
        bool isTripParticipant = trip.booking.provider == user || trip.booking.customer == user;
        if (!isTripParticipant && !controversialSituation) {
            revert InvalidTripGuest(tripId, user);
        }

        bool isAllowedStatus =
            status == TripStatus.Created ||
            status == TripStatus.Approved ||
            status == TripStatus.CheckedInByHost ||
            controversialSituation;
        if (!isAllowedStatus) {
            revert TripCancellationNotAllowed(tripId, status);
        }

        _deactivateTrip(tripId);

        trip.status = TripStatus.Canceled;
        trip.rejectedDateTime = block.timestamp;
        trip.rejectedBy = user;

        _saveTransactionInfo(tripId, rentalityFee, status, depositRefund, tripEarnings);

        emit TripStatusUpdated(tripId, TripStatus.Canceled);
    }

    function checkInByHost(
        uint256 tripId,
        uint64[] calldata panelParams,
        string calldata insuranceCompany,
        string calldata insuranceNumber,
        address user
    ) external onlyPlatform bookingExists(tripId) {
        Trip storage trip = trips[tripId];
        if (trip.booking.provider != user) {
            revert InvalidTripHost(tripId, user);
        }
        if (trip.status != TripStatus.Approved) {
            revert InvalidTripStatus(tripId, trip.status, TripStatus.Approved);
        }

        uint256[] memory activeTrips = resourceIdToActiveBookings[trip.booking.resourceId];
        for (uint256 i = 0; i < activeTrips.length; i++) {
            uint256 activeTripId = activeTrips[i];
            if (activeTripId == tripId || !exists(activeTripId)) {
                continue;
            }

            Trip memory otherTrip = trips[activeTripId];
            if (
                otherTrip.booking.resourceId == trip.booking.resourceId &&
                (
                    otherTrip.status == TripStatus.CheckedInByGuest ||
                    otherTrip.status == TripStatus.CheckedInByHost ||
                    otherTrip.status == TripStatus.CheckedOutByGuest
                )
            ) {
                revert CarOnAnotherActiveTrip(tripId, activeTripId);
            }
        }

        engineService.verifyStartParams(panelParams, trip.engineType);

        trip.status = TripStatus.CheckedInByHost;
        trip.checkedInByHostDateTime = block.timestamp;
        trip.startParamLevels = panelParams;
        trip.guestInsuranceCompanyName = insuranceCompany;
        trip.guestInsurancePolicyNumber = insuranceNumber;

        emit TripStatusUpdated(tripId, TripStatus.CheckedInByHost);
    }

    function checkInByGuest(uint256 tripId, uint64[] calldata panelParams, address user)
        external
        onlyPlatform
        bookingExists(tripId)
    {
        Trip storage trip = trips[tripId];
        if (trip.booking.customer != user) {
            revert InvalidTripGuest(tripId, user);
        }
        if (trip.status != TripStatus.CheckedInByHost) {
            revert InvalidTripStatus(tripId, trip.status, TripStatus.CheckedInByHost);
        }

        engineService.compareParams(panelParams, trip.startParamLevels, trip.engineType);

        trip.tripStartedBy = user;
        trip.status = TripStatus.CheckedInByGuest;
        trip.checkedInByGuestDateTime = block.timestamp;

        emit TripStatusUpdated(tripId, TripStatus.CheckedInByGuest);
    }

    function checkOutByGuest(uint256 tripId, uint64[] calldata panelParams, address user)
        external
        onlyPlatform
        bookingExists(tripId)
    {
        Trip storage trip = trips[tripId];
        if (trip.booking.customer != user) {
            revert InvalidTripGuest(tripId, user);
        }
        if (trip.status != TripStatus.CheckedInByGuest) {
            revert InvalidTripStatus(tripId, trip.status, TripStatus.CheckedInByGuest);
        }

        CarData memory car = carLookup.getCarData(trip.booking.resourceId);
        engineService.verifyEndParams(trip.startParamLevels, panelParams, trip.engineType);

        trip.endParamLevels = panelParams;
        trip.tripFinishedBy = user;
        trip.status = TripStatus.CheckedOutByGuest;

        _applyResolveAmounts(tripId, car.engineParams, panelParams, true);
        trip.checkedOutByGuestDateTime = block.timestamp;

        emit TripStatusUpdated(tripId, TripStatus.CheckedOutByGuest);
    }

    function checkOutByHost(uint256 tripId, uint64[] calldata panelParams, address user)
        external
        onlyPlatform
        bookingExists(tripId)
    {
        Trip storage trip = trips[tripId];
        if (trip.booking.provider != user) {
            revert InvalidTripHost(tripId, user);
        }

        bool allowedStatus =
            trip.status == TripStatus.CheckedOutByGuest ||
            trip.status == TripStatus.CheckedInByHost ||
            trip.status == TripStatus.CheckedInByGuest;
        if (!allowedStatus) {
            revert TripCancellationNotAllowed(tripId, trip.status);
        }

        CarData memory car = carLookup.getCarData(trip.booking.resourceId);

        if (trip.status == TripStatus.CheckedInByHost || trip.status == TripStatus.CheckedInByGuest) {
            engineService.verifyEndParams(trip.startParamLevels, panelParams, trip.engineType);
            trip.endParamLevels = panelParams;
            trip.tripFinishedBy = user;
            _applyResolveAmounts(tripId, car.engineParams, panelParams, false);
        } else {
            engineService.compareParams(trip.endParamLevels, panelParams, trip.engineType);
        }

        trip.status = TripStatus.CheckedOutByHost;
        trip.checkedOutByHostDateTime = block.timestamp;

        emit TripStatusUpdated(tripId, TripStatus.CheckedOutByHost);
    }

    function finishTrip(uint256 tripId, address user) external onlyPlatform bookingExists(tripId) {
        Trip storage trip = trips[tripId];

        trip.status = TripStatus.Finished;
        _deactivateTrip(tripId);
        trip.finishDateTime = block.timestamp;
        completedByAdmin[tripId] =
            userAccess.isAdmin(user) && trip.booking.provider != user && trip.booking.customer != user;

        emit TripStatusUpdated(tripId, TripStatus.Finished);
    }

    function saveTransactionInfo(
        uint256 tripId,
        uint256 rentalityFee,
        TripStatus status,
        uint256 depositRefund,
        uint256 tripEarnings
    ) external onlyPlatform bookingExists(tripId) {
        _saveTransactionInfo(tripId, rentalityFee, status, depositRefund, tripEarnings);
    }

    function rebuildUserTrips(uint256 start, uint256 end) external onlyAdmin {
        if (end == 0) {
            end = nextBookingId;
        }

        for (uint256 i = start; i <= end; i++) {
            if (!exists(i)) {
                continue;
            }

            Trip memory trip = trips[i];
            userToBookings[trip.booking.customer].push(i);
            userToBookings[trip.booking.provider].push(i);

            if (trip.status != TripStatus.Finished && trip.status != TripStatus.Canceled) {
                userToActiveBookings[trip.booking.customer].push(i);
                userToActiveBookings[trip.booking.provider].push(i);
            }
        }
    }

    function getTrip(uint256 tripId) public view bookingExists(tripId) returns (Trip memory) {
        return trips[tripId];
    }

    function totalSupply() external view returns (uint256) {
        return nextBookingId;
    }

    function getActiveTrips(uint256 carId) external view returns (uint256[] memory) {
        return resourceIdToActiveBookings[carId];
    }

    function getCarTrips(uint256 carId) external view returns (uint256[] memory) {
        return resourceIdToBookings[carId];
    }

    function getActiveTripsByUser(address user) external view returns (uint256[] memory) {
        return userToActiveBookings[user];
    }

    function getTripsByUser(address user) external view returns (uint256[] memory) {
        return userToBookings[user];
    }

    function isCompletedByAdmin(uint256 tripId) external view returns (bool) {
        return completedByAdmin[tripId];
    }

    function getEthSumInTripCreation(uint256 tripId) external view returns (uint256) {
        return tripIdToEthSumInTripCreation[tripId];
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = ITripUserAccess(userAccessAddress);
    }

    function updateEngineService(address engineServiceAddress) external onlyOwner {
        engineService = ITripEngineService(engineServiceAddress);
    }

    function updateCarLookup(address carLookupAddress) external onlyOwner {
        carLookup = ITripCarLookup(carLookupAddress);
    }

    function _deactivateTrip(uint256 tripId) internal {
        Trip storage trip = trips[tripId];
        _removeActiveBooking(trip.booking.resourceId, tripId);
        _removeActiveBookingFromUser(trip.booking.provider, tripId);
        _removeActiveBookingFromUser(trip.booking.customer, tripId);
    }

    function _saveTransactionInfo(
        uint256 tripId,
        uint256 rentalityFee,
        TripStatus status,
        uint256 depositRefund,
        uint256 tripEarnings
    ) internal {
        TripTransactionInfo storage transactionInfo = trips[tripId].transactionInfo;
        transactionInfo.rentalityFee = rentalityFee;
        transactionInfo.depositRefund = depositRefund;
        transactionInfo.tripEarnings = tripEarnings;
        transactionInfo.dateTime = block.timestamp;
        transactionInfo.statusBeforeCancellation = status;
    }

    function _applyResolveAmounts(
        uint256 tripId,
        uint64[] memory engineParams,
        uint64[] memory endParams,
        bool markFinishedByGuest
    ) internal {
        Trip storage trip = trips[tripId];
        trip.endParamLevels = endParams;

        uint64 duration = trip.booking.endDateTime - trip.booking.startDateTime;
        uint64 tripDays = uint64(Math.ceilDiv(duration, 1 days));
        (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = engineService
            .getResolveAmountInUsdCents(
                trip.engineType,
                trip.fuelPrice,
                trip.startParamLevels,
                endParams,
                engineParams,
                trip.milesIncludedPerDay,
                trip.pricePerDayInUsdCents,
                tripDays
            );

        trip.paymentInfo.resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
        trip.paymentInfo.resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

        uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;
        if (resolveAmountInUsdCents > trip.paymentInfo.depositInUsdCents) {
            resolveAmountInUsdCents = trip.paymentInfo.depositInUsdCents;
        }
        trip.paymentInfo.resolveAmountInUsdCents = resolveAmountInUsdCents;

        if (markFinishedByGuest) {
            trip.tripFinishedBy = trip.booking.customer;
        }
    }
}
