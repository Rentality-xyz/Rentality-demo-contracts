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
        uint256 ethToCurrencyRate;
        uint256 ethToCurrencyDecimals;
    }

    ///host functions 
    function addCar(string memory tokenUri,
        string memory carVinNumber,
        uint256 pricePerDayInUsdCents,
        uint256 tankVolumeInGal,
        uint256 distanceIncludedInMi) external returns (uint);
    function getMyCars() external view returns(RentalityCarToken.CarInfo[] memory);
    function getTripsAsHost() external view returns (RentalityTripService.Trip[] memory);
    function approveTripRequest(uint256 tripId) external;
    function rejectTripRequest(uint256 tripId) external;
    
    ///guest functions 
    function getAvailableCars() external view returns (RentalityCarToken.CarInfo[] memory);
    function createTripRequest(CreateTripRequest memory request) external payable;
    function getCarsRentedByMe() external view returns(RentalityCarToken.CarInfo[] memory);
    function finishTrip(uint256 tripId) external;
}