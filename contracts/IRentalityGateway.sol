// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityCarToken.sol';
import './RentalityTripService.sol';


 /// @title RentalityGateway
 /// @notice This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.
 /// @dev All functions in this interface are meant to be implemented by the Rentality Gateway contract.
interface IRentalityGateway {

     /// @dev Struct representing the parameters for creating a trip request.
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
        uint64[] fuelPrices;
        int256 ethToCurrencyRate;
        uint8 ethToCurrencyDecimals;
    }


    /// @dev Struct representing information about a chat related to a trip.
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
        uint64 startDateTime;
        uint64 endDateTime;
    }

    /// @admin functions


    /// @notice Get the address of the Car Service contract.
    /// @return The address of the Car Service contract.
    function getCarServiceAddress() external view returns (address);


     /// @notice Update the Car Service contract address.
     /// @param contractAddress The new address of the Car Service contract.
    function updateCarService(address contractAddress) external;


    /// @notice Get the address of the Currency Converter Service contract.
    /// @return The address of the Currency Converter Service contract.
    function getCurrencyConverterServiceAddress() external view returns (address);


     /// @notice Update the Currency Converter Service contract address.
     /// @param contractAddress The new address of the Currency Converter Service contract.
    function updateCurrencyConverterService(address contractAddress) external;


     /// @notice Get the address of the Trip Service contract.
     /// @return The address of the Trip Service contract.
    function getTripServiceAddress() external view returns (address);


    /// @notice Update the Trip Service contract address.
    /// @param contractAddress The new address of the Trip Service contract.
    function updateTripService(address contractAddress) external;

     /// @notice Get the address of the User Service contract.
     /// @return The address of the User Service contract.
     function getUserServiceAddress() external view returns (address);

     /// @notice Update the User Service contract address.
     /// @param contractAddress The new address of the User Service contract.
    function updateUserService(address contractAddress) external;


    ///  @notice Get the address of the Rentality Platform contract.
    ///  @return The address of the Rentality Platform contract.
    function getRentalityPlatformAddress() external view returns (address);


    /// @notice Update the Rentality Platform contract address.
    /// @param contractAddress The new address of the Rentality Platform contract.
    function updateRentalityPlatform(address contractAddress) external;

    /// @notice Withdraw a specified amount of funds from the platform.
    /// @param amount The amount of funds to withdraw.
    function withdrawFromPlatform(uint256 amount) external;

    /// @notice Withdraw all funds from the platform.
    function withdrawAllFromPlatform() external;

    /// @notice Get the platform fee in parts per million (PPM).
    /// @return The platform fee in PPM.
    function getPlatformFeeInPPM() external view returns (uint32);

    /// @notice Set the platform fee in parts per million (PPM).
    /// @param valueInPPM The new platform fee in PPM.
    function setPlatformFeeInPPM(uint32 valueInPPM) external;

    /// @host functions

    /// @notice Add a new car to the platform.
    /// @param request The request parameters for creating a new car.
    /// @return The ID of the newly added car.
    function addCar(RentalityCarToken.CreateCarRequest memory request) external returns (uint);


    /// @notice Update information for an existing car, without location.
    /// @param request the Update car parameters
    function updateCarInfo(
        RentalityCarToken.UpdateCarInfoRequest memory request
    ) external;

    /// @notice Update information for an existing car with location
    /// @notice This sets geo verification status to false.
    /// @param request the Update car parameters
    /// @param location Single string that contains the car location
    /// @param geoApiKey the key to verify location by google geo api
    function updateCarInfoWithLocation(
        RentalityCarToken.UpdateCarInfoRequest memory request,
        string memory location,
        string memory geoApiKey
    ) external;


    /// @notice Get the metadata URI for a specific car.
    /// @param carId The ID of the car.
    /// @return The metadata URI for the specified car.
    function getCarMetadataURI(uint256 carId) external view returns (string memory);

    /// @notice Get information about a specific car by ID.
    /// @param carId The ID of the car.
    /// @return CarInfo structure containing details about the specified car.
    function getCarInfoById(uint256 carId) external view returns (RentalityCarToken.CarInfo memory);

    /// @notice Get information about all cars owned by the caller.
    /// @return An array of CarInfo structures containing details about the caller's cars.
    function getMyCars() external view returns (RentalityCarToken.CarInfo[] memory);

    /// @notice Get information about all trips where the caller is the host.
    /// @return An array of Trip structures containing details about trips where the caller is the host.
    function getTripsAsHost() external view returns (RentalityTripService.Trip[] memory);

    /// @notice Approve a trip request by its ID.
    /// @param tripId The ID of the trip to approve.
    function approveTripRequest(uint256 tripId) external;

    /// @notice Reject a trip request by its ID.
    /// @param tripId The ID of the trip to reject.
    function rejectTripRequest(uint256 tripId) external;

    /// @notice Perform check-in for a trip as the host.
    /// @param tripId The ID of the trip to check in.
    /// @param startFuelLevelInPermille The start fuel level in permille.
    /// @param startOdometr The start odometer reading.
    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) external;

    /// @notice Perform check-out for a trip as the host.
    /// @param tripId The ID of the trip to check out.
    /// @param endFuelLevelInPermille The end fuel level in permille.
    /// @param endOdometr The end odometer reading.
    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) external;

    /// @notice Finish a trip as the host.
    /// @param tripId The ID of the trip to finish.
    function finishTrip(uint256 tripId) external;

    /// @guest functions

    /// @notice Get information about all available cars.
    /// @return An array of CarInfo structures containing details about available cars.
    function getAvailableCars() external view returns (RentalityCarToken.CarInfo[] memory);

    /// @notice Search for available cars based on specified criteria.
    /// @param startDateTime The start date and time of the trip.
    /// @param endDateTime The end date and time of the trip.
    /// @param searchParams Additional parameters for searching available cars.
    /// @return An array of CarInfo structures containing details about available cars matching the criteria.
    function searchAvailableCars(
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) external view returns (RentalityCarToken.CarInfo[] memory);

    /// @notice Create a trip request.
    /// @param request The request parameters for creating a new trip.
    function createTripRequest(CreateTripRequest memory request) external payable;

    /// @notice Get information about all trips where the caller is the guest.
    /// @return An array of Trip structures containing details about trips where the caller is the guest.
    function getTripsAsGuest() external view returns (RentalityTripService.Trip[] memory);

    /// @notice Perform check-in for a trip as the guest.
    /// @param tripId The ID of the trip to check in.
    /// @param startFuelLevelInPermille The start fuel level in permille.
    /// @param startOdometr The start odometer reading.
    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) external;

    /// @notice Perform check-out for a trip as the guest.
    /// @param tripId The ID of the trip to check out.
    /// @param endFuelLevelInPermille The end fuel level in permille.
    /// @param endOdometr The end odometer reading.
    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) external;

    /// @notice Get information about a specific trip.
    /// @param tripId The ID of the trip.
    /// @return Trip structure containing details about the specified trip.
    function getTrip(uint256 tripId) external view returns (RentalityTripService.Trip memory);

    /// @notice Get the addresses (host and guest) associated with a trip ID.
    /// @param tripId The ID of the trip.
    /// @return hostAddress The address of the host associated with the trip.
    /// @return guestAddress The address of the guest associated with the trip.
    function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress);

    /// @notice Get contact information for a trip.
    /// @param tripId The ID of the trip.
    /// @return guestPhoneNumber The phone number of the guest associated with the trip.
    /// @return hostPhoneNumber The phone number of the host associated with the trip.
    function getTripContactInfo(uint256 tripId) external view returns (string memory guestPhoneNumber, string memory hostPhoneNumber);

    /// @notice Set KYC (Know Your Customer) information for the caller.
    /// @param name The name of the caller.
    /// @param surname The surname of the caller.
    /// @param mobilePhoneNumber The mobile phone number of the caller.
    /// @param profilePhoto The URL of the caller's profile photo.
    /// @param licenseNumber The driver's license number of the caller.
    /// @param expirationDate The expiration date of the caller's driver's license.
    function setKYCInfo(
        string memory name,
        string memory surname,
        string memory mobilePhoneNumber,
        string memory profilePhoto,
        string memory licenseNumber,
        uint64 expirationDate
    ) external;

    /// @notice Get KYC (Know Your Customer) information for a specific user.
    /// @param user The address of the user.
    /// @return KYCInfo structure containing details about the KYC information of the specified user.
    function getKYCInfo(address user) external view returns (RentalityUserService.KYCInfo memory);

    /// @notice Get KYC (Know Your Customer) information for the caller.
    /// @return KYCInfo structure containing details about the KYC information of the caller.
    function getMyKYCInfo() external view returns (RentalityUserService.KYCInfo memory);
}
