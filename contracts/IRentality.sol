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
        uint64 fuelPricePerGalInUsdCents;
        int256 ethToCurrencyRate;
        uint8 ethToCurrencyDecimals;
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

    ///host functions
    function addCar(RentalityCarToken.CreateCarRequest memory request) external returns (uint);
    function updateCarInfo(RentalityCarToken.UpdateCarInfoRequest memory request) external;
    function updateCarInfo(
        uint256 carId,
        uint64 pricePerDayInUsdCents,
        uint64 securityDepositPerTripInUsdCents,
        uint64 fuelPricePerGalInUsdCents,
        uint64 milesIncludedPerDay,
        string memory country,
        string memory state,
        string memory city,
        int64 locationLatitudeInPPM,
        int64 locationLongitudeInPPM,
        bool currentlyListed
    ) external;
    function getCarMetadataURI(uint256 carId) external view returns (string memory);
    function getCarInfoById(uint256 carId) external view returns (RentalityCarToken.CarInfo memory);
    function getMyCars() external view returns (RentalityCarToken.CarInfo[] memory);
    function getTripsAsHost() external view returns (RentalityTripService.Trip[] memory);
    function approveTripRequest(uint256 tripId) external;
    function rejectTripRequest(uint256 tripId) external;
    function checkInByHost(uint256 tripId, uint64 startFuelLevelInPermille, uint64 startOdometr) external;
    function checkOutByHost(uint256 tripId, uint64 endFuelLevelInPermille, uint64 endOdometr) external;
    function finishTrip(uint256 tripId) external;

    ///guest functions
    function getAvailableCars() external view returns (RentalityCarToken.CarInfo[] memory);
    function searchAvailableCars(uint64 startDateTime, uint64 endDateTime, RentalityCarToken.SearchCarParams memory searchParams) external view returns (RentalityCarToken.CarInfo[] memory);

    function createTripRequest(CreateTripRequest memory request) external payable;
    function getTripsAsGuest() external view returns (RentalityTripService.Trip[] memory);
    function getCarsRentedByMe() external view returns (RentalityCarToken.CarInfo[] memory);
    function checkInByGuest(uint256 tripId, uint64 startFuelLevelInPermille, uint64 startOdometr) external;
    function checkOutByGuest(uint256 tripId, uint64 endFuelLevelInPermille, uint64 endOdometr) external;

    function getTrip(uint256 tripId) external view returns (RentalityTripService.Trip memory);

    function getTripContactInfo(uint256 tripId)
        external
        view
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber);
    function setKYCInfo(
        string memory name,
        string memory surname,
        string memory mobilePhoneNumber,
        string memory profilePhoto,
        string memory licenseNumber,
        uint64 expirationDate
    ) external;
    function getKYCInfo(address user) external view returns (RentalityUserService.KYCInfo memory);
    function getMyKYCInfo() external view returns (RentalityUserService.KYCInfo memory);
}
