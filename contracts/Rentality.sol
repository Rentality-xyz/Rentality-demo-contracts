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

    enum CurrencyType {
        ETH
    }

    struct PaymentInfo {
        uint256 tripRequestId;
        address from;
        address to;
        uint256 totalDayPriceInUsdCents;
        uint256 taxPriceInUsdCents;
        uint256 depositInUsdCents;
        CurrencyType currencyType;
        uint256 ethToCurrencyRate;
        uint256 ethToCurrencyDecimals;
    }

    struct TripRequest {
        uint256 carId;
        address guest;
        address host;
        uint startDateTime;
        uint endDateTime;
        string startLocation;
        string endLocation;
        PaymentInfo paymentInfo;
        bool approved;
        bool rejected;
        bool closed;
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
            userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) ||(tx.origin == owner()),
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

    function updateCarService(address contractAddress) public onlyAdmin {
        carService = RentalityCarToken(contractAddress);
    }

    function updateCurrencyConverterService(address contractAddress) public onlyAdmin {
        currencyConverterService = RentalityCurrencyConverter(contractAddress);
    }

    function updateTripService(address contractAddress) public onlyAdmin {
        tripService = RentalityTripService(contractAddress);
    }

    function updateUserService(address contractAddress) public onlyAdmin {
        userService = RentalityUserService(contractAddress);
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

    function getAllCars() public view returns (RentalityCarToken.CarInfo[] memory)
    {
        return carService.getAllCars();
    }

    function getAllAvailableCarsForUser(address user) public view returns (RentalityCarToken.CarInfo[] memory) {
        return carService.getAllAvailableCarsForUser(user);
    }

    function getMyCars() public view returns (RentalityCarToken.CarInfo[] memory)
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
        uint256 carId,
        address host,
        uint256 startDateTime,
        uint256 endDateTime,
        string memory startLocation,
        string memory endLocation,
        uint256 totalDayPriceInUsdCents,
        uint256 taxPriceInUsdCents,
        uint256 depositInUsdCents,
        uint256 ethToCurrencyRate,
        uint256 ethToCurrencyDecimals
    ) public payable {
        require(msg.value > 0, "Rental fee must be greater than 0");

        uint256 msgValueInUsdCents = (msg.value * uint(ethToCurrencyRate)) /
            ((10 ** (ethToCurrencyDecimals - 2)) * (1 ether));

        require(
            msgValueInUsdCents ==
                totalDayPriceInUsdCents +
                    taxPriceInUsdCents +
                    depositInUsdCents,
            "Rental fee must be equal to sum totalDayPrice + taxPrice + deposit"
        );

        _tripRequestIdCounter.increment();
        uint256 newTripRequestId = _tripRequestIdCounter.current();
        PaymentInfo memory paymentInfo = PaymentInfo(
            newTripRequestId,
            msg.sender,
            address(this),
            totalDayPriceInUsdCents,
            taxPriceInUsdCents,
            depositInUsdCents,
            CurrencyType.ETH,
            ethToCurrencyRate,
            ethToCurrencyDecimals
        );

        idToTripRequest[newTripRequestId] = TripRequest(
            carId,
            msg.sender,
            host,
            startDateTime,
            endDateTime,
            startLocation,
            endLocation,
            paymentInfo,
            false,
            false,
            false
        );
    }

    function approveTripRequest(uint256 tripRequestId) public {
        TripRequest memory request = idToTripRequest[tripRequestId];
        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(
            request.carId
        );
        RentalityTripService.TripPaymentInfo
            memory tripPaymentInfo = RentalityTripService.TripPaymentInfo(
                request.paymentInfo.totalDayPriceInUsdCents,
                request.paymentInfo.taxPriceInUsdCents,
                request.paymentInfo.depositInUsdCents
            );

        tripService.addTrip(
            request.carId,
            tripRequestId,
            request.guest,
            request.host,
            request.startDateTime,
            request.endDateTime,
            request.startLocation,
            request.endLocation,
            carInfo.distanceIncludedInMi,
            tripPaymentInfo,
            true
        );
        request.approved = true;
        request.closed = true;
    }

    function rejectTripRequest(uint256 tripRequestId) public {
        TripRequest memory request = idToTripRequest[tripRequestId];
        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(
            request.carId
        );
        RentalityTripService.TripPaymentInfo
            memory tripPaymentInfo = RentalityTripService.TripPaymentInfo(
                request.paymentInfo.totalDayPriceInUsdCents,
                request.paymentInfo.taxPriceInUsdCents,
                request.paymentInfo.depositInUsdCents
            );

        tripService.addTrip(
            request.carId,
            tripRequestId,
            request.guest,
            request.host,
            request.startDateTime,
            request.endDateTime,
            request.startLocation,
            request.endLocation,
            carInfo.distanceIncludedInMi,
            tripPaymentInfo,
            false
        );
        request.rejected = true;
        request.closed = true;
        uint256 valueToReturnInUsdCents = request
            .paymentInfo
            .totalDayPriceInUsdCents +
            request.paymentInfo.taxPriceInUsdCents +
            request.paymentInfo.depositInUsdCents;
        uint256 valueToReturnInEth = (valueToReturnInUsdCents *
            (1 ether) *
            (10 ** (request.paymentInfo.ethToCurrencyDecimals - 2))) /
            uint(request.paymentInfo.ethToCurrencyRate);
        require(payable(request.guest).send(valueToReturnInEth));
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

    function finishTrip(uint256 tripId) public {
        tripService.finishTrip(tripId);
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        TripRequest memory request = idToTripRequest[trip.tripRequestId];

        uint256 valueToHostInUsdCents = request
            .paymentInfo
            .totalDayPriceInUsdCents + request.paymentInfo.taxPriceInUsdCents;
        uint256 valueToHostInEth = (valueToHostInUsdCents *
            (1 ether) *
            (10 ** (request.paymentInfo.ethToCurrencyDecimals - 2))) /
            uint(request.paymentInfo.ethToCurrencyRate);
        uint256 valueToGuestInUsdCents = request.paymentInfo.depositInUsdCents;
        uint256 valueToGuestInEth = (valueToGuestInUsdCents *
            (1 ether) *
            (10 ** (request.paymentInfo.ethToCurrencyDecimals - 2))) /
            uint(request.paymentInfo.ethToCurrencyRate);
        require(payable(request.host).send(valueToHostInEth));
        require(payable(request.guest).send(valueToGuestInEth));
    }

    function resolveIssue(uint256 tripId, uint256 fuelPricePerGal) public {
        return tripService.resolveIssue(tripId, fuelPricePerGal);
    }

    function getTrip(
        uint256 tripId
    ) public view returns (RentalityTripService.Trip memory) {
        return tripService.getTrip(tripId);
    }

    function getTripsByGuest(
        address guest
    ) public view returns (RentalityTripService.Trip[] memory) {
        return tripService.getTripsByGuest(guest);
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

    function withdrawTips() public {
        require(
            address(this).balance > 0,
            "There is no commission to withdraw"
        );
        require(payable(owner()).send(address(this).balance));
    }
}
