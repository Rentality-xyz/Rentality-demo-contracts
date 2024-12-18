// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721URIStorageUpgradeable, ERC721Upgradeable, IERC721Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './abstract/IRentalityGeoService.sol';
import './proxy/UUPSOwnable.sol';
import './engine/RentalityEnginesService.sol';
import './Schemas.sol';
import './RentalityUserService.sol';
import './libs/RentalityUtils.sol';
import './features/RentalityNotificationService.sol';

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
  RentalityNotificationService private eventManager;

  modifier onlyAdmin() {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    _;
  }
  mapping(uint => uint) private carIdToListingMoment;

  /// @dev Updates the address of the RentalityEventManager contract.
  /// @param _eventManager The address of the new RentalityEventManager contract.
  function updateEventServiceAddress(address _eventManager) public onlyAdmin {
    eventManager = RentalityNotificationService(_eventManager);
  }

  /// @dev Updates the address of the RentalityEnginesService contract.
  /// @param _engineService The address of the new RentalityEnginesService contract.
  function updateEngineServiceAddress(address _engineService) public onlyAdmin {
    engineService = RentalityEnginesService(_engineService);
  }

  /// @notice returns RentalityGeoService address
  function getGeoServiceAddress() public view returns (address) {
    return address(geoService);
  }
  /// @notice update RentalityGeoService address
  /// @param _geoService address of service
  function updateGeoServiceAddress(address _geoService) public onlyAdmin {
    geoService = IRentalityGeoService(_geoService);
  }

  function getEngineService() public view returns (RentalityEnginesService) {
    return engineService;
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

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
    uint carsOwnedByHost = balanceOf(host);

    Schemas.PublicHostCarDTO[] memory carDTOs = new Schemas.PublicHostCarDTO[](carsOwnedByHost);
    uint carCounter = 0;
    for (uint i = 1; i <= _carIdCounter.current(); i++) {
      if (_exists(i) && ownerOf(i) == host) {
        Schemas.CarInfo memory car = idToCarInfo[i];

        carDTOs[carCounter].carId = i;
        carDTOs[carCounter].milesIncludedPerDay = car.milesIncludedPerDay;
        carDTOs[carCounter].metadataURI = tokenURI(i);
        carDTOs[carCounter].yearOfProduction = car.yearOfProduction;
        carDTOs[carCounter].currentlyListed = car.currentlyListed;
        carDTOs[carCounter].brand = car.brand;
        carDTOs[carCounter].model = car.model;
        carDTOs[carCounter].pricePerDayInUsdCents = car.pricePerDayInUsdCents;
        carDTOs[carCounter].securityDepositPerTripInUsdCents = car.securityDepositPerTripInUsdCents;
        carCounter++;
      }
    }
    return carDTOs;
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
    geoService.verifySignedLocationInfo(request.locationInfo);
    if (!userService.isHost(tx.origin)) {
      userService.grantHostRole(tx.origin);
    }

    _carIdCounter.increment();
    uint256 newCarId = _carIdCounter.current();

    engineService.verifyCreateParams(request.engineType, request.engineParams);

    _safeMint(tx.origin, newCarId);
    _setTokenURI(newCarId, request.tokenUri);

    bytes32 hash = geoService.createLocationInfo(request.locationInfo.locationInfo);

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
      request.currentlyListed,
      true,
      request.locationInfo.locationInfo.timeZoneId,
      false,
      hash
    );

    if (request.currentlyListed) carIdToListingMoment[newCarId] = block.timestamp;

    _approve(address(this), newCarId);

    eventManager.emitEvent(Schemas.EventType.Car, newCarId, uint8(Schemas.CarUpdateStatus.Add), tx.origin, tx.origin);

    return newCarId;
  }

  /// @notice Updates the information for a specific car.
  /// @param request The input parameters for updating the car.
  /// @param location The location for verifying geographic coordinates.
  /// can be empty if updateLocation is false
  /// @param updateLocation Wether update location or not
  function updateCarInfo(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.LocationInfo memory location,
    bool updateLocation
  ) public {
    require(userService.isManager(msg.sender), 'Only from manager contract.');
    require(_exists(request.carId), 'Token does not exist');
    require(ownerOf(request.carId) == tx.origin, 'Only the owner of the car can update car info');
    require(request.pricePerDayInUsdCents > 0, "Make sure the price isn't negative");
    require(request.milesIncludedPerDay > 0, "Make sure the included distance isn't negative");

    if (updateLocation) {
      idToCarInfo[request.carId].geoVerified = true;
      bytes32 hash = geoService.createLocationInfo(location);
      idToCarInfo[request.carId].locationHash = hash;
      idToCarInfo[request.carId].timeZoneId = location.timeZoneId;
    }

    engineService.verifyCreateParams(request.engineType, request.engineParams);
    if (bytes(request.tokenUri).length > 0) _setTokenURI(request.carId, request.tokenUri);

    idToCarInfo[request.carId].pricePerDayInUsdCents = request.pricePerDayInUsdCents;
    idToCarInfo[request.carId].securityDepositPerTripInUsdCents = request.securityDepositPerTripInUsdCents;
    idToCarInfo[request.carId].milesIncludedPerDay = request.milesIncludedPerDay;
    idToCarInfo[request.carId].engineParams = request.engineParams;
    idToCarInfo[request.carId].engineType = request.engineType;
    idToCarInfo[request.carId].timeBufferBetweenTripsInSec = request.timeBufferBetweenTripsInSec;
    idToCarInfo[request.carId].currentlyListed = request.currentlyListed;

    bool listed = idToCarInfo[request.carId].currentlyListed;

    if (listed && !request.currentlyListed) carIdToListingMoment[request.carId] = 0;

    if (!listed && request.currentlyListed) carIdToListingMoment[request.carId] = block.timestamp;

    eventManager.emitEvent(
      Schemas.EventType.Car,
      request.carId,
      uint8(Schemas.CarUpdateStatus.Update),
      tx.origin,
      tx.origin
    );
  }

  function getListingMoment(uint carId) public view returns (uint) {
    return carIdToListingMoment[carId];
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

    eventManager.emitEvent(Schemas.EventType.Car, carId, uint8(Schemas.CarUpdateStatus.Burn), msg.sender, msg.sender);
  }
  /// @notice temporary disable transfer function
  function transferFrom(address, address, uint256) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
    require(false, 'Not implemented.');
  }
  /// @notice temporary disable transfer function
  function safeTransferFrom(address, address, uint256) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    require(false, 'Not implemented.');
  }
  /// @notice temporary disable transfer function
  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    require(false, 'Not implemented.');
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

    uint elementsCounter = 0;
    for (uint i = 0; i < totalSupply(); i++) {
      if (_exists(i + 1)) {
        result[elementsCounter++] = idToCarInfo[i + 1];
      }
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
      RentalityUtils.isCarAvailableForUser(carId, searchCarParams, address(this), address(geoService));
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


  /// @notice Verifies the authenticity of the signed location information.
  /// @dev This function checks the validity of the signed location information using the geoService.
  /// @param locationInfo The signed location information that needs to be verified.
  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) public view {
    geoService.verifySignedLocationInfo(locationInfo);
  }

  /// @notice Constructor to initialize the RentalityCarToken contract.
  /// @param geoServiceAddress The address of the RentalityGeoService contract.
  /// @param engineServiceAddress The address of the RentalityGeoService contract.
  /// @param userServiceAddress The address of the RentalityGeoService contract.
  function initialize(
    address geoServiceAddress,
    address engineServiceAddress,
    address userServiceAddress,
    address eventManagerAddress
  ) public initializer {
    engineService = RentalityEnginesService(engineServiceAddress);
    geoService = IRentalityGeoService(geoServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    eventManager = RentalityNotificationService(eventManagerAddress);
    __ERC721_init('RentalityCarToken Test', 'RTCT');
    __Ownable_init();
  }
}
