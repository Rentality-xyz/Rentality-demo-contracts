// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./RentalityUtils.sol";
import "./IRentalityGeoService.sol";
import "./engine/RentalityEnginesService.sol";

/// @title RentalityCarToken
/// @notice ERC-721 token for representing cars in the Rentality platform.
/// @notice This contract allows users to add, update, and manage information about cars for rental.
/// @notice Cars can be listed, updated, and verified for geographic coordinates.
contract RentalityCarToken is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _carIdCounter;

    IRentalityGeoService private geoService;
    RentalityEnginesService private engineService;
    mapping(uint256 => CarInfo) private idToCarInfo;

    /// @notice Struct to store information about a listed car.
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
        uint8 engineType;
        uint64 milesIncludedPerDay;
        bool currentlyListed;
        bool geoVerified;
    }

    /// @notice Struct to store input parameters for creating a new car.
    struct CreateCarRequest {
        string tokenUri;
        string carVinNumber;
        string brand;
        string model;
        uint32 yearOfProduction;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64[] engineParams;
        uint8 engineType;
        uint64 milesIncludedPerDay;
        string locationAddress;
        string geoApiKey;
    }

    /// @notice Struct to store input parameters for updating car information.
    struct UpdateCarInfoRequest {
        uint256 carId;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64[] engineParams;
        uint64 milesIncludedPerDay;
        bool currentlyListed;
    }

    /// @notice Struct to store search parameters for querying cars.
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

    /// @notice Event emitted when a new car is successfully added.
    event CarAddedSuccess(
        uint256 CarId,
        string carVinNumber,
        address createdBy,
        uint64 pricePerDayInUsdCents,
        bool currentlyListed
    );

    /// @notice Event emitted when a car's information is successfully updated.
    event CarUpdatedSuccess(
        uint256 carId,
        uint64 pricePerDayInUsdCents,
        bool currentlyListed
    );

    /// @notice Event emitted when a car is successfully removed.
    event CarRemovedSuccess(
        uint256 carId,
        string CarVinNumber,
        address removedBy
    );

    /// @notice Constructor to initialize the RentalityCarToken contract.
    /// @param _geoServiceAddress The address of the RentalityGeoService contract.
    constructor(
        address _geoServiceAddress, address _rentalityEngine
    ) ERC721("RentalityCarToken Test", "RTCT") {
        geoService = IRentalityGeoService(_geoServiceAddress);
        engineService = RentalityEnginesService(_rentalityEngine);

    }

    /// @notice Returns the total supply of cars.
    /// @return The total number of cars in the system.
    function totalSupply() public view returns (uint) {
        return _carIdCounter.current();
    }

    /// @notice Retrieves information about a car based on its ID.
    /// @param carId The ID of the car.
    /// @return A struct containing information about the specified car.
    function getCarInfoById(uint256 carId) public view returns (CarInfo memory) {
        return idToCarInfo[carId];
    }

    /// @notice Checks if a VIN number is unique among the listed cars.
    /// @param carVinNumber The VIN number to check for uniqueness.
    /// @return True if the VIN number is unique, false otherwise.
    function isUniqueVinNumber(string memory carVinNumber) public view returns (bool) {
        bytes32 carVinNumberHash = keccak256(abi.encodePacked(carVinNumber));

        for (uint i = 0; i < totalSupply(); i++) {
            if (idToCarInfo[i + 1].carVinNumberHash == carVinNumberHash)
                return false;
        }

        return true;
    }

    /// @notice Adds a new car to the system with the provided information.
    /// @param request The input parameters for creating the new car.
    /// @return The ID of the newly added car.
    function addCar(CreateCarRequest memory request) public returns (uint) {
        require(
            request.pricePerDayInUsdCents > 0,
            "Make sure the price isn't negative"
        );

        require(
            request.milesIncludedPerDay > 0,
            "Make sure the included distance isn't negative"
        );
        require(
            isUniqueVinNumber(request.carVinNumber),
            "Car with this VIN number already exists"
        );

        _carIdCounter.increment();
        uint256 newCarId = _carIdCounter.current();

        engineService.addCar(newCarId, request.engineType, request.engineParams);

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
            request.engineType,
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

    /// @notice Verifies the geographic coordinates for a given car.
    /// @param carId The ID of the car to verify.
    function verifyGeo(uint256 carId) public {
        bool geoStatus = geoService.getCarCoordinateValidity(carId);
        CarInfo storage carInfo = idToCarInfo[carId];
        carInfo.geoVerified = geoStatus;
    }

    /// @notice Updates the information for a specific car.
    /// @param request The input parameters for updating the car.
    /// @param location The location for verifying geographic coordinates.
    ///  can be empty, for left old location information.
    /// @param geoApiKey The API key for the geographic verification service.
    /// can be empty, if location param is empty.
    function updateCarInfo(
        UpdateCarInfoRequest memory request,
        string memory location,
        string memory geoApiKey
    ) public {
        require(_exists(request.carId), "Token does not exist");
        require(
            ownerOf(request.carId) == tx.origin,
            "Only the owner of the car can update car info"
        );
        require(
            request.pricePerDayInUsdCents > 0,
            "Make sure the price isn't negative"
        );
        require(
            request.milesIncludedPerDay > 0,
            "Make sure the included distance isn't negative"
        );

        if (bytes(location).length > 0) {
            require(bytes(geoApiKey).length > 0, "Provide a valid geo API key");
            geoService.executeRequest(location, geoApiKey, request.carId);
            idToCarInfo[request.carId].geoVerified = false;
        }

        engineService.updateCar(request.carId,idToCarInfo[request.carId].engineType, request.engineParams);
        idToCarInfo[request.carId].pricePerDayInUsdCents = request.pricePerDayInUsdCents;
        idToCarInfo[request.carId].securityDepositPerTripInUsdCents = request.securityDepositPerTripInUsdCents;
        idToCarInfo[request.carId].milesIncludedPerDay = request.milesIncludedPerDay;
        idToCarInfo[request.carId].currentlyListed = request.currentlyListed;

        emit CarUpdatedSuccess(
            request.carId,
            request.pricePerDayInUsdCents,
            request.currentlyListed
        );
    }

    /// @notice Updates the token URI associated with a specific car.
    /// @param carId The ID of the car.
    /// @param tokenUri The new token URI.
    function updateCarTokenUri(uint256 carId, string memory tokenUri) public {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only the owner of the car can update the token URI"
        );

        _setTokenURI(carId, tokenUri);
    }

    /// @notice Burns a specific car token, removing it from the system.
    /// @param carId The ID of the car to be burned.
    function burnCar(uint256 carId) public {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only the owner of the car can burn the token"
        );

        engineService.burnCar(carId, idToCarInfo[carId].engineType);

        _burn(carId);
        delete idToCarInfo[carId];

        emit CarRemovedSuccess(
            carId,
            idToCarInfo[carId].carVinNumber,
            tx.origin
        );
    }

    /// @notice Retrieves information about all cars in the system.
    /// @return An array containing information about all cars.
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

    /// @notice Checks if a car is available for a specific user.
    /// @param carId The ID of the car.
    /// @param sender The address of the user.
    /// @return True if the car is available for the user, false otherwise.
    function isCarAvailableForUser(uint256 carId, address sender) private view returns (bool) {
        return
            _exists(carId) &&
            idToCarInfo[carId].currentlyListed &&
            ownerOf(carId) != sender;
    }

    /// @notice Retrieves available cars for a specific user.
    /// @dev Only used by main contract
    /// @param user The address of the user.
    /// @return An array containing information about available cars for the user.
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
    /// @notice Checks if a car is available for a specific user based on search parameters.
    /// @dev Determines availability based on several conditions, including ownership and search parameters.
    /// @param carId The ID of the car being checked.
    /// @param sender The address of the user checking availability.
    /// @param searchCarParams The parameters used to filter available cars.
    /// @return A boolean indicating whether the car is available for the user.
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
                idToCarInfo[carId].yearOfProduction <=
                searchCarParams.yearOfProductionTo) &&
            (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
                idToCarInfo[carId].pricePerDayInUsdCents >=
                searchCarParams.pricePerDayInUsdCentsFrom) &&
            (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
                idToCarInfo[carId].pricePerDayInUsdCents <=
                searchCarParams.pricePerDayInUsdCentsTo);
    }

    /// @notice Fetches available cars for a specific user based on search parameters.
    /// @dev Iterates through all cars to find those that are available for the user.
    /// @param user The address of the user for whom to fetch available cars.
    /// @param searchCarParams The parameters used to filter available cars.
    /// @return An array of CarInfo representing the available cars for the user.
    function fetchAvailableCarsForUser(
        address user,
        SearchCarParams memory searchCarParams
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        // Count the number of available cars for the user.
        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user, searchCarParams)) {
                itemCount += 1;
            }
        }

        // Create an array to store the available cars.
        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        // Populate the array with available cars.
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

    /// @notice Checks if a car belongs to a specific user.
    /// @dev Determines ownership of a car.
    /// @param carId The ID of the car being checked.
    /// @param user The address of the user being checked.
    /// @return A boolean indicating whether the car belongs to the user.
    function isCarOfUser(
        uint256 carId,
        address user
    ) private view returns (bool) {
        return _exists(carId) && (ownerOf(carId) == user);
    }

    /// @notice Gets the cars owned by a specific user.
    /// @dev Iterates through all cars to find those owned by the user.
    /// @param user The address of the user for whom to fetch owned cars.
    /// @return An array of CarInfo representing the cars owned by the user.
    function getCarsOwnedByUser(
        address user
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        // Count the number of cars owned by the user.
        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarOfUser(currentId, user)) {
                itemCount += 1;
            }
        }

        // Create an array to store the owned cars.
        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        // Populate the array with owned cars.
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