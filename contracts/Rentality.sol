// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRentality.sol";
import "./RentalityCarToken.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityUtils.sol";


//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
//deployed 27.06.2023 11:10 to sepolia at 0x18744A3f7D15930446B1dbc5A837562e468B2D8d
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

    modifier onlyHostOrGuest() {
        require(
            userService.isHost(msg.sender) || userService.isGuest(msg.sender),
            "User is not a host or guest"
        );
        _;
    }

    function getChatInfoForHost() public view returns (IRentality.ChatInfo[] memory) {
        RentalityTripService.Trip[] memory trips = tripService.getTripsByHost(tx.origin);
        return RentalityUtils.populateChatInfo(trips, userService, carService);
    }

    function getChatInfoForGuest() public view returns (IRentality.ChatInfo[] memory) {
        RentalityTripService.Trip[] memory trips = tripService.getTripsByGuest(tx.origin);
        return RentalityUtils.populateChatInfo(trips, userService, carService);
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

    function getPlatformFeeFrom(uint64 value) private view returns (uint64) {
        return (value * platformFeeInPPM) / 1_000_000;
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

        //require(payable(owner()).send(amount));
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed.");
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
        // if (startDateTime < block.timestamp){
        //     return new RentalityCarToken.CarInfo[](0);
        // }
        RentalityCarToken.CarInfo[] memory availableCars = carService
            .searchAvailableCarsForUser(user, searchParams);
        if (availableCars.length == 0) return availableCars;

        RentalityTripService.Trip[] memory trips = tripService
            .getTripsThatIntersect(startDateTime, endDateTime);
        if (trips.length == 0) return availableCars;

        RentalityCarToken.CarInfo[]
            memory temp = new RentalityCarToken.CarInfo[](availableCars.length);
        uint256 resultCount = 0;

        for (uint i = 0; i < availableCars.length; i++) {
            bool hasIntersectTrip = false;

            for (uint j = 0; j < trips.length; j++) {
                if (
                    trips[j].status ==
                    RentalityTripService.TripStatus.Created ||
                    trips[j].status ==
                    RentalityTripService.TripStatus.Finished ||
                    trips[j].status == RentalityTripService.TripStatus.Canceled
                ) {
                    continue;
                }

                if (trips[j].carId == availableCars[i].carId) {
                    hasIntersectTrip = true;
                    break;
                }
            }

            if (!hasIntersectTrip) {
                temp[resultCount] = availableCars[i];
                resultCount++;
            }
        }

        if (availableCars.length == resultCount) return availableCars;

        RentalityCarToken.CarInfo[]
            memory result = new RentalityCarToken.CarInfo[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            result[i] = temp[i];
        }
        return result;
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
                request.ethToCurrencyDecimals,
                0,
                0
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

    function getTripContactInfo(uint256 tripId)
        public
        view
        onlyHostOrGuest
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);


        RentalityUserService.KYCInfo memory guestInfo = userService.getKYCInfo(
            trip.guest
        );
        RentalityUserService.KYCInfo memory hostInfo = userService.getKYCInfo(
            trip.host
        );

        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
    }

    function approveTripRequest(uint256 tripId) public {
        tripService.approveTrip(tripId);

        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityTripService.Trip[] memory intersectedTrips = tripService
            .getTripsForCarThatIntersect(
                trip.carId,
                trip.startDateTime,
                trip.endDateTime
            );
        if (intersectedTrips.length > 0) {
            for (uint256 i = 0; i < intersectedTrips.length; i++) {
                if (
                    intersectedTrips[i].status ==
                    RentalityTripService.TripStatus.Created
                ) {
                    rejectTripRequest(intersectedTrips[i].tripId);
                }
            }
        }
    }

    function rejectTripRequest(uint256 tripId) public {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        tripService.rejectTrip(tripId);

        uint64 valueToReturnInUsdCents = trip
            .paymentInfo 
            .totalDayPriceInUsdCents +
            trip.paymentInfo.taxPriceInUsdCents +
            trip.paymentInfo.depositInUsdCents;

        uint64 subtractAmount;
        if (trip.status == RentalityTripService.TripStatus.Approved) {
            subtractAmount = trip.pricePerDayInUsdCents / 2; 
        } else if (trip.status == RentalityTripService.TripStatus.CheckedInByHost) {
            subtractAmount = trip.pricePerDayInUsdCents;

        } else {
            subtractAmount = 0;
        }

        uint64 platformFee = subtractAmount * platformFeeInPPM / 1000000;
        uint64 returnToHost = subtractAmount - platformFee;

        valueToReturnInUsdCents -= subtractAmount;

        uint256 valueToReturnInEth = currencyConverterService.getEthFromUsd(
            valueToReturnInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );

        (bool successGuest, ) = payable(trip.guest).call{value: valueToReturnInEth}("");
        require(successGuest, "Transfer to guest failed.");

        if (returnToHost > 0) {
            uint256 returnToHostInEth = currencyConverterService.getEthFromUsd(
                returnToHost,
                trip.paymentInfo.ethToCurrencyRate,
                trip.paymentInfo.ethToCurrencyDecimals
            );
            (bool successHost, ) = payable(trip.host).call{value: returnToHostInEth}("");
            require(successHost, "Transfer to host failed.");
        }
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
        //require(payable(trip.host).send(valueToHostInEth));
        //require(payable(trip.guest).send(valueToGuestInEth));
        (bool successHost, ) = payable(trip.host).call{value: valueToHostInEth}(
            ""
        );
        (bool successGuest, ) = payable(trip.guest).call{
            value: valueToGuestInEth
        }("");
        require(successHost, "Transfer failed.");
        require(successGuest, "Transfer failed.");
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
        if (!userService.isGuest(msg.sender)) {
            userService.grantGuestRole(msg.sender);
        }
         return userService.setKYCInfo(name, surname, mobilePhoneNumber, profilePhoto, licenseNumber, expirationDate);
    }

    function getKYCInfo(address user) external view returns (RentalityUserService.KYCInfo memory) {
         return userService.getKYCInfo(user);
    }

    function getMyKYCInfo() external view returns (RentalityUserService.KYCInfo memory) {
         return userService.getMyKYCInfo();
    }

    function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress){
         return tripService.getAddressesByTripId(tripId);
    }
}
