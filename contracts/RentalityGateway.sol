// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRentalityGateway.sol";
import "./RentalityCarToken.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityPlatform.sol";
import "./RentalityPaymentService.sol";

//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
//deployed 27.06.2023 11:10 to sepolia at 0x18744A3f7D15930446B1dbc5A837562e468B2D8d
contract RentalityGateway is Ownable {
    RentalityCarToken private carService;
    RentalityCurrencyConverter private currencyConverterService;
    RentalityTripService private tripService;
    RentalityUserService private userService;
    RentalityPlatform private rentalityPlatform;
    RentalityPaymentService private paymentService;

    constructor(
        address carServiceAddress,
        address currencyConverterServiceAddress,
        address tripServiceAddress,
        address userServiceAddress,
        address rentalityPlatformAddress,
        address paymentServiceAddress
    ) {
        carService = RentalityCarToken(carServiceAddress);
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
        tripService = RentalityTripService(tripServiceAddress);
        userService = RentalityUserService(userServiceAddress);
        rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
        paymentService = RentalityPaymentService(paymentServiceAddress);
    }

    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) ||
                userService.isAdmin(tx.origin) ||
                (tx.origin == owner()),
            "User is not an admin"
        );
        _;
    }

    modifier onlyHost() {
        require(userService.isHost(msg.sender), "User is not a host");
        _;
    }

    modifier onlyGuest() {
        require(userService.isGuest(msg.sender), "User is not a guest");
        _;
    }

    modifier onlyHostOrGuest() {
        require(
            userService.isHost(msg.sender) || userService.isGuest(msg.sender),
            "User is not a host or guest"
        );
        _;
    }

    function getCarServiceAddress() public view returns (address) {
        return address(carService);
    }

    function updateCarService(address contractAddress) public onlyAdmin {
        carService = RentalityCarToken(contractAddress);
    }

    function getRentalityPlatformAddress() public view returns (address) {
        return address(rentalityPlatform);
    }

    function updateRentalityPlatform(address contractAddress) public onlyAdmin {
        rentalityPlatform = RentalityPlatform(contractAddress);
    }

    function getCurrencyConverterServiceAddress()
        public
        view
        returns (address)
    {
        return address(currencyConverterService);
    }

    function updateCurrencyConverterService(
        address contractAddress
    ) public onlyAdmin {
        currencyConverterService = RentalityCurrencyConverter(contractAddress);
    }

    function getTripServiceAddress() public view returns (address) {
        return address(tripService);
    }

    function updateTripService(address contractAddress) public onlyAdmin {
        tripService = RentalityTripService(contractAddress);
    }

    function getUserServiceAddress() public view returns (address) {
        return address(userService);
    }

    function updateUserService(address contractAddress) public onlyAdmin {
        userService = RentalityUserService(contractAddress);
    }

    function getPlatformFeeInPPM() public view returns (uint32) {
        return paymentService.getPlatformFeeInPPM();
    }

    function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
        paymentService.setPlatformFeeInPPM(valueInPPM);
    }

    function getPlatformFeeFrom(uint64 value) private view returns (uint64) {
        return paymentService.getPlatformFeeFrom(value);
    }

    function withdrawFromPlatform(uint256 amount) public {
        rentalityPlatform.withdrawFromPlatform(amount);
    }

    function withdrawAllFromPlatform() public {
        return rentalityPlatform.withdrawFromPlatform(address(this).balance);
    }

    function getCarInfoById(
        uint256 carId
    ) public view returns (RentalityCarToken.CarInfo memory) {
        return carService.getCarInfoById(carId);
    }

    function getCarMetadataURI(
        uint256 carId
    ) public view returns (string memory) {
        return carService.tokenURI(carId);
    }

    function addCar(
        RentalityCarToken.CreateCarRequest memory request
    ) public returns (uint) {
        if (!userService.isHost(msg.sender)) {
            userService.grantHostRole(msg.sender);
        }
        return carService.addCar(request);
    }

    function updateCarInfo(
        RentalityCarToken.UpdateCarInfoRequest memory request
    ) public onlyHost {
        return
            carService.updateCarInfo(
                request.carId,
                request.pricePerDayInUsdCents,
                request.securityDepositPerTripInUsdCents,
                request.fuelPricePerGalInUsdCents,
                request.milesIncludedPerDay,
                request.country,
                request.state,
                request.city,
                request.locationLatitudeInPPM,
                request.locationLongitudeInPPM,
                request.currentlyListed
            );
    }

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
    ) public onlyHost {
        return
            carService.updateCarInfo(
                carId,
                pricePerDayInUsdCents,
                securityDepositPerTripInUsdCents,
                fuelPricePerGalInUsdCents,
                milesIncludedPerDay,
                country,
                state,
                city,
                locationLatitudeInPPM,
                locationLongitudeInPPM,
                currentlyListed
            );
    }

    function updateCarTokenUri(
        uint256 carId,
        string memory tokenUri
    ) public onlyHost {
        return carService.updateCarTokenUri(carId, tokenUri);
    }

    function burnCar(uint256 carId) public onlyHost {
        return carService.burnCar(carId);
    }

    function getAllCars()
        public
        view
        returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getAllCars();
    }

    function getAvailableCars()
        public
        view
        returns (RentalityCarToken.CarInfo[] memory)
    {
        return getAvailableCarsForUser(tx.origin);
    }

    function getAvailableCarsForUser(
        address user
    ) public view returns (RentalityCarToken.CarInfo[] memory) {
        return carService.getAvailableCarsForUser(user);
    }

    function searchAvailableCars(
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) public view returns (RentalityCarToken.CarInfo[] memory) {
        return
            searchAvailableCarsForUser(
                tx.origin,
                startDateTime,
                endDateTime,
                searchParams
            );
    }

    function searchAvailableCarsForUser(
        address user,
        uint64 startDateTime,
        uint64 endDateTime,
        RentalityCarToken.SearchCarParams memory searchParams
    ) public view returns (RentalityCarToken.CarInfo[] memory) {
        return
            tripService.searchAvailableCarsForUser(
                user,
                startDateTime,
                endDateTime,
                searchParams
            );
    }

    function getMyCars()
        public
        view
        returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getCarsOwnedByUser(tx.origin);
    }


    function createTripRequest(
        IRentalityGateway.CreateTripRequest memory request
    ) public payable {
        return rentalityPlatform.createTripRequest{value: msg.value}(request);
    }

    function getTripContactInfo(uint256 tripId)
        public
        view
        onlyHostOrGuest
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        return rentalityPlatform.getTripContactInfo(tripId);
    }

    function approveTripRequest(uint256 tripId) public {
        return rentalityPlatform.approveTripRequest(tripId);
    }

    function rejectTripRequest(uint256 tripId) public {
        return rentalityPlatform.rejectTripRequest(tripId);
    }

    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        return tripService.checkInByHost(tripId, startFuelLevelInPermille, startOdometr);
    }

    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        return tripService.checkInByGuest(tripId, startFuelLevelInPermille, startOdometr);
    }

    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        return tripService.checkOutByGuest(tripId, endFuelLevelInPermille, endOdometr);
    }

    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        return tripService.checkOutByHost(tripId, endFuelLevelInPermille, endOdometr);
    }

    function finishTrip(uint256 tripId) public {
        return rentalityPlatform.finishTrip(tripId);
    }

    function getTrip(
        uint256 tripId
    ) public view returns (RentalityTripService.Trip memory) {
        return tripService.getTrip(tripId);
    }

    function getTripsAsGuest()
        public
        view
        returns (RentalityTripService.Trip[] memory)
    {
        return tripService.getTripsByGuest(tx.origin);
    }

    function getTripsByGuest(
        address guest
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByGuest(guest);
    }

    function getTripsAsHost()
        public
        view
        returns (RentalityTripService.Trip[] memory)
    {
        return tripService.getTripsByHost(tx.origin);
    }

    function getTripsByHost(
        address host
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByHost(host);
    }

    function getTripsByCar(
        uint256 carId
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByCar(carId);
    }

    function setKYCInfo(
        string memory name,
        string memory surname,
        string memory mobilePhoneNumber,
        string memory profilePhoto,
        string memory licenseNumber,
        uint64 expirationDate
    ) public {
         return userService.setKYCInfo(name, surname, mobilePhoneNumber, profilePhoto, licenseNumber, expirationDate);
    }

    function getKYCInfo(address user) external view returns (RentalityUserService.KYCInfo memory) {
         return userService.getKYCInfo(user);
    }

    function getMyKYCInfo() external view returns (RentalityUserService.KYCInfo memory) {
         return userService.getMyKYCInfo();
    }
}
