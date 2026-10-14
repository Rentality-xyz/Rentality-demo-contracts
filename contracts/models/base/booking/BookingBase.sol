// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BookingTypes.sol";
import "./IBooking.sol";

abstract contract BookingBase is IBooking {
    uint256 internal nextBookingId;

    mapping(uint256 => Booking) internal bookings;
    mapping(uint256 => uint256[]) internal resourceIdToActiveBookings;
    mapping(uint256 => uint256[]) internal resourceIdToBookings;
    mapping(address => uint256[]) internal userToBookings;
    mapping(address => uint256[]) internal userToActiveBookings;

    error BookingDoesNotExist(uint256 id);
    error InvalidBookingWindow(uint64 startDateTime, uint64 endDateTime);
    error InvalidBookingParties(address provider, address customer);
    error BookingWindowTaken(uint256 resourceId, uint256 bookingId);

    event BookingCreated(uint256 indexed id, uint256 indexed resourceId, address indexed provider, address customer);
    event BookingWindowUpdated(uint256 indexed id, uint64 startDateTime, uint64 endDateTime);
    event BookingReleased(uint256 indexed id, uint256 indexed resourceId);

    modifier bookingExists(uint256 id) {
        if (!exists(id)) {
            revert BookingDoesNotExist(id);
        }
        _;
    }

    function getBooking(uint256 id) external view virtual bookingExists(id) returns (Booking memory) {
        return bookings[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return bookings[id].id != 0;
    }

    function getProvider(uint256 id) external view virtual bookingExists(id) returns (address) {
        return bookings[id].provider;
    }

    function getCustomer(uint256 id) external view virtual bookingExists(id) returns (address) {
        return bookings[id].customer;
    }

    function isWindowFree(
        uint256 resourceId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view virtual returns (bool) {
        return _firstOverlapping(resourceId, startDateTime, endDateTime, 0) == 0;
    }

    function isBookedAt(uint256 resourceId, uint64 timestamp) public view virtual returns (bool) {
        uint256[] storage activeBookings = resourceIdToActiveBookings[resourceId];
        uint256 length = activeBookings.length;

        for (uint256 i = 0; i < length; i++) {
            Booking storage booking = bookings[activeBookings[i]];

            if (booking.startDateTime <= timestamp && timestamp < booking.endDateTime) {
                return true;
            }
        }

        return false;
    }

    function getActiveBookings(uint256 resourceId) external view virtual returns (uint256[] memory) {
        return resourceIdToActiveBookings[resourceId];
    }

    function _createBooking(
        uint256 resourceId,
        address provider,
        address customer,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal virtual returns (uint256) {
        _validateBooking(resourceId, provider, customer, startDateTime, endDateTime);

        // Pruning belongs to exclusivity and goes no further than it. A model that allows
        // overlapping requests keeps its own meaning for this list: Rentality's trips read it to
        // refuse handing over a car that is already out, and a car whose trip was due back
        // yesterday and was never closed is precisely the one that must not be handed to anybody.
        if (_bookingsAreExclusive()) {
            _forgetEndedBookings(resourceId);
        }

        _requireWindowFree(resourceId, startDateTime, endDateTime, 0);

        uint256 id = ++nextBookingId;

        bookings[id] = Booking({
            id: id,
            resourceId: resourceId,
            customer: customer,
            provider: provider,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            createdAt: uint64(block.timestamp)
        });

        resourceIdToBookings[resourceId].push(id);
        resourceIdToActiveBookings[resourceId].push(id);
        userToBookings[provider].push(id);
        userToBookings[customer].push(id);
        userToActiveBookings[provider].push(id);
        userToActiveBookings[customer].push(id);

        emit BookingCreated(id, resourceId, provider, customer);
        return id;
    }

    function _updateBookingWindow(
        uint256 id,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal virtual bookingExists(id) {
        if (startDateTime >= endDateTime) {
            revert InvalidBookingWindow(startDateTime, endDateTime);
        }

        uint256 resourceId = bookings[id].resourceId;
        _requireWindowFree(resourceId, startDateTime, endDateTime, id);

        bookings[id].startDateTime = startDateTime;
        bookings[id].endDateTime = endDateTime;

        emit BookingWindowUpdated(id, startDateTime, endDateTime);
    }

    /**
     * Gives the window back, so the resource can be booked for it again.
     *
     * A booking that was cancelled or completed must be released, or it keeps blocking its hours
     * forever and keeps making every later booking of the same resource more expensive to check.
     */
    function _releaseBooking(uint256 id) internal virtual bookingExists(id) {
        Booking storage booking = bookings[id];

        _removeActiveBooking(booking.resourceId, id);
        _removeActiveBookingFromUser(booking.provider, id);
        _removeActiveBookingFromUser(booking.customer, id);

        emit BookingReleased(id, booking.resourceId);
    }

    function _removeActiveBooking(uint256 resourceId, uint256 bookingId) internal virtual {
        uint256[] storage activeBookings = resourceIdToActiveBookings[resourceId];
        _removeBookingId(activeBookings, bookingId);
    }

    function _removeActiveBookingFromUser(address user, uint256 bookingId) internal virtual {
        uint256[] storage activeBookings = userToActiveBookings[user];
        _removeBookingId(activeBookings, bookingId);
    }

    /**
     * Whether one booking shuts another out of the same hours.
     *
     * True by default, because a resource two people hold at once is the costly mistake and the one
     * nobody notices until both turn up. A model that wants the opposite — several people asking for
     * the same dates and the owner choosing between them — says so here and settles it later.
     */
    function _bookingsAreExclusive() internal view virtual returns (bool) {
        return true;
    }

    function _requireWindowFree(
        uint256 resourceId,
        uint64 startDateTime,
        uint64 endDateTime,
        uint256 ignoreBookingId
    ) internal view virtual {
        if (!_bookingsAreExclusive()) {
            return;
        }

        uint256 taken = _firstOverlapping(resourceId, startDateTime, endDateTime, ignoreBookingId);

        if (taken != 0) {
            revert BookingWindowTaken(resourceId, taken);
        }
    }

    /**
     * Windows are half-open: one ending exactly when the next begins is not an overlap, so a
     * resource handed over at noon can be booked until noon and from noon.
     */
    function _firstOverlapping(
        uint256 resourceId,
        uint64 startDateTime,
        uint64 endDateTime,
        uint256 ignoreBookingId
    ) internal view virtual returns (uint256) {
        uint256[] storage activeBookings = resourceIdToActiveBookings[resourceId];
        uint256 length = activeBookings.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 bookingId = activeBookings[i];

            if (bookingId == ignoreBookingId) {
                continue;
            }

            Booking storage booking = bookings[bookingId];

            // A window that has run out holds nothing. The resource is free whatever became of the
            // booking: a request nobody answered, or one answered and never closed, stops standing
            // in the way of the hours it asked for once those hours have gone by.
            if (booking.endDateTime <= block.timestamp) {
                continue;
            }

            if (startDateTime < booking.endDateTime && booking.startDateTime < endDateTime) {
                return bookingId;
            }
        }

        return 0;
    }

    /**
     * Drops bookings whose hours have gone by from the list this resource is checked against.
     *
     * <p>Only that list. The same bookings stay in their people's own, because a stay that ended
     * yesterday and was never closed is still somebody's to finish — the resource has moved on, the
     * paperwork has not.
     *
     * <p>Run when a booking is made rather than on a timer, which there is none of here: the cost
     * falls on the next person to book the same resource, and it is theirs to pay — an unpruned
     * list is exactly what makes their own booking expensive.
     */
    function _forgetEndedBookings(uint256 resourceId) internal virtual {
        uint256[] storage activeBookings = resourceIdToActiveBookings[resourceId];

        // Backwards, because removing swaps the last entry into the hole: walking forwards would
        // step over whatever was moved down into the slot just examined.
        for (uint256 i = activeBookings.length; i > 0; i--) {
            uint256 bookingId = activeBookings[i - 1];

            if (bookings[bookingId].endDateTime <= block.timestamp) {
                activeBookings[i - 1] = activeBookings[activeBookings.length - 1];
                activeBookings.pop();
            }
        }
    }

    function _validateBooking(
        uint256 resourceId,
        address provider,
        address customer,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal pure virtual {
        if (resourceId == 0 || provider == address(0) || customer == address(0) || provider == customer) {
            revert InvalidBookingParties(provider, customer);
        }

        if (startDateTime >= endDateTime) {
            revert InvalidBookingWindow(startDateTime, endDateTime);
        }
    }

    function _removeBookingId(uint256[] storage bookingIds, uint256 bookingId) internal virtual {
        uint256 length = bookingIds.length;

        for (uint256 i = 0; i < length; i++) {
            if (bookingIds[i] == bookingId) {
                bookingIds[i] = bookingIds[length - 1];
                bookingIds.pop();
                break;
            }
        }
    }
}
