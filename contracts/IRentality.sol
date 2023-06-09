// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityCarToken.sol";
import "./RentalityTripService.sol";

interface IRentality {
    struct CreateTripRequest {
        uint256 carId;
        address host;
        uint64 startDateTime;
        uint64 endDateTime;
        string startLocation;
        string endLocation;
        uint64 totalDayPriceInUsdCents;
        uint64 taxPriceInUsdCents;
        uint64 depositInUsdCents;
        int256 ethToCurrencyRate;
        uint8 ethToCurrencyDecimals;
        uint64 fuelPricePerGalInUsdCents;
    }

    ///admin functions
    function owner() external view returns (address);
    function getCarServiceAddress() external view returns (address);
    function updateCarService(address contractAddress) external;
    function getCurrencyConverterServiceAddress() external view returns (address);
    function updateCurrencyConverterService(address contractAddress) external;
    function getTripServiceAddress() external view returns (address);
    function updateTripService(address contractAddress) external;
    function getUserServiceAddress() external view returns (address);
    function updateUserService(address contractAddress) external;
    function withdrawFromPlatform(uint256 amount) external;
    function withdrawAllFromPlatform() external;
    function getPlatformFeeInPPM() external view returns (uint32);
    function setPlatformFeeInPPM(uint32 valueInPPM) external;
    function getDepositePriceInUsdCents() external view returns (uint32);
    function setDepositePriceInUsdCents(uint32 valueInUsdCents) external;
    function getFuelPricePerGalInUsdCents() external view returns (uint32);
    function setFuelPricePerGalInUsdCents(uint32 valueInUsdCents) external;

    ///host functions
    function addCar(
        string memory tokenUri,
        string memory carVinNumber,
        uint64 pricePerDayInUsdCents,
        uint64 tankVolumeInGal,
        uint64 distanceIncludedInMi
    ) external returns (uint);
    function getCarMetadataURI(uint256 carId) external view returns (string memory);
    function getMyCars() external view returns (RentalityCarToken.CarInfo[] memory);
    function getTripsAsHost() external view returns (RentalityTripService.Trip[] memory);
    function approveTripRequest(uint256 tripId) external;
    function rejectTripRequest(uint256 tripId) external;
    function checkInByHost(uint256 tripId, uint64 startFuelLevel, uint64 startOdometr) external;
    function checkOutByHost(uint256 tripId, uint64 endFuelLevel, uint64 endOdometr) external;
    function finishTrip(uint256 tripId) external;

    ///guest functions
    function getAvailableCars() external view returns (RentalityCarToken.CarInfo[] memory);
    function createTripRequest(CreateTripRequest memory request) external payable;
    function getTripsAsGuest() external view returns (RentalityTripService.Trip[] memory);
    function getCarsRentedByMe() external view returns (RentalityCarToken.CarInfo[] memory);
    function checkInByGuest(uint256 tripId, uint64 startFuelLevel, uint64 startOdometr) external;
    function checkOutByGuest(uint256 tripId, uint64 endFuelLevel, uint64 endOdometr) external;

}
