// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721URIStorageUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './libs/RentalityQuery.sol';
import './IRentalityGeoService.sol';
import './proxy/UUPSOwnable.sol';
import './engine/RentalityEnginesService.sol';
import './Schemas.sol';

/// @title RentalityCarToken
/// @notice ERC-721 token for representing cars in the Rentality platform.
/// @notice This contract allows users to add, update, and manage information about cars for rental.
/// @notice Cars can be listed, updated, and verified for geographic coordinates.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityCarToken is ERC721URIStorageUpgradeable, UUPSOwnable {
  using Counters for Counters.Counter;
  Counters.Counter private _carIdCounter;
  IRentalityGeoService private geoService;
  RentalityEnginesService private engineService;
  RentalityUserService private userService;

  mapping(uint256 => Schemas.CarInfo) private idToCarInfo;

  /// @notice Event emitted when a new car is successfully added.
  event CarAddedSuccess(
    uint256 CarId,
    string carVinNumber,
    address createdBy,
    uint64 pricePerDayInUsdCents,
    bool currentlyListed
  );

  /// @notice Event emitted when a car's information is successfully updated.
  event CarUpdatedSuccess(uint256 carId, uint64 pricePerDayInUsdCents, bool currentlyListed);

  /// @notice Event emitted when a car is successfully removed.
  event CarRemovedSuccess(uint256 carId, string CarVinNumber, address removedBy);

  /// @notice returns RentalityGeoService address
  function getGeoServiceAddress() public view returns (address) {
    return address(geoService);
  }
  /// @notice update RentalityGeoService address
  /// @param _geoService address of service
  function updateGeoServiceAddress(address _geoService) public {
    require(owner() == msg.sender, 'Only owner.');
    geoService = IRentalityGeoService(_geoService);
  }

  /// @notice Returns the total supply of cars.
  /// @return The total number of cars in the system.
  function totalSupply() public view returns (uint) {
    return _carIdCounter.current();
  }

  /// @notice Retrieves information about a car based on its ID.
  /// @param carId The ID of the car.
  /// @return A struct containing information about the specified car.
  function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfo memory) {
    return idToCarInfo[carId];
  }

  /// @notice Checks if a VIN number is unique among the listed cars.
  /// @param carVinNumber The VIN number to check for uniqueness.
  /// @return True if the VIN number is unique, false otherwise.
  function isUniqueVinNumber(string memory carVinNumber) public view returns (bool) {
    bytes32 carVinNumberHash = keccak256(abi.encodePacked(carVinNumber));

    for (uint i = 0; i < totalSupply(); i++) {
      if (idToCarInfo[i + 1].carVinNumberHash == carVinNumberHash) return false;
    }

    return true;
  }

  /// @notice Adds a new car to the system with the provided information.
  /// @param request The input parameters for creating the new car.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request) public returns (uint) {
    require(userService.hasPassedKYCAndTC(tx.origin), 'KYC or TC has not passed.');
    require(request.pricePerDayInUsdCents > 0, "Make sure the price isn't negative");
    require(request.milesIncludedPerDay > 0, "Make sure the included distance isn't negative");
    require(isUniqueVinNumber(request.carVinNumber), 'Car with this VIN number already exists');

    _carIdCounter.increment();
    uint256 newCarId = _carIdCounter.current();

    engineService.verifyCreateParams(request.engineType, request.engineParams);

    _safeMint(tx.origin, newCarId);
    _setTokenURI(newCarId, request.tokenUri);

    geoService.executeRequest(
      request.locationAddress,
      request.locationLatitude,
      request.locationLongitude,
      request.geoApiKey,
      newCarId
    );

    idToCarInfo[newCarId] = Schemas.CarInfo(
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
      request.engineParams,
      request.milesIncludedPerDay,
      request.timeBufferBetweenTripsInSec,
      true,
      false,
      ''
    );

    _approve(address(this), newCarId);
    //_transfer(msg.sender, address(this), carId);

    emit CarAddedSuccess(newCarId, request.carVinNumber, tx.origin, request.pricePerDayInUsdCents, true);

    return newCarId;
  }

  /// @notice Verifies the geographic coordinates for a given car.
  /// @param carId The ID of the car to verify.
  function verifyGeo(uint256 carId) public {
    bool geoStatus = geoService.getCarCoordinateValidity(carId);
    Schemas.CarInfo storage carInfo = idToCarInfo[carId];
    carInfo.geoVerified = geoStatus;
    carInfo.timeZoneId = geoService.getCarTimeZoneId(carId);
  }

  /// @notice Updates the information for a specific car.
  /// @param request The input parameters for updating the car.
  /// @param location The location for verifying geographic coordinates.
  ///  can be empty, for left old location information.
  /// @param geoApiKey The API key for the geographic verification service.
  /// can be empty, if location param is empty.
  function updateCarInfo(
    Schemas.UpdateCarInfoRequest memory request,
    string memory location,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory geoApiKey
  ) public {
    require(_exists(request.carId), 'Token does not exist');
    require(ownerOf(request.carId) == tx.origin, 'Only the owner of the car can update car info');
    require(request.pricePerDayInUsdCents > 0, "Make sure the price isn't negative");
    require(request.milesIncludedPerDay > 0, "Make sure the included distance isn't negative");

    if (bytes(location).length > 0) {
      require(bytes(geoApiKey).length > 0, 'Provide a valid geo API key');
      geoService.executeRequest(location, locationLatitude, locationLongitude, geoApiKey, request.carId);
      idToCarInfo[request.carId].geoVerified = false;
    }

    uint64[] memory engineParams = engineService.verifyUpdateParams(
      idToCarInfo[request.carId].engineType,
      request.engineParams,
      idToCarInfo[request.carId].engineParams
    );
    idToCarInfo[request.carId].pricePerDayInUsdCents = request.pricePerDayInUsdCents;
    idToCarInfo[request.carId].securityDepositPerTripInUsdCents = request.securityDepositPerTripInUsdCents;
    idToCarInfo[request.carId].milesIncludedPerDay = request.milesIncludedPerDay;
    idToCarInfo[request.carId].engineParams = engineParams;
    idToCarInfo[request.carId].timeBufferBetweenTripsInSec = request.timeBufferBetweenTripsInSec;
    idToCarInfo[request.carId].currentlyListed = request.currentlyListed;

    emit CarUpdatedSuccess(request.carId, request.pricePerDayInUsdCents, request.currentlyListed);
  }

  /// @notice Updates the token URI associated with a specific car.
  /// @param carId The ID of the car.
  /// @param tokenUri The new token URI.
  function updateCarTokenUri(uint256 carId, string memory tokenUri) public {
    require(_exists(carId), 'Token does not exist');
    require(ownerOf(carId) == tx.origin, 'Only the owner of the car can update the token URI');

    _setTokenURI(carId, tokenUri);
  }

  /// @notice Burns a specific car token, removing it from the system.
  /// @param carId The ID of the car to be burned.
  function burnCar(uint256 carId) public {
    require(_exists(carId), 'Token does not exist');
    require(ownerOf(carId) == tx.origin, 'Only the owner of the car can burn the token');

    _burn(carId);
    delete idToCarInfo[carId];

    emit CarRemovedSuccess(carId, idToCarInfo[carId].carVinNumber, tx.origin);
  }

  /// @notice Retrieves information about all cars in the system.
  /// @return An array containing information about all cars.
  function getAllCars() public view returns (Schemas.CarInfo[] memory) {
    uint itemCount = 0;

    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (_exists(currentId)) {
        itemCount += 1;
      }
    }

    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);

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
    return _exists(carId) && idToCarInfo[carId].currentlyListed && ownerOf(carId) != sender;
  }

  /// @notice Retrieves available cars for a specific user.
  /// @dev Only used by main contract
  /// @param user The address of the user.
  /// @return An array containing information about available cars for the user.
  function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
    uint itemCount = 0;

    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user)) {
        itemCount += 1;
      }
    }

    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user)) {
        Schemas.CarInfo storage currentItem = idToCarInfo[currentId];
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
    Schemas.SearchCarParams memory searchCarParams
  ) public view returns (bool) {
    return
      _exists(carId) &&
      idToCarInfo[carId].currentlyListed &&
      ownerOf(carId) != sender &&
      RentalityQuery.isCarAvailableForUser(carId, searchCarParams, address(this), address(geoService));
  }

  /// @notice Fetches available cars for a specific user based on search parameters.
  /// @dev Iterates through all cars to find those that are available for the user.
  /// @param user The address of the user for whom to fetch available cars.
  /// @param searchCarParams The parameters used to filter available cars.
  /// @return An array of CarInfo representing the available cars for the user.
  function fetchAvailableCarsForUser(
    address user,
    Schemas.SearchCarParams memory searchCarParams
  ) public view returns (Schemas.CarInfo[] memory) {
    uint itemCount = 0;

    // Count the number of available cars for the user.
    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user, searchCarParams)) {
        itemCount += 1;
      }
    }

    // Create an array to store the available cars.
    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
    uint currentIndex = 0;

    // Populate the array with available cars.
    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (isCarAvailableForUser(currentId, user, searchCarParams)) {
        Schemas.CarInfo memory currentItem = idToCarInfo[currentId];
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
  function isCarOfUser(uint256 carId, address user) private view returns (bool) {
    return _exists(carId) && (ownerOf(carId) == user);
  }

  /// @notice Gets the cars owned by a specific user.
  /// @dev Iterates through all cars to find those owned by the user.
  /// @param user The address of the user for whom to fetch owned cars.
  /// @return An array of CarInfo representing the cars owned by the user.
  function getCarsOwnedByUser(address user) public view returns (Schemas.CarInfo[] memory) {
    uint itemCount = 0;

    // Count the number of cars owned by the user.
    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (isCarOfUser(currentId, user)) {
        itemCount += 1;
      }
    }

    // Create an array to store the owned cars.
    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](itemCount);
    uint currentIndex = 0;

    // Populate the array with owned cars.
    for (uint i = 0; i < totalSupply(); i++) {
      uint currentId = i + 1;
      if (isCarOfUser(currentId, user)) {
        Schemas.CarInfo memory currentItem = idToCarInfo[currentId];
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Constructor to initialize the RentalityCarToken contract.
  /// @param geoServiceAddress The address of the RentalityGeoService contract.
  /// @param engineServiceAddress The address of the RentalityGeoService contract.
  /// @param userServiceAddress The address of the RentalityGeoService contract.
  function initialize(
    address geoServiceAddress,
    address engineServiceAddress,
    address userServiceAddress
  ) public initializer {
    engineService = RentalityEnginesService(engineServiceAddress);
    geoService = IRentalityGeoService(geoServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    __ERC721_init('RentalityCarToken Test', 'RTCT');
    __Ownable_init();
  }
}
