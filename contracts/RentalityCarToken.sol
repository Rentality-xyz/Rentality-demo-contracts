// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./RentalityUtils.sol";
import "./RentalityGeoService.sol";

//deployed 26.05.2023 11:15 to sepolia at 0xcC66CdAfc3C39d96651220975855202960C08747
contract RentalityCarToken is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _carIdCounter;

    RentalityGeoService private geoService;
    mapping(uint256 => CarInfo) private idToCarInfo;

    //The structure to store info about a listed car
    struct CarInfo {
        uint256 carId;
        string carVinNumber;
        bytes32 carVinNumberHash;
        address createdBy;
        string brand;
        string model;
        uint32 yearOfProduction;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64 tankVolumeInGal;
        uint64 fuelPricePerGalInUsdCents;
        uint64 milesIncludedPerDay;
        bool currentlyListed;
        bool geoVerified;
    }

    struct CreateCarRequest {
        string tokenUri;
        string carVinNumber;
        string brand;
        string model;
        uint32 yearOfProduction;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64 tankVolumeInGal;
        uint64 fuelPricePerGalInUsdCents;
        uint64 milesIncludedPerDay;
        string locationAddress;
        string geoApiKey;
    }

    struct UpdateCarInfoRequest {
        uint256 carId;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64 fuelPricePerGalInUsdCents;
        uint64 milesIncludedPerDay;
        string country;
        string state;
        string city;
        int64 locationLatitudeInPPM;
        int64 locationLongitudeInPPM;
        bool currentlyListed;
    }

    struct SearchCarParams {
        string country;
        string state;
        string city;
        string brand;
        string model;
        uint32 yearOfProductionFrom;
        uint32 yearOfProductionTo;
        uint64 pricePerDayInUsdCentsFrom;
        uint64 pricePerDayInUsdCentsTo;
    }

    event CarAddedSuccess(
        uint256 CarId,
        string carVinNumber,
        address createdBy,
        uint64 pricePerDayInUsdCents,
        bool currentlyListed
    );

    event CarUpdatedSuccess(
        uint256 carId,
        uint64 pricePerDayInUsdCents,
        bool currentlyListed
    );

    event CarRemovedSuccess(
        uint256 carId,
        string CarVinNumber,
        address removedBy
    );

    constructor(
        address _geoServiceAddress
    ) ERC721("RentalityCarToken Test", "RTCT") {
        geoService = RentalityGeoService(_geoServiceAddress);

    }

    function totalSupply() public view returns (uint) {
        return _carIdCounter.current();
    }

    function getCarInfoById(
        uint256 carId
    ) public view returns (CarInfo memory) {
        return idToCarInfo[carId];
    }

    function isUniqueVinNumber(
        string memory carVinNumber
    ) public view returns (bool) {
        bytes32 carVinNumberHash = keccak256(abi.encodePacked(carVinNumber));

        for (uint i = 0; i < totalSupply(); i++) {
            if (idToCarInfo[i + 1].carVinNumberHash == carVinNumberHash)
                return false;
        }

        return true;
    }

    function addCar(
        CreateCarRequest memory request
    ) public returns (uint) {
        require(
            request.pricePerDayInUsdCents > 0,
            "Make sure the price isn't negative"
        );
        require(
            request.tankVolumeInGal > 0,
            "Make sure the tank volume isn't negative"
        );
        require(
            request.milesIncludedPerDay > 0,
            "Make sure the included distance isn't negative"
        );
        require(
            isUniqueVinNumber(request.carVinNumber),
            "Car with this VIN number is already exist"
        );

        _carIdCounter.increment();
        uint256 newCarId = _carIdCounter.current();

        _safeMint(tx.origin, newCarId);
        _setTokenURI(newCarId, request.tokenUri);

        geoService.executeRequest(request.locationAddress, request.geoApiKey, newCarId);        

        idToCarInfo[newCarId] = CarInfo(
            newCarId,
            request.carVinNumber,
            keccak256(abi.encodePacked(request.carVinNumber)),
            tx.origin,
            request.brand,
            request.model,
            request.yearOfProduction,
            request.pricePerDayInUsdCents,
            request.securityDepositPerTripInUsdCents,
            request.tankVolumeInGal,
            request.fuelPricePerGalInUsdCents,
            request.milesIncludedPerDay,
            true,
            false
        );

        _approve(address(this), newCarId);
        //_transfer(msg.sender, address(this), carId);

        emit CarAddedSuccess(
            newCarId,
            request.carVinNumber,
            tx.origin,
            request.pricePerDayInUsdCents,
            true
        );

        return newCarId;
    }

    function verifyGeo(uint256 carId) public {
        bool geoStatus = geoService.getCarCoordinateValidity(carId);
        CarInfo storage carInfo = idToCarInfo[carId];
        carInfo.geoVerified = geoStatus;
    }

    function updateCarInfo(
        uint256 carId,
        uint64 pricePerDayInUsdCents,
        uint64 securityDepositPerTripInUsdCents,
        uint64 fuelPricePerGalInUsdCents,
        uint64 milesIncludedPerDay,
        bool currentlyListed
    ) public {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only owner of the car can update car info"
        );

        idToCarInfo[carId].pricePerDayInUsdCents = pricePerDayInUsdCents;
        idToCarInfo[carId]
            .securityDepositPerTripInUsdCents = securityDepositPerTripInUsdCents;
        idToCarInfo[carId]
            .fuelPricePerGalInUsdCents = fuelPricePerGalInUsdCents;
        idToCarInfo[carId].milesIncludedPerDay = milesIncludedPerDay;
        idToCarInfo[carId].currentlyListed = currentlyListed;

        emit CarUpdatedSuccess(carId, pricePerDayInUsdCents, currentlyListed);
    }

    function updateCarTokenUri(
        uint256 carId,
        string memory tokenUri
    ) public {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only owner of the car can update token"
        );

        _setTokenURI(carId, tokenUri);
    }

    function burnCar(uint256 carId) public {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only owner of the car can burn token"
        );

        _burn(carId);
        delete idToCarInfo[carId];

        emit CarRemovedSuccess(
            carId,
            idToCarInfo[carId].carVinNumber,
            tx.origin
        );
    }

    function getAllCars() public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (_exists(currentId)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);

        for (uint i = 0; i < totalSupply(); i++) {
            result[i] = idToCarInfo[i + 1];
        }

        return result;
    }

    function isCarAvailableForUser(
        uint256 carId,
        address sender
    ) private view returns (bool) {
        return
            _exists(carId) &&
            idToCarInfo[carId].currentlyListed &&
            ownerOf(carId) != sender;
    }

    // Only used by main contract
    function getAvailableCarsForUser(
        address user
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user)) {
                CarInfo storage currentItem = idToCarInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isCarAvailableForUser(
        uint256 carId,
        address sender,
        SearchCarParams memory searchCarParams
    ) private view returns (bool) {
        return
            _exists(carId) &&
            idToCarInfo[carId].currentlyListed &&
            ownerOf(carId) != sender &&
            (bytes(searchCarParams.brand).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(idToCarInfo[carId].brand),
                    RentalityUtils.toLower(searchCarParams.brand)
                )) &&
            (bytes(searchCarParams.model).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(idToCarInfo[carId].model),
                    RentalityUtils.toLower(searchCarParams.model)
                )) &&
            (bytes(searchCarParams.country).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(geoService.getCarCountry(carId)),
                    RentalityUtils.toLower(searchCarParams.country)
                )) &&
            (bytes(searchCarParams.state).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(geoService.getCarState(carId)),
                    RentalityUtils.toLower(searchCarParams.state)
                )) &&
            (bytes(searchCarParams.city).length == 0 ||
                RentalityUtils.containWord(
                    RentalityUtils.toLower(geoService.getCarCity(carId)),
                    RentalityUtils.toLower(searchCarParams.city)
                )) &&
            (searchCarParams.yearOfProductionFrom == 0 ||
                idToCarInfo[carId].yearOfProduction >=
                searchCarParams.yearOfProductionFrom) &&
            (searchCarParams.yearOfProductionTo == 0 ||
                idToCarInfo[carId].yearOfProduction >=
                searchCarParams.yearOfProductionTo) &&
            (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
                idToCarInfo[carId].pricePerDayInUsdCents >=
                searchCarParams.pricePerDayInUsdCentsFrom) &&
            (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
                idToCarInfo[carId].pricePerDayInUsdCents <=
                searchCarParams.pricePerDayInUsdCentsTo);
    }

    function fetchAvailableCarsForUser(
        address user,
        SearchCarParams memory searchCarParams
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user, searchCarParams)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user, searchCarParams)) {
                CarInfo storage currentItem = idToCarInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isCarOfUser(
        uint256 carId,
        address user
    ) private view returns (bool) {
        return _exists(carId) && (ownerOf(carId) == user);
    }

    function getCarsOwnedByUser(
        address user
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarOfUser(currentId, user)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarOfUser(currentId, user)) {
                CarInfo storage currentItem = idToCarInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }
}
