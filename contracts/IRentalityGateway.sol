// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityCarToken.sol';
import './RentalityTripService.sol';

interface IRentalityGateway {
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

    struct ChatInfo {
        uint256 tripId;
        address guestAddress;
        string guestName;
        string guestPhotoUrl;
        address hostAddress;
        string hostName;
        string hostPhotoUrl;
        uint256 tripStatus;
        string carBrand;
        string carModel;
        uint32 carYearOfProduction;
        string carMetadataUrl;
    }

    ///admin functions
    function getCarServiceAddress() external view returns (address);

    function updateCarService(address contractAddress) external;

    function getCurrencyConverterServiceAddress()
        external
        view
        returns (address);

    function updateCurrencyConverterService(address contractAddress) external;

    function getTripServiceAddress() external view returns (address);

    function updateTripService(address contractAddress) external;

    function getUserServiceAddress() external view returns (address);

    function updateUserService(address contractAddress) external;

    function getRentalityPlatformAddress() external view returns (address);

    function updateRentalityPlatform(address contractAddress) external;

    function withdrawFromPlatform(uint256 amount) external;

    function withdrawAllFromPlatform() external;

    function getPlatformFeeInPPM() external view returns (uint32);

    function setPlatformFeeInPPM(uint32 valueInPPM) external;

    ///host functions
    function addCar(
        RentalityCarToken.CreateCarRequest memory request
    ) external returns (uint);

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

    function getCarMetadataURI(
        uint256 carId
    ) external view returns (string memory);

    function getCarInfoById(
        uint256 carId
    ) external view returns (RentalityCarToken.CarInfo memory);

    function getMyCars()
        external
        view
        returns (RentalityCarToken.CarInfo[] memory);

    function getTripsAsHost()
        external
        view
        returns (RentalityTripService.Trip[] memory);

    function approveTripRequest(uint256 tripId) external;

    function rejectTripRequest(uint256 tripId) external;

    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) external;

    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) external;

    function finishTrip(uint256 tripId) external;

    ///guest functions
    function getAvailableCars()
        external
        view
        returns (RentalityCarToken.CarInfo[] memory);

    function searchAvailableCars(
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) external view returns (RentalityCarToken.CarInfo[] memory);

    function createTripRequest(
        CreateTripRequest memory request
    ) external payable;

    function getTripsAsGuest()
        external
        view
        returns (RentalityTripService.Trip[] memory);

    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) external;

    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) external;

    function getTrip(
        uint256 tripId
    ) external view returns (RentalityTripService.Trip memory);

    function getAddressesByTripId(
        uint256 tripId
    ) external view returns (address hostAddress, address guestAddress);

    function getTripContactInfo(
        uint256 tripId
    )
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

    function getKYCInfo(
        address user
    ) external view returns (RentalityUserService.KYCInfo memory);

    function getMyKYCInfo()
        external
        view
        returns (RentalityUserService.KYCInfo memory);
}
