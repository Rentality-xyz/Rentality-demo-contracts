// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRentality.sol";
import "./RentalityCarToken.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityTripService.sol";
import "./RentalityUserService.sol";

//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
contract Rentality is IRentality, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tripRequestIdCounter;
    uint32 platformFeeInPPM = 300_000;

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

    function owner()
        public
        view
        override(IRentality, Ownable)
        returns (address)
    {
        return Ownable.owner();
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

    function getCarServiceAddress() public view returns (address) {
        return address(carService);
    }

    function updateCarService(address contractAddress) public onlyAdmin {
        carService = RentalityCarToken(contractAddress);
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
        return platformFeeInPPM;
    }

    function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
        require(valueInPPM > 0, "Make sure the value isn't negative");
        require(valueInPPM <= 1_000_000, "Value can't be more than 1000000");

        platformFeeInPPM = valueInPPM;
    }

    function withdrawFromPlatform(uint256 amount) public {
        require(
            address(this).balance > 0,
            "There is no commission to withdraw"
        );
        require(
            address(this).balance >= amount,
            "There is not enough balance on the contract"
        );

        require(payable(owner()).send(amount));
    }

    function withdrawAllFromPlatform() public {
        return withdrawFromPlatform(address(this).balance);
    }

    function totalTripRequestCount() public view returns (uint) {
        return _tripRequestIdCounter.current();
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
        string memory tokenUri,
        string memory carVinNumber,
        uint256 pricePerDayInUsdCents,
        uint256 tankVolumeInGal,
        uint256 distanceIncludedInMi
    ) public returns (uint) {
        if (!userService.isHost(msg.sender)) {
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

    function getMyCars()
        public
        view
        returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getCarsOwnedByUser(tx.origin);
    }

    function getCarsRentedByMe()
        public
        view
        returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getCarsRentedByUser(tx.origin);
    }

    function createTripRequest(
        IRentality.CreateTripRequest memory request
    ) public payable {
        require(msg.value > 0, "Rental fee must be greater than 0");

        uint256 valueSum = request.totalDayPriceInUsdCents +
            request.taxPriceInUsdCents +
            request.depositInUsdCents;
        uint256 valueSumInEth = currencyConverterService.getEthFromUsd(
            valueSum,
            request.ethToCurrencyRate,
            request.ethToCurrencyDecimals
        );

        require(
            msg.value == valueSumInEth,
            "Rental fee must be equal to sum totalDayPrice + taxPrice + deposit"
        );

        _tripRequestIdCounter.increment();
        uint256 newTripRequestId = _tripRequestIdCounter.current();
        RentalityTripService.PaymentInfo
            memory paymentInfo = RentalityTripService.PaymentInfo(
                newTripRequestId,
                tx.origin,
                address(this),
                request.totalDayPriceInUsdCents,
                request.taxPriceInUsdCents,
                request.depositInUsdCents,
                RentalityTripService.CurrencyType.ETH,
                request.ethToCurrencyRate,
                request.ethToCurrencyDecimals
            );

        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(
            request.carId
        );

        tripService.createNewTrip(
            request.carId,
            tx.origin,
            request.host,
            request.startDateTime,
            request.endDateTime,
            request.startLocation,
            request.endLocation,
            carInfo.distanceIncludedInMi,
            paymentInfo
        );
    }

    function approveTripRequest(uint256 tripId) public {
        tripService.approveTrip(tripId);
    }

    function rejectTripRequest(uint256 tripId) public {
        tripService.rejectTrip(tripId);
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

        uint256 valueToReturnInUsdCents = trip
            .paymentInfo
            .totalDayPriceInUsdCents +
            trip.paymentInfo.taxPriceInUsdCents +
            trip.paymentInfo.depositInUsdCents;
        uint256 valueToReturnInEth = currencyConverterService.getEthFromUsd(
            valueToReturnInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        require(payable(trip.guest).send(valueToReturnInEth));
    }

    function checkInByHost(
        uint256 tripId,
        uint256 startFuelLevel,
        uint256 startOdometr
    ) public {
        return tripService.checkInByHost(tripId, startFuelLevel, startOdometr);
    }

    function checkInByGuest(
        uint256 tripId,
        uint256 startFuelLevel,
        uint256 startOdometr
    ) public {
        return tripService.checkInByGuest(tripId, startFuelLevel, startOdometr);
    }

    function checkOutByGuest(
        uint256 tripId,
        uint256 endFuelLevel,
        uint256 endOdometr
    ) public {
        return tripService.checkOutByGuest(tripId, endFuelLevel, endOdometr);
    }

    function checkOutByHost(
        uint256 tripId,
        uint256 endFuelLevel,
        uint256 endOdometr
    ) public {
        return tripService.checkOutByHost(tripId, endFuelLevel, endOdometr);
    }

    function getPlatformFeeFrom(uint256 value) private view returns (uint256) {
        return (value * platformFeeInPPM) / 1_000_000;
    }

    function finishTrip(uint256 tripId) public {
        tripService.finishTrip(tripId);
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

        uint256 valueToHostInUsdCents = trip
            .paymentInfo
            .totalDayPriceInUsdCents +
            trip.paymentInfo.taxPriceInUsdCents -
            getPlatformFeeFrom(
                trip.paymentInfo.totalDayPriceInUsdCents +
                    trip.paymentInfo.taxPriceInUsdCents
            );
        uint256 valueToHostInEth = currencyConverterService.getEthFromUsd(
            valueToHostInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        uint256 valueToGuestInUsdCents = trip.paymentInfo.depositInUsdCents;
        uint256 valueToGuestInEth = currencyConverterService.getEthFromUsd(
            valueToGuestInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        require(payable(trip.host).send(valueToHostInEth));
        require(payable(trip.guest).send(valueToGuestInEth));
    }

    function resolveIssue(uint256 tripId, uint256 fuelPricePerGal) public {
        return tripService.resolveIssue(tripId, fuelPricePerGal);
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
        uint256 carTokenId
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByCar(carTokenId);
    }
}
