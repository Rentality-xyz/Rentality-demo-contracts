// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ERC721URIStorageUpgradeable,
    ERC721Upgradeable,
    IERC721Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "../base/asset/AssetBase.sol";
import "../base/asset/AssetTypes.sol";
import "./CarLib.sol";
import "./CarTypes.sol";
import "../../rentality_old/proxy/UUPSOwnable.sol";

interface ICarUserAccess {
    function isRentalityPlatform(address user) external view returns (bool);
    function isAdmin(address user) external view returns (bool);
    function hasPassedKYCAndTC(address user) external view returns (bool);
    function isHost(address user) external view returns (bool);
    function grantHostRole(address user) external;
}

interface ICarEngineValidator {
    function verifyCreateParams(uint8 eType, uint64[] memory params) external view;
}

interface ICarGeoVerifier {
    function createLocationInfo(LocationInfo memory info) external returns (bytes32);
    function verifySignedLocationInfo(SignedLocationInfo memory signed) external view;
}

interface ICarEventEmitter {
    function emitCarEvent(uint256 id, CarUpdateStatus status, address from, address to) external;
}



contract CarMain is AssetBase, ERC721URIStorageUpgradeable, UUPSOwnable {
    ICarGeoVerifier public geoVerifier;
    ICarEngineValidator public engineValidator;
    ICarUserAccess public userAccess;
    ICarEventEmitter public eventEmitter;

    mapping(uint256 => CarData) internal cars;
    mapping(bytes32 => uint256) internal vinHashToAssetId;
    mapping(uint256 => uint256) internal listingMomentByAssetId;

    error OnlyPlatform();
    error OnlyAdmin();
    error DuplicateVin(bytes32 vinHash);
    error UserDidNotPassKyc(address user);

    event CarCreated(uint256 indexed id, address indexed owner, string brand, string model);
    event CarUpdated(uint256 indexed id);

    modifier onlyPlatform() {
        if (!userAccess.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!(userAccess.isAdmin(msg.sender) || userAccess.isAdmin(tx.origin))) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address geoVerifierAddress,
        address engineValidatorAddress,
        address userAccessAddress,
        address eventEmitterAddress
    ) public initializer {
        __ERC721_init("RentalityCarToken Test", "RTCT");
        __ERC721URIStorage_init();
        __Ownable_init();

        geoVerifier = ICarGeoVerifier(geoVerifierAddress);
        engineValidator = ICarEngineValidator(engineValidatorAddress);
        userAccess = ICarUserAccess(userAccessAddress);
        eventEmitter = ICarEventEmitter(eventEmitterAddress);
    }

    function createCar(CreateCarRequest calldata request, address user) external onlyPlatform returns (uint256) {
        if (!userAccess.hasPassedKYCAndTC(user)) {
            revert UserDidNotPassKyc(user);
        }

        CarLib.validatePricing(request.pricePerDayInUsdCents, request.milesIncludedPerDay);

        bytes32 vinHash = CarLib.hashVin(request.carVinNumber);
        if (vinHashToAssetId[vinHash] != 0) {
            revert DuplicateVin(vinHash);
        }

        geoVerifier.verifySignedLocationInfo(request.locationInfo);
        engineValidator.verifyCreateParams(request.engineType, request.engineParams);

        if (!userAccess.isHost(user)) {
            userAccess.grantHostRole(user);
        }

        uint256 id = _createAsset(
            user,
            CarLib.buildName(request.asset.name, request.brand, request.model),
            request.asset.metadataURI
        );
        _safeMint(user, id);
        _setTokenURI(id, request.asset.metadataURI);

        bytes32 locationHash = geoVerifier.createLocationInfo(request.locationInfo.locationInfo);

        cars[id] = CarData({
            carVinNumber: request.carVinNumber,
            carVinNumberHash: vinHash,
            brand: request.brand,
            model: request.model,
            yearOfProduction: request.yearOfProduction,
            pricePerDayInUsdCents: request.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: request.securityDepositPerTripInUsdCents,
            engineType: request.engineType,
            engineParams: request.engineParams,
            milesIncludedPerDay: request.milesIncludedPerDay,
            timeBufferBetweenTripsInSec: request.timeBufferBetweenTripsInSec,
            currentlyListed: request.currentlyListed,
            geoVerified: true,
            timeZoneId: request.locationInfo.locationInfo.timeZoneId,
            insuranceIncluded: false,
            locationHash: locationHash
        });

        vinHashToAssetId[vinHash] = id;
        if (request.currentlyListed) {
            listingMomentByAssetId[id] = block.timestamp;
        }

        _approve(address(this), id);

        eventEmitter.emitCarEvent(id, CarUpdateStatus.Add, user, user);
        emit CarCreated(id, user, request.brand, request.model);
        return id;
    }

    function updateCar(uint256 id, UpdateCarRequest calldata request, address user) external onlyPlatform assetExists(id) {
        _checkCanManageAsset(id, user);
        CarLib.validatePricing(request.pricePerDayInUsdCents, request.milesIncludedPerDay);

        _updateAsset(id, request.asset.name, request.asset.metadataURI);
        if (bytes(request.asset.metadataURI).length > 0) {
            _setTokenURI(id, request.asset.metadataURI);
        }

        if (request.updateLocation) {
            bytes32 locationHash = geoVerifier.createLocationInfo(request.location);
            cars[id].geoVerified = true;
            cars[id].locationHash = locationHash;
            cars[id].timeZoneId = request.location.timeZoneId;
        }

        engineValidator.verifyCreateParams(request.engineType, request.engineParams);

        bool wasListed = cars[id].currentlyListed;

        cars[id].pricePerDayInUsdCents = request.pricePerDayInUsdCents;
        cars[id].securityDepositPerTripInUsdCents = request.securityDepositPerTripInUsdCents;
        cars[id].milesIncludedPerDay = request.milesIncludedPerDay;
        cars[id].engineParams = request.engineParams;
        cars[id].engineType = request.engineType;
        cars[id].timeBufferBetweenTripsInSec = request.timeBufferBetweenTripsInSec;
        cars[id].currentlyListed = request.currentlyListed;

        CarLib.updateListingMoment(listingMomentByAssetId, id, wasListed, request.currentlyListed);

        eventEmitter.emitCarEvent(id, CarUpdateStatus.Update, user, user);
        emit CarUpdated(id);
    }

    function getCarData(uint256 id) external view assetExists(id) returns (CarData memory) {
        return cars[id];
    }

    function totalSupply() external view returns (uint256) {
        return nextAssetId;
    }

    function getGeoVerifierAddress() external view returns (address) {
        return address(geoVerifier);
    }

    function getEngineValidatorAddress() external view returns (address) {
        return address(engineValidator);
    }

    function isUniqueVinNumber(string memory carVinNumber) external view returns (bool) {
        return vinHashToAssetId[CarLib.hashVin(carVinNumber)] == 0;
    }

    function getListingMoment(uint256 id) external view returns (uint256) {
        if (!exists(id)) {
            return 0;
        }
        return listingMomentByAssetId[id];
    }

    function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) external view {
        geoVerifier.verifySignedLocationInfo(locationInfo);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            return "";
        }

        return super.tokenURI(tokenId);
    }

    function updateCarTokenUri(uint256 id, string memory metadataURI, address user) external assetExists(id) {
        _checkCanManageAsset(id, user);
        _setTokenURI(id, metadataURI);
        assets[id].metadataURI = metadataURI;
    }

    function burnCar(uint256 id) external assetExists(id) {
        if (assets[id].owner != msg.sender) {
            revert NotAssetOwner(id, msg.sender);
        }

        bytes32 vinHash = cars[id].carVinNumberHash;

        _burn(id);

        delete vinHashToAssetId[vinHash];
        delete listingMomentByAssetId[id];
        delete cars[id];
        delete assets[id];

        eventEmitter.emitCarEvent(id, CarUpdateStatus.Burn, msg.sender, msg.sender);
    }

    function updateGeoVerifierAddress(address geoVerifierAddress) external onlyAdmin {
        geoVerifier = ICarGeoVerifier(geoVerifierAddress);
    }

    function updateEngineValidatorAddress(address engineValidatorAddress) external onlyAdmin {
        engineValidator = ICarEngineValidator(engineValidatorAddress);
    }

    function updateUserAccessAddress(address userAccessAddress) external onlyAdmin {
        userAccess = ICarUserAccess(userAccessAddress);
    }

    function updateEventEmitterAddress(address eventEmitterAddress) external onlyAdmin {
        eventEmitter = ICarEventEmitter(eventEmitterAddress);
    }

    function transferFrom(address, address, uint256) public pure override(ERC721Upgradeable, IERC721Upgradeable) {
        revert("Not implemented.");
    }

    function safeTransferFrom(address, address, uint256)
        public
        pure
        override(ERC721Upgradeable, IERC721Upgradeable)
    {
        revert("Not implemented.");
    }

    function safeTransferFrom(address, address, uint256, bytes memory)
        public
        pure
        override(ERC721Upgradeable, IERC721Upgradeable)
    {
        revert("Not implemented.");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
}






