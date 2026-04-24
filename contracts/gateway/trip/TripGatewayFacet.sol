// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../infrastructure/upgradeable/UUPSOwnable.sol";
import "../../models/trip/TripTypes.sol";
import "../../models/trip/TripQuery.sol";
import "../../models/common/CommonTypes.sol";
import "../../models/trip/TripMainFacet1.sol";
import "../GatewayContext.sol";
import "../mappers/TripMapper.sol";

interface ITripGatewayFacetUserProfileMain {
    function isRentalityPlatform(address user) external view returns (bool);
}


contract TripGatewayFacet is UUPSOwnable, GatewayContext {
    TripQuery public tripQuery;
    TripMainFacet1 public tripMainFacet1;
    ITripGatewayFacetUserProfileMain public userProfileMain;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address tripQueryAddress,
        address tripMainFacet1Address,
        address userProfileMainAddress
    ) public initializer {
        __Ownable_init();
        _setServiceAddresses(tripQueryAddress, tripMainFacet1Address, userProfileMainAddress);
    }

    function updateServiceAddresses(
        address tripQueryAddress,
        address tripMainFacet1Address,
        address userProfileMainAddress
    ) external onlyOwner {
        _setServiceAddresses(tripQueryAddress, tripMainFacet1Address, userProfileMainAddress);
    }

    function getTripContactInfo(uint256 tripId)
        external
        view
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        return tripQuery.getTripContactInfo(tripId);
    }

    function getTrip(uint256 tripId) external view returns (TripGatewayTypes.GatewayTripDTO memory) {
        return TripMapper.toLegacyTripDTO(tripQuery.getTripDTO(tripId, _msgGatewaySender()));
    }

    function getTripsAs(bool host) external view returns (TripGatewayTypes.GatewayTripDTO[] memory result) {
        TripDTO[] memory trips = tripQuery.getTripsAs(_msgGatewaySender(), host);
        result = new TripGatewayTypes.GatewayTripDTO[](trips.length);
        for (uint256 i = 0; i < trips.length; i++) {
            result[i] = TripMapper.toLegacyTripDTO(trips[i]);
        }
    }

    function getChatInfoFor(bool host) external view returns (TripGatewayTypes.GatewayChatInfo[] memory result) {
        return tripQuery.getChatInfoFor(_msgGatewaySender(), host);
    }

    function getAllTrips(TripGatewayTypes.GatewayTripFilter memory filter, uint page, uint itemsPerPage)
        external
        view
        returns (TripGatewayTypes.GatewayAllTripsDTO memory)
    {
        return tripQuery.getAllTrips(filter, page, itemsPerPage);
    }

    function createTripRequestWithDelivery(
        TripGatewayTypes.GatewayCreateTripRequestWithDelivery memory request,
        string memory promo
    ) external payable {
        tripMainFacet1.createTripRequestWithDelivery{value: msg.value}(
            request,
            promo,
            _msgGatewaySender()
        );
    }


    function calculatePaymentsWithDelivery(
        uint256 carId,
        uint64 daysOfTrip,
        address currency,
        LocationInfo memory pickUpLocation,
        LocationInfo memory returnLocation,
        string memory promo
    ) external view returns (TripGatewayTypes.GatewayCalculatePaymentsDTO memory) {
        return tripMainFacet1.calculatePaymentsWithDelivery(
            carId,
            daysOfTrip,
            currency,
            pickUpLocation,
            returnLocation,
            promo,
            _msgGatewaySender()
        );
    }
    function approveTripRequest(uint256 tripId) external {
        tripMainFacet1.approveTripRequest(tripId, _msgGatewaySender());
    }

    function rejectTripRequest(uint256 tripId) external {
        tripMainFacet1.rejectTripRequest(tripId, _msgGatewaySender());
    }

    function confirmCheckOut(uint256 tripId) external {
        tripMainFacet1.confirmCheckOut(tripId, _msgGatewaySender());
    }

    function payToHost(uint256 tripId) external {
        tripMainFacet1.confirmCheckOut(tripId, _msgGatewaySender());
    }

    function refundToGuest(uint256 tripId) external {
        tripMainFacet1.rejectTripRequest(tripId, _msgGatewaySender());
    }

    function finishTrip(uint256 tripId) external {
        tripMainFacet1.finishTrip(tripId, _msgGatewaySender());
    }

    function checkInByHost(
        uint256 tripId,
        uint64[] memory panelParams,
        string memory insuranceCompany,
        string memory insuranceNumber
    ) external {
        tripMainFacet1.checkInByHost(tripId, panelParams, insuranceCompany, insuranceNumber, _msgGatewaySender());
    }

    function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external {
        tripMainFacet1.checkInByGuest(tripId, panelParams, _msgGatewaySender());
    }

    function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external {
        tripMainFacet1.checkOutByGuest(tripId, panelParams, _msgGatewaySender());
    }

    function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external {
        tripMainFacet1.checkOutByHost(tripId, panelParams, _msgGatewaySender());
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
    }


    function _setServiceAddresses(
        address tripQueryAddress,
        address tripMainFacet1Address,
        address userProfileMainAddress
    ) internal {
        tripQuery = TripQuery(tripQueryAddress);
        tripMainFacet1 = TripMainFacet1(tripMainFacet1Address);
        userProfileMain = ITripGatewayFacetUserProfileMain(userProfileMainAddress);
    }


}
















