// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import './IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './RentalityPlatform.sol';
import './RentalityPaymentService.sol';


/// @title RentalityGateway
/// @notice The main gateway contract that connects various services in the Rentality platform.
/// Users can interact with the car service, trip service, user service, and payment service through this gateway.
/// Admins can update the addresses of connected services.
/// Hosts and guests can perform actions related to car rentals and trips.

//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
//deployed 27.06.2023 11:10 to sepolia at 0x18744A3f7D15930446B1dbc5A837562e468B2D8d
contract RentalityGateway is Ownable, Initializable, UUPSUpgradeable  {
    RentalityCarToken private carService;
    RentalityCurrencyConverter private currencyConverterService;
    RentalityTripService private tripService;
    RentalityUserService private userService;
    RentalityPlatform private rentalityPlatform;
    RentalityPaymentService private paymentService;


    constructor() {}
    /// @notice Ensures that the caller is either an admin, the contract owner, or an admin from the origin transaction.
    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) ||
            userService.isAdmin(tx.origin) ||
            (tx.origin == owner()),
            'User is not an admin'
        );
        _;
    }

    /// @notice Ensures that the caller is a host.
    modifier onlyHost() {
        require(userService.isHost(msg.sender), 'User is not a host');
        _;
    }

    /// @notice Ensures that the caller is a guest.
    modifier onlyGuest() {
        require(userService.isGuest(msg.sender), 'User is not a guest');
        _;
    }

    /// @notice Ensures that the caller is either a host or a guest.
    modifier onlyHostOrGuest() {
        require(
            userService.isHost(msg.sender) || userService.isGuest(msg.sender),
            'User is not a host or guest'
        );
        _;
    }

    /// @notice Retrieves the address of the RentalityCarToken contract.
    /// @return The address of the RentalityCarToken contract.
    function getCarServiceAddress() public view returns (address) {
        return address(carService);
    }

    /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityCarToken contract.
    function updateCarService(address contractAddress) public onlyAdmin {
        carService = RentalityCarToken(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityPlatform contract.
    /// @return The address of the RentalityPlatform contract.
    function getRentalityPlatformAddress() public view returns (address) {
        return address(rentalityPlatform);
    }

    /// @notice Updates the address of the RentalityPlatform contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityPlatform contract.
    function updateRentalityPlatform(address contractAddress) public onlyAdmin {
        rentalityPlatform = RentalityPlatform(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityCurrencyConverter contract.
    /// @return The address of the RentalityCurrencyConverter contract.
    function getCurrencyConverterServiceAddress()
    public
    view
    returns (address)
    {
        return address(currencyConverterService);
    }

    /// @notice Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityCurrencyConverter contract.
    function updateCurrencyConverterService(
        address contractAddress
    ) public onlyAdmin {
        currencyConverterService = RentalityCurrencyConverter(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityTripService contract.
    /// @return The address of the RentalityTripService contract.
    function getTripServiceAddress() public view returns (address) {
        return address(tripService);
    }

    /// @notice Updates the address of the RentalityTripService contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityTripService contract.
    function updateTripService(address contractAddress) public onlyAdmin {
        tripService = RentalityTripService(contractAddress);
    }

    /// @notice Retrieves the address of the RentalityUserService contract.
    /// @return The address of the RentalityUserService contract.
    function getUserServiceAddress() public view returns (address) {
        return address(userService);
    }

    /// @notice Updates the address of the RentalityUserService contract. Only callable by admins.
    /// @param contractAddress The new address of the RentalityUserService contract.
    function updateUserService(address contractAddress) public onlyAdmin {
        userService = RentalityUserService(contractAddress);
    }

    /// @notice Retrieves the platform fee in parts per million (PPM).
    /// @return The platform fee in PPM.
    function getPlatformFeeInPPM() public view returns (uint32) {
        return paymentService.getPlatformFeeInPPM();
    }

    /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
    /// @param valueInPPM The new platform fee value in PPM.
    function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
        paymentService.setPlatformFeeInPPM(valueInPPM);
    }

    /// @notice Retrieves the platform fee calculated from the given value.
    /// @param value The value from which to calculate the platform fee.
    /// @return The calculated platform fee.
    function getPlatformFeeFrom(uint64 value) private view returns (uint64) {
        return paymentService.getPlatformFeeFrom(value);
    }

    /// @notice Withdraws the specified amount from the RentalityPlatform contract.
    /// @param amount The amount to withdraw.
    function withdrawFromPlatform(uint256 amount) public {
        rentalityPlatform.withdrawFromPlatform(amount);
    }

    /// @notice Withdraws the entire balance from the RentalityPlatform contract.
    function withdrawAllFromPlatform() public {
        rentalityPlatform.withdrawFromPlatform(address(this).balance);
    }

    /// @notice Retrieves information about a car by its ID.
    /// @param carId The ID of the car.
    /// @return Car information as a struct.
    function getCarInfoById(
        uint256 carId
    ) public view returns (RentalityCarToken.CarInfo memory) {
        return carService.getCarInfoById(carId);
    }

    /// @notice Retrieves the metadata URI of a car by its ID.
    /// @param carId The ID of the car.
    /// @return The metadata URI of the car.
    function getCarMetadataURI(
        uint256 carId
    ) public view returns (string memory) {
        return carService.tokenURI(carId);
    }

    /// @notice Adds a new car using the provided request. Grants host role to the caller if not already a host.
    /// @param request The request containing car information.
    /// @return The ID of the newly added car.
    function addCar(
        RentalityCarToken.CreateCarRequest memory request
    ) public returns (uint) {
        if (!userService.isHost(msg.sender)) {
            userService.grantHostRole(msg.sender);
        }
        return carService.addCar(request);
    }

    /// @notice Updates the information of a car. Only callable by hosts.
    /// @param request The request containing updated car information.
    function updateCarInfo(
        RentalityCarToken.UpdateCarInfoRequest memory request
    ) public onlyHost {
        return carService.updateCarInfo(request, "", "");
    }

    /// @notice Updates the information of a car, including location details. Only callable by hosts.
    /// @param request The request containing updated car information.
    /// @param location The new location of the car.
    /// @param geoApiKey The API key for geocoding purposes.
    function updateCarInfoWithLocation(
        RentalityCarToken.UpdateCarInfoRequest memory request,
        string memory location,
        string memory geoApiKey
    ) public onlyHost {
        return carService.updateCarInfo(request, location, geoApiKey);
    }

    // function updateCarInfo(
    //     RentalityCarToken.UpdateCarInfoRequest memory request
    // ) public onlyHost {
    //     return
    //         carService.updateCarInfo(
    //             request.carId,
    //             request.pricePerDayInUsdCents,
    //             request.securityDepositPerTripInUsdCents,
    //             request.fuelPricePerGalInUsdCents,
    //             request.milesIncludedPerDay,
    //             request.country,
    //             request.state,
    //             request.city,
    //             request.locationLatitudeInPPM,
    //             request.locationLongitudeInPPM,
    //             request.currentlyListed
    //         );
    // }

    /// @notice Updates the token URI of a car. Only callable by hosts.
    /// @param carId The ID of the car to update.
    /// @param tokenUri The new token URI.
    function updateCarTokenUri(
        uint256 carId,
        string memory tokenUri
    ) public onlyHost {
        return carService.updateCarTokenUri(carId, tokenUri);
    }

    /// @notice Burns (disables) a car. Only callable by hosts.
    /// @param carId The ID of the car to burn.
    function burnCar(uint256 carId) public onlyHost {
        return carService.burnCar(carId);
    }

    /// @notice Retrieves information about all cars.
    /// @return An array of car information.
    function getAllCars()
    public
    view
    returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getAllCars();
    }

    /// @notice Retrieves information about available cars.
    /// @return An array of available car information.
    function getAvailableCars()
    public
    view
    returns (RentalityCarToken.CarInfo[] memory)
    {
        return getAvailableCarsForUser(tx.origin);
    }

    /// @notice Retrieves information about available cars for a specific user.
    /// @param user The address of the user.
    /// @return An array of available car information for the specified user.
    function getAvailableCarsForUser(
        address user
    ) public view returns (RentalityCarToken.CarInfo[] memory) {
        return carService.getAvailableCarsForUser(user);
    }

    /// @notice Searches for available cars based on specified criteria.
    /// @param startDateTime The start date and time of the search.
    /// @param endDateTime The end date and time of the search.
    /// @param searchParams Additional search parameters.
    /// @return An array of available car information meeting the search criteria.
    function searchAvailableCars(
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) public view returns (RentalityTripService.AvailableCarResponse[] memory) {
        return
            searchAvailableCarsForUser(
            tx.origin,
            startDateTime,
            endDateTime,
            searchParams
        );
    }

    /// @notice Searches for available cars for a specific user based on specified criteria.
    /// @param user The address of the user.
    /// @param startDateTime The start date and time of the search.
    /// @param endDateTime The end date and time of the search.
    /// @param searchParams Additional search parameters.
    /// @return An array of available car information meeting the search criteria for the specified user.
    function searchAvailableCarsForUser(
        address user,
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) public view returns (RentalityTripService.AvailableCarResponse[] memory) {
        return
            tripService.searchAvailableCarsForUser(
            user,
            startDateTime,
            endDateTime,
            searchParams
        );
    }

    /// @notice Retrieves information about cars owned by the caller.
    /// @return An array of car information owned by the caller.
    function getMyCars()
    public
    view
    returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getCarsOwnedByUser(tx.origin);
    }

    /// @notice Creates a trip request. Callable by users with payment.
    /// @param request The trip request details.
    function createTripRequest(
        IRentalityGateway.CreateTripRequest memory request
    ) public payable {
        return rentalityPlatform.createTripRequest{value: msg.value}(request);
    }

    /// @notice Retrieves contact information for a trip. Only callable by hosts or guests.
    /// @param tripId The ID of the trip.
    /// @return guestPhoneNumber
    /// @return hostPhoneNumber
    /// The guest's and host's phone numbers.
    function getTripContactInfo(
        uint256 tripId
    )
    public
    view
    onlyHostOrGuest
    returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        return rentalityPlatform.getTripContactInfo(tripId);
    }

    /// @notice Approves a trip request. Only callable by hosts.
    /// @param tripId The ID of the trip to approve.
    function approveTripRequest(uint256 tripId) public {
        return rentalityPlatform.approveTripRequest(tripId);
    }

    /// @notice Rejects a trip request. Only callable by hosts.
    /// @param tripId The ID of the trip to reject.
    function rejectTripRequest(uint256 tripId) public {
        return rentalityPlatform.rejectTripRequest(tripId);
    }

    /// @notice Performs check-in by the host for a trip.
    /// @param tripId The ID of the trip.
    /// @param startFuelLevelInPermille The starting fuel level in permille.
    /// @param startOdometr The starting odometer reading.
    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        return
            tripService.checkInByHost(
            tripId,
            startFuelLevelInPermille,
            startOdometr
        );
    }

    /// @notice Performs check-in by the guest for a trip.
    /// @param tripId The ID of the trip.
    /// @param startFuelLevelInPermille The starting fuel level in permille.
    /// @param startOdometr The starting odometer reading.
    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        return
            tripService.checkInByGuest(
            tripId,
            startFuelLevelInPermille,
            startOdometr
        );
    }

    /// @notice Performs check-out by the guest for a trip.
    /// @param tripId The ID of the trip.
    /// @param endFuelLevelInPermille The ending fuel level in permille.
    /// @param endOdometr The ending odometer reading.
    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        return
            tripService.checkOutByGuest(
            tripId,
            endFuelLevelInPermille,
            endOdometr
        );
    }

    /// @notice Performs check-out by the host for a trip.
    /// @param tripId The ID of the trip.
    /// @param endFuelLevelInPermille The ending fuel level in permille.
    /// @param endOdometr The ending odometer reading.
    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        return
            tripService.checkOutByHost(
            tripId,
            endFuelLevelInPermille,
            endOdometr
        );
    }

    /// @notice Finishes a trip. Only callable by RentalityPlatform.
    /// @param tripId The ID of the trip to finish.
    function finishTrip(uint256 tripId) public {
        return rentalityPlatform.finishTrip(tripId);
    }

    /// @notice Retrieves information about a trip by ID.
    /// @param tripId The ID of the trip.
    /// @return Trip information.
    function getTrip(
        uint256 tripId
    ) public view returns (RentalityTripService.Trip memory) {
        return tripService.getTrip(tripId);
    }

    /// @notice Retrieves information about trips where the caller is the guest.
    /// @return An array of trip information.
    function getTripsAsGuest()
    public
    view
    returns (RentalityTripService.Trip[] memory)
    {
        return tripService.getTripsByGuest(tx.origin);
    }

    /// @notice Retrieves information about trips where the specified user is the guest.
    /// @param guest The address of the guest.
    /// @return An array of trip information for the specified guest.
    function getTripsByGuest(
        address guest
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByGuest(guest);
    }

    /// @notice Retrieves information about trips where the caller is the host.
    /// @return An array of trip information.
    function getTripsAsHost()
    public
    view
    returns (RentalityTripService.Trip[] memory)
    {
        return tripService.getTripsByHost(tx.origin);
    }

    /// @notice Retrieves information about trips where the specified user is the host.
    /// @param host The address of the host.
    /// @return An array of trip information for the specified host.
    function getTripsByHost(
        address host
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByHost(host);
    }

    /// @notice Retrieves information about trips for a specific car.
    /// @param carId The ID of the car.
    /// @return An array of trip information for the specified car.
    function getTripsByCar(
        uint256 carId
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByCar(carId);
    }

    /// @notice Sets Know Your Customer (KYC) information for the caller.
    /// @param name The name of the user.
    /// @param surname The surname of the user.
    /// @param mobilePhoneNumber The mobile phone number of the user.
    /// @param profilePhoto The URL of the user's profile photo.
    /// @param licenseNumber The user's license number.
    /// @param expirationDate The expiration date of the user's license.
    function setKYCInfo(
        string memory name,
        string memory surname,
        string memory mobilePhoneNumber,
        string memory profilePhoto,
        string memory licenseNumber,
        uint64 expirationDate
    ) public {
        return
            userService.setKYCInfo(
            name,
            surname,
            mobilePhoneNumber,
            profilePhoto,
            licenseNumber,
            expirationDate
        );
    }

    /// @notice Retrieves KYC information for the specified user.
    /// @param user The address of the user.
    /// @return KYC information for the specified user.
    function getKYCInfo(
        address user
    ) external view returns (RentalityUserService.KYCInfo memory) {
        return userService.getKYCInfo(user);
    }

    /// @notice Retrieves KYC information for the caller.
    /// @return KYC information for the caller.
    function getMyKYCInfo()
    external
    view
    returns (RentalityUserService.KYCInfo memory)
    {
        return userService.getMyKYCInfo();
    }

    /// @notice Retrieves chat information for the caller acting as a host.
    /// @return An array of chat information.
    function getChatInfoForHost()
    public
    view
    returns (IRentalityGateway.ChatInfo[] memory)
    {
        return rentalityPlatform.getChatInfoForHost();
    }

    /// @notice Retrieves chat information for the caller acting as a guest.
    /// @return An array of chat information.
    function getChatInfoForGuest()
    public
    view
    returns (IRentalityGateway.ChatInfo[] memory)
    {
        return rentalityPlatform.getChatInfoForGuest();
    }

    //Proxy

    function _authorizeUpgrade(address newImplementation) internal override
    {
//        require(owner == msg.sender, "Only for owner.");
    }

    function initialize(  address carServiceAddress,
        address currencyConverterServiceAddress,
        address tripServiceAddress,
        address userServiceAddress,
        address rentalityPlatformAddress,
        address paymentServiceAddress) public initializer  {

        carService = RentalityCarToken(carServiceAddress);
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
        tripService = RentalityTripService(tripServiceAddress);
        userService = RentalityUserService(userServiceAddress);
        rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
        paymentService = RentalityPaymentService(paymentServiceAddress);

    }
}
