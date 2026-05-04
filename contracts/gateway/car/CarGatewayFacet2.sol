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
import '../GatewayContext.sol';

interface ICarGatewayUserProfileMain2 {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ICarGatewayUserProfileQuery2 {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface ICarGatewayTripQuery2 {
  function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface ICarGatewayInsuranceService2 {
  function getInsuranceRequirement(uint256 objectId) external view returns (InsuranceRequirement memory);
}

interface ICarGatewayDimoService2 {
  function getDimoTokenId(uint256 carId) external view returns (uint256);
}

interface ICarGatewayGeoService2 {
  function getLocationInfo(bytes32 hash) external view returns (LocationInfo memory);
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);
}

contract CarGatewayFacet2 is UUPSOwnable, GatewayContext {
  CarMain public carMain;
  CarQuery public carQuery;
  ICarGatewayTripQuery2 public tripQuery;
  ICarGatewayUserProfileMain2 public userProfileMain;
  ICarGatewayUserProfileQuery2 public userProfileQuery;
  ICarGatewayInsuranceService2 public insuranceService;
  ICarGatewayDimoService2 public dimoService;
  ICarGatewayGeoService2 public geoService;

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

  function getMyCars() external view returns (CarInfoDTO[] memory) {
    address sender = _msgGatewaySender();
    CarInfo[] memory cars = carQuery.getCarsOfOwner(sender);
    CarInfoDTO[] memory result = new CarInfoDTO[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = CarInfoDTO({
        carInfo: cars[i],
        metadataURI: carMain.tokenURI(cars[i].asset.id),
        isEditable: _isCarEditable(cars[i].asset.id),
        dimoTokenId: dimoService.getDimoTokenId(cars[i].asset.id)
      });
    }

    return result;
  }

  function getCarInfoById(uint256 carId) external view returns (CarInfoWithInsurance memory) {
    return carQuery.getCarInfoWithInsurance(address(insuranceService), carId);
  }

  function getCarDetails(uint256 carId) external view returns (CarDetails memory) {
    CarInfo memory car = carQuery.getCar(carId);
    UserProfileKYCInfo memory hostKyc = userProfileQuery.getKYCInfo(car.asset.owner);

    return CarDetails({
      carId: carId,
      hostName: hostKyc.name,
      hostPhotoUrl: hostKyc.profilePhoto,
      host: car.asset.owner,
      brand: car.car.brand,
      model: car.car.model,
      yearOfProduction: car.car.yearOfProduction,
      pricePerDayInUsdCents: car.car.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: car.car.securityDepositPerTripInUsdCents,
      milesIncludedPerDay: car.car.milesIncludedPerDay,
      engineType: car.car.engineType,
      engineParams: car.car.engineParams,
      geoVerified: geoService.getCarCoordinateValidity(carId),
      currentlyListed: car.car.currentlyListed,
      locationInfo: geoService.getLocationInfo(car.car.locationHash),
      carVinNumber: car.car.carVinNumber,
      carMetadataURI: carMain.tokenURI(carId),
      dimoTokenId: dimoService.getDimoTokenId(carId)
    });
  }

  function getDeliveryData(uint256 carId) external view returns (CarGatewayTypes.DeliveryData memory) {
    CarInfo memory car = carQuery.getCar(carId);
    DeliveryPrices memory prices = carQuery.getUserDeliveryPrices(car.asset.owner);

    return CarGatewayTypes.DeliveryData({
      locationInfo: geoService.getLocationInfo(car.car.locationHash),
      underTwentyFiveMilesInUsdCents: prices.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: prices.aboveTwentyFiveMilesInUsdCents,
      insuranceIncluded: car.car.insuranceIncluded
    });
  }

  function getUserDeliveryPrices(address user) external view returns (CarGatewayTypes.GatewayDeliveryPrices memory) {
    DeliveryPrices memory prices = carQuery.getUserDeliveryPrices(user);
    return CarGatewayTypes.GatewayDeliveryPrices({
      underTwentyFiveMilesInUsdCents: prices.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: prices.aboveTwentyFiveMilesInUsdCents,
      initialized: prices.initialized
    });
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
    tripQuery = ICarGatewayTripQuery2(tripQueryAddress);
    userProfileMain = ICarGatewayUserProfileMain2(userProfileMainAddress);
    userProfileQuery = ICarGatewayUserProfileQuery2(userProfileQueryAddress);
    insuranceService = ICarGatewayInsuranceService2(insuranceServiceAddress);
    dimoService = ICarGatewayDimoService2(dimoServiceAddress);
    geoService = ICarGatewayGeoService2(geoServiceAddress);
  }
}
