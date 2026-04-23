// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/car/CarMain.sol';
import '../../models/car/CarQuery.sol';
import '../../models/car/CarTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../../models/profile/UserProfileTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../ARentalityContext.sol';

import './CarMapper.sol';
import './ICarViewGatewayFacet1.sol';

interface ICarViewGatewayFacet1UserProfileMain {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ICarViewGatewayFacet1UserProfileQuery {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface ICarViewGatewayFacet1TripQuery {
  function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface ICarViewGatewayFacet1InsuranceService {
  function getInsuranceRequirement(uint256 objectId) external view returns (InsuranceRequirement memory);
}

interface ICarViewGatewayFacet1DimoService {
  function getDimoTokenId(uint256 carId) external view returns (uint256);
}

interface ICarViewGatewayFacet1GeoService {
  function getLocationInfo(bytes32 hash) external view returns (LocationInfo memory);
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);
}

contract CarViewGatewayFacet1 is UUPSOwnable, ARentalityContext, ICarViewGatewayFacet1 {
  CarMain public carMain;
  CarQuery public carQuery;
  ICarViewGatewayFacet1TripQuery public tripQuery;
  ICarViewGatewayFacet1UserProfileMain public userProfileMain;
  ICarViewGatewayFacet1UserProfileQuery public userProfileQuery;
  ICarViewGatewayFacet1InsuranceService public insuranceService;
  ICarViewGatewayFacet1DimoService public dimoService;
  ICarViewGatewayFacet1GeoService public geoService;

  function initialize(
    address carMainAddress,
    address carQueryAddress,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address insuranceServiceAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      tripQueryAddress,
      userProfileMainAddress,
      userProfileQueryAddress,
      insuranceServiceAddress,
      dimoServiceAddress,
      geoServiceAddress
    );
  }

  function updateServiceAddresses(
    address carMainAddress,
    address carQueryAddress,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address insuranceServiceAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      tripQueryAddress,
      userProfileMainAddress,
      userProfileQueryAddress,
      insuranceServiceAddress,
      dimoServiceAddress,
      geoServiceAddress
    );
  }

  function getMyCars() external view returns (CarGatewayTypes.GatewayCarInfoDTO[] memory) {
    address sender = _msgGatewaySender();
    CarInfo[] memory cars = carQuery.getCarsOfOwner(sender);
    CarGatewayTypes.GatewayCarInfoDTO[] memory result = new CarGatewayTypes.GatewayCarInfoDTO[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = CarMapper.toLegacyCarInfoDTO(
        cars[i].asset,
        cars[i].car,
        carMain.tokenURI(cars[i].asset.id),
        _isCarEditable(cars[i].asset.id),
        dimoService.getDimoTokenId(cars[i].asset.id)
      );
    }

    return result;
  }

  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfoWithInsurance memory) {
    if (!carQuery.exists(carId)) {
      CarGatewayTypes.GatewayCarInfo memory emptyCar;
      CarGatewayTypes.InsuranceCarInfo memory emptyInsurance;
      return CarGatewayTypes.GatewayCarInfoWithInsurance({carInfo: emptyCar, insuranceInfo: emptyInsurance, carMetadataURI: ''});
    }

    CarInfo memory car = carQuery.getCar(carId);
    InsuranceRequirement memory requirement = insuranceService.getInsuranceRequirement(carId);

    return CarMapper.toLegacyCarInfoWithInsurance(car.asset, car.car, requirement, carMain.tokenURI(carId));
  }

  function getCarDetails(uint256 carId) external view returns (CarGatewayTypes.GatewayCarDetails memory) {
    CarInfo memory car = carQuery.getCar(carId);
    UserProfileKYCInfo memory hostKyc = userProfileQuery.getKYCInfo(car.asset.owner);

    return CarMapper.toLegacyCarDetails(
      carId,
      car.asset,
      car.car,
      hostKyc.name,
      hostKyc.profilePhoto,
      geoService.getCarCoordinateValidity(carId),
      geoService.getLocationInfo(car.car.locationHash),
      carMain.tokenURI(carId),
      dimoService.getDimoTokenId(carId)
    );
  }

  function getDeliveryData(uint256 carId) external view returns (CarGatewayTypes.DeliveryData memory) {
    CarInfo memory car = carQuery.getCar(carId);
    DeliveryPrices memory prices = carQuery.getUserDeliveryPrices(car.asset.owner);

    return CarMapper.toLegacyDeliveryData(geoService.getLocationInfo(car.car.locationHash), prices, car.car.insuranceIncluded);
  }

  function getUserDeliveryPrices(address user) external view returns (CarGatewayTypes.GatewayDeliveryPrices memory) {
    return CarMapper.toLegacyDeliveryPrices(carQuery.getUserDeliveryPrices(user));
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
  }

  function _isCarEditable(uint256 carId) internal view returns (bool) {
    uint256[] memory carTrips = tripQuery.getActiveTrips(carId);
    for (uint256 i = 0; i < carTrips.length; i++) {
      Trip memory tripInfo = tripQuery.getTrip(carTrips[i]);
      if (
        tripInfo.booking.resourceId == carId &&
        (
          tripInfo.status != TripStatus.Finished &&
          tripInfo.status != TripStatus.Canceled &&
          (tripInfo.status != TripStatus.CheckedOutByHost || tripInfo.booking.provider != tripInfo.tripFinishedBy)
        )
      ) {
        return false;
      }
    }

    return true;
  }

  function _setServiceAddresses(
    address carMainAddress,
    address carQueryAddress,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address insuranceServiceAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) internal {
    carMain = CarMain(carMainAddress);
    carQuery = CarQuery(carQueryAddress);
    tripQuery = ICarViewGatewayFacet1TripQuery(tripQueryAddress);
    userProfileMain = ICarViewGatewayFacet1UserProfileMain(userProfileMainAddress);
    userProfileQuery = ICarViewGatewayFacet1UserProfileQuery(userProfileQueryAddress);
    insuranceService = ICarViewGatewayFacet1InsuranceService(insuranceServiceAddress);
    dimoService = ICarViewGatewayFacet1DimoService(dimoServiceAddress);
    geoService = ICarViewGatewayFacet1GeoService(geoServiceAddress);
  }
}
