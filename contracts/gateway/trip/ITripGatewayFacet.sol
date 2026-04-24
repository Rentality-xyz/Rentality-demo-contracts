// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/CommonTypes.sol';
import '../../models/trip/TripTypes.sol';

interface ITripGatewayFacet {
    function getTripContactInfo(uint256 tripId)
        external
        view
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber);
    function getTrip(uint256 tripId) external view returns (TripGatewayTypes.GatewayTripDTO memory);
    function getTripsAs(bool host) external view returns (TripGatewayTypes.GatewayTripDTO[] memory result);
    function getChatInfoFor(bool host) external view returns (TripGatewayTypes.GatewayChatInfo[] memory result);
    function getAllTrips(TripGatewayTypes.GatewayTripFilter memory filter, uint page, uint itemsPerPage)
        external
        view
        returns (TripGatewayTypes.GatewayAllTripsDTO memory allTrips);
    function createTripRequestWithDelivery(
        TripGatewayTypes.GatewayCreateTripRequestWithDelivery memory request,
        string memory promo
    ) external payable;
    function calculatePaymentsWithDelivery(
        uint256 carId,
        uint64 daysOfTrip,
        address currency,
        LocationInfo memory pickUpLocation,
        LocationInfo memory returnLocation,
        string memory promo
    ) external view returns (TripGatewayTypes.GatewayCalculatePaymentsDTO memory);
    function approveTripRequest(uint256 tripId) external;
    function rejectTripRequest(uint256 tripId) external;
    function confirmCheckOut(uint256 tripId) external;
    function payToHost(uint256 tripId) external;
    function refundToGuest(uint256 tripId) external;
    function finishTrip(uint256 tripId) external;
    function checkInByHost(
        uint256 tripId,
        uint64[] memory panelParams,
        string memory insuranceCompany,
        string memory insuranceNumber
    ) external;
    function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external;
    function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external;
    function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external;
}
