// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityCarToken.sol";
import "./RentalityTripService.sol";

interface IRentality {
    
    struct CreateTripRequest {
        uint256 carId;
        address host;
        uint256 startDateTime;
        uint256 endDateTime;
        string startLocation;
        string endLocation;
        uint256 totalDayPriceInUsdCents;
        uint256 taxPriceInUsdCents;
        uint256 depositInUsdCents;
        int256 ethToCurrencyRate;
        uint8 ethToCurrencyDecimals;
    }

    ///host functions 
    function addCar(string memory tokenUri,
        string memory carVinNumber,
        uint256 pricePerDayInUsdCents,
        uint256 tankVolumeInGal,
        uint256 distanceIncludedInMi) external returns (uint);
    function getCarMetadataURI(uint256 carId) external view returns (string memory);
    function getMyCars() external view returns(RentalityCarToken.CarInfo[] memory);
    function getTripsAsHost() external view returns (RentalityTripService.Trip[] memory);
    function approveTripRequest(uint256 tripId) external;
    function rejectTripRequest(uint256 tripId) external;
    function checkInByHost(uint256 tripId, uint256 startFuelLevel, uint256 startOdometr) external;
    function checkOutByHost(uint256 tripId,uint256 endFuelLevel,uint256 endOdometr) external;
    function finishTrip(uint256 tripId) external;
    function resolveIssue(uint256 tripId, uint256 fuelPricePerGal) external;

    ///guest functions 
    function getAvailableCars() external view returns (RentalityCarToken.CarInfo[] memory);
    function createTripRequest(CreateTripRequest memory request) external payable;
    function getTripsAsGuest() external view returns (RentalityTripService.Trip[] memory);
    function getCarsRentedByMe() external view returns(RentalityCarToken.CarInfo[] memory);
    function checkInByGuest(uint256 tripId,uint256 startFuelLevel,uint256 startOdometr) external;
    function checkOutByGuest(uint256 tripId,uint256 endFuelLevel,uint256 endOdometr) external;
}