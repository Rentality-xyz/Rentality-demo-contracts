pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface ITripGatewayFacet {
    function getTripContactInfo(uint256 tripId)
        external
        view
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber);
    function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory);
    function getTripsAs(bool host) external view returns (Schemas.TripDTO[] memory result);
    function getChatInfoFor(bool host) external view returns (Schemas.ChatInfo[] memory result);
    function createTripRequestWithDelivery(
        Schemas.CreateTripRequestWithDelivery memory request,
        string memory promo
    ) external payable;
    function calculatePaymentsWithDelivery(
        uint256 carId,
        uint64 daysOfTrip,
        address currency,
        Schemas.LocationInfo memory pickUpLocation,
        Schemas.LocationInfo memory returnLocation,
        string memory promo
    ) external view returns (Schemas.CalculatePaymentsDTO memory);
    function approveTripRequest(uint256 tripId) external;
    function rejectTripRequest(uint256 tripId) external;
    function confirmCheckOut(uint256 tripId) external;
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
