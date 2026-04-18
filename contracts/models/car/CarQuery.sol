pragma solidity ^0.8.20;

import "../base/asset/AssetTypes.sol";
import "../common/CommonTypes.sol";
import "./CarLib.sol";
import "./CarTypes.sol";

interface ICarMain {
    function exists(uint256 id) external view returns (bool);
    function getAsset(uint256 id) external view returns (Asset memory);
    function getOwner(uint256 id) external view returns (address);
    function getCarData(uint256 id) external view returns (CarData memory);
    function totalSupply() external view returns (uint256);
    function getListingMoment(uint256 id) external view returns (uint256);
    function getGeoVerifierAddress() external view returns (address);
    function getEngineValidatorAddress() external view returns (address);
    function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) external view;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getUserDeliveryPrices(address user) external view returns (DeliveryPrices memory);
}

interface ICarGeoService {
    function getCarCountry(bytes32 locationHash) external view returns (string memory);
    function getCarState(bytes32 locationHash) external view returns (string memory);
    function getCarCity(bytes32 locationHash) external view returns (string memory);
    function getCarLocationLatitude(bytes32 locationHash) external view returns (string memory);
    function getCarLocationLongitude(bytes32 locationHash) external view returns (string memory);
}

interface ICarInsuranceAdapter {
    function getCarInsuranceInfo(uint256 carId) external view returns (CarInsuranceInfo memory);
}

contract CarQuery {
    ICarMain public immutable carMain;

    constructor(address carMainAddress) {
        carMain = ICarMain(carMainAddress);
    }

    function getCar(uint256 id) public view returns (CarInfo memory) {
        return CarInfo({asset: carMain.getAsset(id), car: carMain.getCarData(id)});
    }

    function getCarInfoWithInsurance(address insuranceAdapterAddress, uint256 carId)
        external
        view
        returns (CarInfoWithInsurance memory)
    {
        if (!carMain.exists(carId)) {
            CarInfo memory emptyCar;
            CarInsuranceInfo memory emptyInsurance;
            return CarInfoWithInsurance({carInfo: emptyCar, insuranceInfo: emptyInsurance, carMetadataURI: ""});
        }

        return CarInfoWithInsurance({
            carInfo: getCar(carId),
            insuranceInfo: ICarInsuranceAdapter(insuranceAdapterAddress).getCarInsuranceInfo(carId),
            carMetadataURI: carMain.tokenURI(carId)
        });
    }

    function getCarData(uint256 id) external view returns (CarData memory) {
        return carMain.getCarData(id);
    }

    function getOwner(uint256 id) external view returns (address) {
        if (!carMain.exists(id)) {
            return address(0);
        }
        return carMain.getOwner(id);
    }

    function exists(uint256 id) external view returns (bool) {
        return carMain.exists(id);
    }

    function totalSupply() external view returns (uint256) {
        return carMain.totalSupply();
    }

    function getGeoVerifierAddress() external view returns (address) {
        return carMain.getGeoVerifierAddress();
    }

    function getEngineValidatorAddress() external view returns (address) {
        return carMain.getEngineValidatorAddress();
    }

    function getListingMoment(uint256 id) external view returns (uint256) {
        if (!carMain.exists(id)) {
            return 0;
        }
        return carMain.getListingMoment(id);
    }

    function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) external view {
        carMain.verifySignedLocationInfo(locationInfo);
    }

    function getUserDeliveryPrices(address user) external view returns (DeliveryPrices memory) {
        return carMain.getUserDeliveryPrices(user);
    }

    function calculateDeliveryPrices(
        uint256 carId,
        LocationInfo memory pickUpLocation,
        LocationInfo memory returnLocation
    ) external view returns (uint64 pickUp, uint64 dropOf) {
        CarInfo memory car = getCar(carId);
        DeliveryPrices memory prices = carMain.getUserDeliveryPrices(car.asset.owner);
        ICarGeoService geoService = ICarGeoService(carMain.getGeoVerifierAddress());

        return CarLib.calculateDeliveryPrices(
            pickUpLocation,
            returnLocation,
            geoService.getCarLocationLatitude(car.car.locationHash),
            geoService.getCarLocationLongitude(car.car.locationHash),
            prices
        );
    }

    function getAllCars() external view returns (CarInfo[] memory) {
        return _collectCars(address(0), false, false);
    }

    function getCarsOfOwner(address owner) public view returns (CarInfo[] memory) {
        return _collectCars(owner, true, false);
    }

    function getCarsOfHost(address host) external view returns (PublicHostCarInfo[] memory) {
        CarInfo[] memory cars = getCarsOfOwner(host);
        PublicHostCarInfo[] memory result = new PublicHostCarInfo[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = _toPublicHostCarInfo(cars[i]);
        }

        return result;
    }

    function getAvailableCarsForUser(address user) public view returns (CarInfo[] memory) {
        return _collectCars(user, false, true);
    }

    function isCarAvailableForUser(uint256 carId, address user, CarSearchParams calldata searchParams)
        external
        view
        returns (bool)
    {
        if (!carMain.exists(carId)) {
            return false;
        }

        CarSearchParams memory params = searchParams;
        return _isCarAvailableForUser(getCar(carId), user, params);
    }

    function fetchAvailableCarsForUser(address user, CarSearchParams calldata searchParams, uint256 from, uint256 to)
        external
        view
        returns (CarInfo[] memory)
    {
        uint256 supply = carMain.totalSupply();
        if (from > supply) {
            from = 0;
        }
        if (to > supply) {
            to = supply;
        }
        if (to < from) {
            to = from;
        }

        CarSearchParams memory params = searchParams;
        uint256[] memory temp = new uint256[](to - from);
        uint256 itemCount;

        for (uint256 i = from; i < to; i++) {
            uint256 currentId = i + 1;
            if (!carMain.exists(currentId)) {
                continue;
            }

            CarInfo memory car = getCar(currentId);
            if (_isCarAvailableForUser(car, user, params)) {
                temp[itemCount++] = currentId;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            result[i] = getCar(temp[i]);
        }

        return result;
    }

    function _collectCars(address user, bool onlyOwnerCars, bool onlyAvailableForUser)
        internal
        view
        returns (CarInfo[] memory)
    {
        uint256 supply = carMain.totalSupply();
        uint256 count;

        for (uint256 i = 1; i <= supply; i++) {
            if (!carMain.exists(i)) {
                continue;
            }

            Asset memory asset = carMain.getAsset(i);
            CarData memory car = carMain.getCarData(i);

            if (onlyOwnerCars && asset.owner != user) {
                continue;
            }

            if (onlyAvailableForUser && (!car.currentlyListed || asset.owner == user)) {
                continue;
            }

            count++;
        }

        CarInfo[] memory result = new CarInfo[](count);
        uint256 index;

        for (uint256 i = 1; i <= supply; i++) {
            if (!carMain.exists(i)) {
                continue;
            }

            Asset memory asset = carMain.getAsset(i);
            CarData memory car = carMain.getCarData(i);

            if (onlyOwnerCars && asset.owner != user) {
                continue;
            }

            if (onlyAvailableForUser && (!car.currentlyListed || asset.owner == user)) {
                continue;
            }

            result[index++] = CarInfo({asset: asset, car: car});
        }

        return result;
    }

    function _isCarAvailableForUser(CarInfo memory car, address user, CarSearchParams memory searchParams)
        internal
        view
        returns (bool)
    {
        if (!car.car.currentlyListed || car.asset.owner == user) {
            return false;
        }

        ICarGeoService geoService = ICarGeoService(carMain.getGeoVerifierAddress());

        return (bytes(searchParams.brand).length == 0 || _containWord(_toLower(car.car.brand), _toLower(searchParams.brand)))
            && (bytes(searchParams.model).length == 0 || _containWord(_toLower(car.car.model), _toLower(searchParams.model)))
            && (
                bytes(searchParams.country).length == 0
                    || _compareStrings(_toLower(geoService.getCarCountry(car.car.locationHash)), _toLower(searchParams.country))
            ) && (
                bytes(searchParams.state).length == 0
                    || _compareStrings(_toLower(geoService.getCarState(car.car.locationHash)), _toLower(searchParams.state))
            ) && (
                bytes(searchParams.city).length == 0
                    || _compareStrings(_toLower(geoService.getCarCity(car.car.locationHash)), _toLower(searchParams.city))
            ) && (searchParams.yearOfProductionFrom == 0 || car.car.yearOfProduction >= searchParams.yearOfProductionFrom)
            && (searchParams.yearOfProductionTo == 0 || car.car.yearOfProduction <= searchParams.yearOfProductionTo)
            && (
                searchParams.pricePerDayInUsdCentsFrom == 0
                    || car.car.pricePerDayInUsdCents >= searchParams.pricePerDayInUsdCentsFrom
            ) && (
                searchParams.pricePerDayInUsdCentsTo == 0
                    || car.car.pricePerDayInUsdCents <= searchParams.pricePerDayInUsdCentsTo
            );
    }

    function _toPublicHostCarInfo(CarInfo memory car) internal pure returns (PublicHostCarInfo memory) {
        return PublicHostCarInfo({
            carId: car.asset.id,
            metadataURI: car.asset.metadataURI,
            brand: car.car.brand,
            model: car.car.model,
            yearOfProduction: car.car.yearOfProduction,
            pricePerDayInUsdCents: car.car.pricePerDayInUsdCents,
            securityDepositPerTripInUsdCents: car.car.securityDepositPerTripInUsdCents,
            milesIncludedPerDay: car.car.milesIncludedPerDay,
            currentlyListed: car.car.currentlyListed
        });
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory source = bytes(str);
        bytes memory lowered = new bytes(source.length);

        for (uint256 i = 0; i < source.length; i++) {
            uint8 charCode = uint8(source[i]);
            if (charCode >= 65 && charCode <= 90) {
                lowered[i] = bytes1(charCode + 32);
            } else {
                lowered[i] = source[i];
            }
        }

        return string(lowered);
    }

    function _containWord(string memory where, string memory what) internal pure returns (bool found) {
        bytes memory needle = bytes(what);
        bytes memory haystack = bytes(where);

        if (haystack.length < needle.length) {
            return false;
        }

        for (uint256 i = 0; i <= haystack.length - needle.length; i++) {
            bool matches = true;
            for (uint256 j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) {
                    matches = false;
                    break;
                }
            }

            if (matches) {
                return true;
            }
        }

        return false;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
