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
    uint32 platformFeeInPPM = 200_000;

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
        carService.updateUserService(contractAddress);
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

    function addCar(RentalityCarToken.CreateCarRequest memory request
    ) public returns (uint) {
        if (!userService.isHost(msg.sender)) {
            userService.grantHostRole(msg.sender);
        }
        return
            carService.addCar(request);
    }

    function updateCarInfo(
        uint256 carId,
        uint64 pricePerDayInUsdCents,
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

        uint64 valueSum = request.totalDayPriceInUsdCents +
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

        RentalityTripService.PaymentInfo
            memory paymentInfo = RentalityTripService.PaymentInfo(
                0,
                tx.origin,
                address(this),
                request.totalDayPriceInUsdCents,
                request.taxPriceInUsdCents,
                request.depositInUsdCents,
                0,
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
            carInfo.pricePerDayInUsdCents,
            request.startDateTime,
            request.endDateTime,
            request.startLocation,
            request.endLocation,
            carInfo.milesIncludedPerDay,
            request.fuelPricePerGalInUsdCents,
            paymentInfo
        );
    }

    function approveTripRequest(uint256 tripId) public {
        tripService.approveTrip(tripId);

        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityTripService.Trip[] memory intersectedTrips= tripService.getTripsForCarThatIntersect(trip.carId, trip.startDateTime, trip.endDateTime);
        if (intersectedTrips.length > 0){
            for (uint256 i = 0; i < intersectedTrips.length; i++) {
                if (intersectedTrips[i].status == RentalityTripService.TripStatus.Created){
                    rejectTripRequest(intersectedTrips[i].tripId);
                }
            }
        }
    }

    function rejectTripRequest(uint256 tripId) public {
        tripService.rejectTrip(tripId);
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

        uint64 valueToReturnInUsdCents = trip
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
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(trip.carId);
        uint64 startFuelLevelInGal = (carInfo.tankVolumeInGal *
            startFuelLevelInPermille) / 1000;

        return
            tripService.checkInByHost(
                tripId,
                startFuelLevelInGal,
                startOdometr
            );
    }

    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(trip.carId);
        uint64 startFuelLevelInGal = (carInfo.tankVolumeInGal *
            startFuelLevelInPermille) / 1000;

        return
            tripService.checkInByGuest(
                tripId,
                startFuelLevelInGal,
                startOdometr
            );
    }

    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(trip.carId);
        uint64 endFuelLevelInGal = (carInfo.tankVolumeInGal *
            endFuelLevelInPermille) / 1000;

        return
            tripService.checkOutByGuest(tripId, endFuelLevelInGal, endOdometr);
    }

    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityCarToken.CarInfo memory carInfo = getCarInfoById(trip.carId);
        uint64 endFuelLevelInGal = (carInfo.tankVolumeInGal *
            endFuelLevelInPermille) / 1000;

        return
            tripService.checkOutByHost(tripId, endFuelLevelInGal, endOdometr);
    }

    function getPlatformFeeFrom(uint64 value) private view returns (uint64) {
        return (value * platformFeeInPPM) / 1_000_000;
    }

    function finishTrip(uint256 tripId) public {
        tripService.finishTrip(tripId);
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

        uint64 valueToHostInUsdCents = trip
            .paymentInfo
            .totalDayPriceInUsdCents +
            trip.paymentInfo.taxPriceInUsdCents +
            trip.paymentInfo.resolveAmountInUsdCents -
            getPlatformFeeFrom(
                trip.paymentInfo.totalDayPriceInUsdCents +
                    trip.paymentInfo.taxPriceInUsdCents
            );
        uint256 valueToHostInEth = currencyConverterService.getEthFromUsd(
            valueToHostInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        uint64 valueToGuestInUsdCents = trip.paymentInfo.depositInUsdCents -
            trip.paymentInfo.resolveAmountInUsdCents;
        uint256 valueToGuestInEth = currencyConverterService.getEthFromUsd(
            valueToGuestInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        require(payable(trip.host).send(valueToHostInEth));
        require(payable(trip.guest).send(valueToGuestInEth));
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
}
