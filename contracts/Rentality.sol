// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RentalityCarToken.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityTripService.sol";
import "./RentalityUserService.sol";

contract Rentality is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tripRequestIdCounter;

    struct TripRequest {
        uint256 carId;
        address guest;
        address host;
        uint256 startDateTime;
        uint256 endDateTime;
        string startLocation;
        string endLocation;
        uint256 totalDayPrice;
        uint256 taxPrice;
        uint256 deposit;
    }

    mapping(uint256 => TripRequest) private idToTripRequest;
    RentalityCarToken private carService;
    RentalityCurrencyConverter private currencyConverterService;
    RentalityTripService private tripService;
    RentalityUserService private userService;

    constructor(
        address carServiceAddress,
        address currencyConverterServiceAddress,
        address tripServiceAddress,
        address userServiceAddress
    ) {
        carService = RentalityCarToken(carServiceAddress);
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
        tripService = RentalityTripService(tripServiceAddress);
        userService = RentalityUserService(userServiceAddress);
    }

    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) || (msg.sender == owner()),
            "User is not an admin "
        );
        _;
    }

    modifier onlyHost() {
        require(userService.isHost(msg.sender), "User is not a host ");
        _;
    }

    modifier onlyGuest() {
        require(userService.isGuest(msg.sender), "User is not a guest ");
        _;
    }

    function updateCarService(address carServiceAddress) public onlyAdmin {
        carService = RentalityCarToken(carServiceAddress);
    }

    function updateCurrencyConverterService(
        address currencyConverterServiceAddress
    ) public onlyAdmin {
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
    }

    function updateTripService(address tripServiceAddress) public onlyAdmin {
        tripService = RentalityTripService(tripServiceAddress);
    }

    function updateUserService(address userServiceAddress) public onlyAdmin {
        userService = RentalityUserService(userServiceAddress);
    }

    function totalTripRequestCount() public view returns (uint) {
        return _tripRequestIdCounter.current();
    }

    function getCarInfoById(
        uint256 carId
    ) public view returns (RentalityCarToken.CarInfo memory) {
        return carService.getCarInfoById(carId);
    }

    function addCar(
        string memory tokenUri,
        string memory carVinNumber,
        uint256 pricePerDayInUsdCents,
        uint256 tankVolumeInGal,
        uint256 distanceIncludedInMi
    ) public returns (uint) {
        if (!userService.isHost(msg.sender)){
            userService.grantHostRole(msg.sender);
        }
        return
            carService.addCar(
                tokenUri,
                carVinNumber,
                pricePerDayInUsdCents,
                tankVolumeInGal,
                distanceIncludedInMi
            );
    }

    function updateCarInfo(
        uint256 carId,
        uint256 pricePerDayInUsdCents,
        bool currentlyListed
    ) public onlyHost {
        return
            carService.updateCarInfo(
                carId,
                pricePerDayInUsdCents,
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

    function getAllCars() public view returns (RentalityCarToken.CarInfo[] memory) {
        return carService.getAllCars();
    }

    function getAllAvailableCarsForUser(
        address user
    ) public view returns (RentalityCarToken.CarInfo[] memory) {
        return carService.getAllAvailableCarsForUser(user);
    }

    function getMyCars()
        public
        view
        returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getMyCars();
    }

    function getCarsRentedByMe() public view returns (RentalityCarToken.CarInfo[] memory) {
        return carService.getCarsRentedByMe();
    }

    function addTrip(
        uint256 carId,
        address guest,
        address host,
        uint256 startDateTime,
        uint256 endDateTime,
        string memory startLocation,
        string memory endLocation,
        uint256 milesIncluded,
        uint256 totalDayPrice,
        uint256 taxPrice,
        uint256 deposit,
        bool isAccepted
    ) public {
        return
            tripService.addTrip(
                carId,
                guest,
                host,
                startDateTime,
                endDateTime,
                startLocation,
                endLocation,
                milesIncluded,
                totalDayPrice,
                taxPrice,
                deposit,
                isAccepted
            );
    }

    function checkInByHost(
        uint256 tripId,
        uint256 startFuelLevel,
        uint256 startOdometr
    ) public {
        return
            tripService.checkInByHost(
                tripId,
                startFuelLevel,
                startOdometr
            );
    }

    function checkInByGuest(
        uint256 tripId,
        uint256 startFuelLevel,
        uint256 startOdometr
    ) public {
        return
            tripService.checkInByGuest(
                tripId,
                startFuelLevel,
                startOdometr
            );
    }

    function checkOutByGuest(
        uint256 tripId,
        uint256 endFuelLevel,
        uint256 endOdometr
    ) public {
        return
            tripService.checkOutByGuest(
                tripId,
                endFuelLevel,
                endOdometr
            );
    }

    function checkOutByHost(
        uint256 tripId,
        uint256 endFuelLevel,
        uint256 endOdometr
    ) public {
        return
            tripService.checkOutByHost(
                tripId,
                endFuelLevel,
                endOdometr
            );
    }

    function finishTrip(uint256 tripId) public {
        return tripService.finishTrip(tripId);
    }

    function resolveIssue(uint256 tripId, uint256 fuelPricePerGal) public {
        return tripService.resolveIssue(tripId, fuelPricePerGal);
    }

    function getTrip(uint256 tripId) public view returns (RentalityTripService.Trip memory) {
        return tripService.getTrip(tripId);
    }

    function getTripsByGuest(
        address guest
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByGuest(guest);
    }

    function getTripsByHost(address host) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByHost(host);
    }

    function getTripsByCar(
        uint256 carTokenId
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByCar(carTokenId);
    }
}
