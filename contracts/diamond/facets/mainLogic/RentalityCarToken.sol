
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721URIStorage} from "./standarts/ERC721URIStorage.sol";
import {ERC721} from "./standarts/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CarTokenStorage} from "../..//libraries/CarTokenStorage.sol";
import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {GeoServiceStorage} from "../../libraries/GeoServiceStorage.sol";
import {RefferalServiceStorage} from "../../libraries/RefferalServiceStorage.sol";
import {TaxesStorage} from "../../libraries/TaxesStorage.sol";
import {DimoServiceStorage} from "../../libraries/DimoServiceStorage.sol";
import {TripServiceStorage} from "../../libraries/TripServiceStorage.sol";
import {InsuranceServiceStorage} from "../../libraries/InsuranceServiceStorage.sol";
import {ARentalityEventManager} from "../abstract/ARentalityEventManager.sol";
import {RentalityUtils} from "../../libraries/getters/RentalityUtils.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {Schemas} from '../../../Schemas.sol';
import {RentalityCarTokenHelper} from "../../libraries/getters/RentalityCarTokenHelper.sol";

contract RentalityCarToken is ERC721URIStorage, ARentalityEventManager {
  using RentalityUtils for string;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_)  {}


    function totalSupply() public view returns (uint) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    return s._carIdCounter;
  }

  /// @notice Retrieves information about a car based on its ID.
  /// @param carId The ID of the car.
  /// @return A struct containing information about the specified car.
  function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfo memory) {
    return CarTokenStorage.getCarInfoById(carId);
  }

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
    uint carsOwnedByHost = balanceOf(host);
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    Schemas.PublicHostCarDTO[] memory carDTOs = new Schemas.PublicHostCarDTO[](carsOwnedByHost);
    uint carCounter = 0;
    for (uint i = 1; i <= s._carIdCounter; i++) {
      if (_exists(i) && ownerOf(i) == host) {
        Schemas.CarInfo memory car = s.idToCarInfo[i];

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
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    bytes32 carVinNumberHash = keccak256(abi.encodePacked(carVinNumber));

    for (uint i = 0; i < totalSupply(); i++) {
      if (s.idToCarInfo[i + 1].carVinNumberHash == carVinNumberHash) return false;
    }

    return true;
  }

  /// @notice Adds a new car to the system with the provided information.
  /// @param request The input parameters for creating the new car.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request, address user) public returns (uint) {

      RefferalServiceStorage.passReferralProgram(
      Schemas.RefferalProgram.AddCar,
      abi.encode(request.currentlyListed),
      msg.sender
    );
    require(TaxesStorage.taxExists(request.locationInfo.locationInfo) != 0, 'Tax not exist.');

    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();

    require(UserServiceStorage.hasPassedKYCAndTC(user), 'KYC or TC has not passed.');
    require(request.pricePerDayInUsdCents > 0, "Make sure the price isn't negative");
    require(request.milesIncludedPerDay > 0, "Make sure the included distance isn't negative");
    require(isUniqueVinNumber(request.carVinNumber), 'Car with this VIN number already exists');
    GeoServiceStorage.verifySignedLocationInfo(request.locationInfo);
    if (!UserServiceStorage.isHost(user)) {
      UserServiceStorage.grantHostRole(user);
    }

    s._carIdCounter += 1;
    uint256 newCarId = s._carIdCounter;

    s.enginesService.verifyCreateParams(request.engineType, request.engineParams);

    _safeMint(user, newCarId);
    _setTokenURI(newCarId, request.tokenUri);


    bytes32 hash = GeoServiceStorage.createLocationInfo(request.locationInfo.locationInfo);

    s.idToCarInfo[newCarId] = Schemas.CarInfo(
      newCarId,
      request.carVinNumber,
      keccak256(abi.encodePacked(request.carVinNumber)),
      user,
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

    if (request.currentlyListed) s.carIdToListingMoment[newCarId] = block.timestamp;

    _approve(address(this), newCarId, address(0));
    bool isCorrectSignature = UserServiceStorage.isSignatureManager(
      ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes(Strings.toString(request.dimoTokenId))), request.signedDimoTokenId)
    );
    require(isCorrectSignature, 'Dimo signature is not correct');
    DimoServiceStorage.saveDimoTokenId(request.dimoTokenId, newCarId);
    InsuranceServiceStorage.saveInsuranceRequired(
      newCarId,
      request.insurancePriceInUsdCents,
      request.insuranceRequired
    );
    emitEvent(Schemas.EventType.Car, newCarId, uint8(Schemas.CarUpdateStatus.Add), user, user);

    return newCarId;
  }


 function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) public {
    TripServiceStorage.isCarEditable(request.carId);
    
    if (location.signature.length > 0)
    GeoServiceStorage.verifySignedLocationInfo(location);

     CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
     RefferalServiceStorage.passReferralProgram(
      Schemas.RefferalProgram.UnlistedCar,
      abi.encode(s.idToCarInfo[request.carId].currentlyListed, request.currentlyListed),
      msg.sender
    );
    InsuranceServiceStorage.saveInsuranceRequired(
      request.carId,
      request.insurancePriceInUsdCents,
      request.insuranceRequired
    );
    require(_exists(request.carId), 'Token does not exist');
    require(ownerOf(request.carId) == msg.sender, 'Only the owner of the car can update car info');
    require(request.pricePerDayInUsdCents > 0, "Make sure the price isn't negative");
    require(request.milesIncludedPerDay > 0, "Make sure the included distance isn't negative");

    if (bytes(location.signature).length > 0) {
      s.idToCarInfo[request.carId].geoVerified = true;
      bytes32 hash = GeoServiceStorage.createLocationInfo(location.locationInfo);
      s.idToCarInfo[request.carId].locationHash = hash;
      s.idToCarInfo[request.carId].timeZoneId = location.locationInfo.timeZoneId;
    }

    s.enginesService.verifyCreateParams(request.engineType, request.engineParams);
    if (bytes(request.tokenUri).length > 0) _setTokenURI(request.carId, request.tokenUri);

    s.idToCarInfo[request.carId].pricePerDayInUsdCents = request.pricePerDayInUsdCents;
    s.idToCarInfo[request.carId].securityDepositPerTripInUsdCents = request.securityDepositPerTripInUsdCents;
    s.idToCarInfo[request.carId].milesIncludedPerDay = request.milesIncludedPerDay;
    s.idToCarInfo[request.carId].engineParams = request.engineParams;
    s.idToCarInfo[request.carId].engineType = request.engineType;
    s.idToCarInfo[request.carId].timeBufferBetweenTripsInSec = request.timeBufferBetweenTripsInSec;
    s.idToCarInfo[request.carId].currentlyListed = request.currentlyListed;

    bool listed = s.idToCarInfo[request.carId].currentlyListed;

    if (listed && !request.currentlyListed) s.carIdToListingMoment[request.carId] = 0;

    if (!listed && request.currentlyListed) s.carIdToListingMoment[request.carId] = block.timestamp;

   emitEvent(Schemas.EventType.Car, request.carId, uint8(Schemas.CarUpdateStatus.Update), msg.sender, msg.sender);
  }

  function getListingMoment(uint carId) public view returns (uint) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    return s.carIdToListingMoment[carId];
  }

  /// @notice Updates the token URI associated with a specific car.
  /// @param carId The ID of the car.
  /// @param tokenUri The new token URI.
  function updateCarTokenUri(uint256 carId, string memory tokenUri, address user) public {
    require(_exists(carId), 'Token does not exist');
    require(ownerOf(carId) == user, 'Only the owner of the car can update the token URI');

    _setTokenURI(carId, tokenUri);
  }

  /// @notice Burns a specific car token, removing it from the system.
  /// @param carId The ID of the car to be burned.
  function burnCar(uint256 carId) public {
    require(_exists(carId), 'Token does not exist');
    require(ownerOf(carId) == msg.sender, 'Only the owner of the car can burn the token');
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    _burn(carId);
    delete s.idToCarInfo[carId];

   emitEvent(Schemas.EventType.Car, carId, uint8(Schemas.CarUpdateStatus.Burn), msg.sender, msg.sender);
  }
  /// @notice temporary disable transfer function
  function transferFrom(address, address, uint256) public pure override(ERC721) {
    require(false, 'Not implemented.');
  }
  /// @notice temporary disable transfer function
  function safeTransferFrom(address, address, uint256) public virtual override(ERC721) {
    require(false, 'Not implemented.');
  }
  /// @notice temporary disable transfer function
  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override(ERC721) {
    require(false, 'Not implemented.');
  }

  /// @notice Retrieves information about all cars in the system.
  /// @return An array containing information about all cars.
  function getAllCars() public view returns (Schemas.CarInfo[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
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
        result[elementsCounter++] = s.idToCarInfo[i + 1];
      }
    }

    return result;
  }

  function isCarAvailableForUser(uint256 carId, address user) private view returns (bool) {
     CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    return _exists(carId) && s.idToCarInfo[carId].currentlyListed && ownerOf(carId) != user;
  }

  /// @notice Retrieves available cars for a specific user.
  /// @dev Only used by main contract
  /// @param user The address of the user.
  /// @return An array containing information about available cars for the user.
  function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
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
        Schemas.CarInfo storage currentItem = s.idToCarInfo[currentId];
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }
  /// @notice Checks if a car is available for a specific user based on search parameters.
  /// @dev Determines availability based on several conditions, including ownership and search parameters.
  /// @param carId The ID of the car being checked.
  /// @param searchCarParams The parameters used to filter available cars.
  /// @return A boolean indicating whether the car is available for the user.
  function isCarAvailableForUser(
    uint256 carId,
    address user,
    Schemas.SearchCarParams memory searchCarParams
  ) public view returns (bool) {
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
    return
      _exists(carId) &&
      s.idToCarInfo[carId].currentlyListed &&
      ownerOf(carId) != user &&
      RentalityCarTokenHelper._isCarAvailableForUser(carId, searchCarParams);
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
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
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
        Schemas.CarInfo memory currentItem = s.idToCarInfo[currentId];
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
    CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
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
        Schemas.CarInfo memory currentItem = s.idToCarInfo[currentId];
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Verifies the authenticity of the signed location information.
  /// @dev This function checks the validity of the signed location information using the geoService.
  /// @param locationInfo The signed location information that needs to be verified.
  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) internal view {
    GeoServiceStorage.verifySignedLocationInfo(locationInfo);
  }

  
  function _exists(uint256 carId) private view returns (bool) {
    return _ownerOf(carId) != address(0);
  }


}