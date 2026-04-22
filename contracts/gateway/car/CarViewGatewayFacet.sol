// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/car/CarMain.sol';
import '../../models/car/CarQuery.sol';
import '../../models/car/CarQueryFacet1.sol';
import '../../models/car/CarQueryFacet2.sol';
import '../../models/car/CarTypes.sol';
import '../../models/pricing/RentalPricingTypes.sol';
import '../../models/profile/UserProfileTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../../models/common/Schemas.sol';
import '../ARentalityContext.sol';

import './ICarViewGatewayFacet.sol';
import './CarMapper.sol';

interface ICarViewGatewayUserProfileMain {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ICarViewGatewayUserProfileQuery {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface ICarViewGatewayTripQuery {
  function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface ICarViewGatewayPricingService {
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function defineTaxesType(address carService, uint256 carId) external view returns (uint256);
  function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
    external
    view
    returns (uint64 totalTax, RentalTaxValue[] memory taxes);
  function getBaseDiscount(address user) external view returns (RentalBaseDiscount memory);
}

interface ICarViewGatewayInsuranceService {
  function getInsuranceRequirement(uint256 objectId) external view returns (InsuranceRequirement memory);
  function isGuestHasInsurance(address guest) external view returns (bool);
}

interface ICarViewGatewayDimoService {
  function getDimoTokenId(uint256 carId) external view returns (uint256);
  function getDimoVehicles() external view returns (uint256[] memory);
}

interface ICarViewGatewayGeoService {
  function getLocationInfo(bytes32 hash) external view returns (Schemas.LocationInfo memory);
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);
}

interface ICarViewGatewayCurrencyConverter {
  function getUserCurrency(address user) external view returns (Schemas.UserCurrencyDTO memory);
}

contract CarViewGatewayFacet is UUPSOwnable, ARentalityContext, ICarViewGatewayFacet {
  CarMain public carMain;
  CarQuery public carQuery;
  CarQueryFacet1 public carQueryFacet1;
  CarQueryFacet2 public carQueryFacet2;
  ICarViewGatewayTripQuery public tripQuery;
  ICarViewGatewayUserProfileMain public userProfileMain;
  ICarViewGatewayUserProfileQuery public userProfileQuery;
  ICarViewGatewayPricingService public pricingService;
  ICarViewGatewayInsuranceService public insuranceService;
  address public carTaxAdapter;
  ICarViewGatewayCurrencyConverter public currencyConverter;
  ICarViewGatewayDimoService public dimoService;
  ICarViewGatewayGeoService public geoService;

  function initialize(
    address carMainAddress,
    address carQueryAddress,
    address carQueryFacet1Address,
    address carQueryFacet2Address,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address carTaxAdapterAddress,
    address currencyConverterAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      carQueryFacet1Address,
      carQueryFacet2Address,
      tripQueryAddress,
      userProfileMainAddress,
      userProfileQueryAddress,
      pricingServiceAddress,
      insuranceServiceAddress,
      carTaxAdapterAddress,
      currencyConverterAddress,
      dimoServiceAddress,
      geoServiceAddress
    );
  }

  function updateServiceAddresses(
    address carMainAddress,
    address carQueryAddress,
    address carQueryFacet1Address,
    address carQueryFacet2Address,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address carTaxAdapterAddress,
    address currencyConverterAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      carQueryFacet1Address,
      carQueryFacet2Address,
      tripQueryAddress,
      userProfileMainAddress,
      userProfileQueryAddress,
      pricingServiceAddress,
      insuranceServiceAddress,
      carTaxAdapterAddress,
      currencyConverterAddress,
      dimoServiceAddress,
      geoServiceAddress
    );
  }

  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory) {
    CarInfo[] memory cars = carQuery.getAvailableCarsForUser(user);
    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = CarMapper.toLegacyCarInfo(cars[i].asset, cars[i].car);
    }

    return result;
  }

  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.AvailableCarDTO memory) {
    return carQueryFacet1.buildAvailableCarDTO(
      CarAvailabilityContext({
        tripQuery: address(tripQuery),
        userProfileQuery: address(userProfileQuery),
        pricingService: address(pricingService),
        insuranceService: address(insuranceService),
        dimoService: address(dimoService),
        geoService: address(geoService),
        currencyConverter: address(currencyConverter),
        carTaxAdapter: carTaxAdapter
      }),
      carId,
      startDateTime,
      endDateTime,
      carMain.tokenURI(carId),
      pickUpInfo,
      returnInfo,
      _msgGatewaySender()
    );
  }

  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (Schemas.SearchCarsWithDistanceDTO memory) {
    return carQueryFacet1.searchAvailableCarsWithDelivery(
      CarAvailabilityContext({
        tripQuery: address(tripQuery),
        userProfileQuery: address(userProfileQuery),
        pricingService: address(pricingService),
        insuranceService: address(insuranceService),
        dimoService: address(dimoService),
        geoService: address(geoService),
        currencyConverter: address(currencyConverter),
        carTaxAdapter: carTaxAdapter
      }),
      _msgGatewaySender(),
      startDateTime,
      endDateTime,
      CarMapper.toCommonSearchCarParams(searchParams),
      pickUpInfo,
      returnInfo,
      from,
      to
    );
  }

  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory) {
    address sender = _msgGatewaySender();
    CarInfo[] memory cars = carQuery.getCarsOfOwner(sender);
    Schemas.CarInfoDTO[] memory result = new Schemas.CarInfoDTO[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = Schemas.CarInfoDTO({
        carInfo: CarMapper.toLegacyCarInfo(cars[i].asset, cars[i].car),
        metadataURI: carMain.tokenURI(cars[i].asset.id),
        isEditable: _isCarEditable(cars[i].asset.id),
        dimoTokenId: dimoService.getDimoTokenId(cars[i].asset.id)
      });
    }

    return result;
  }

  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfoWithInsurance memory) {
    if (!carQuery.exists(carId)) {
      Schemas.CarInfo memory emptyCar;
      Schemas.InsuranceCarInfo memory emptyInsurance;
      return Schemas.CarInfoWithInsurance({carInfo: emptyCar, insuranceInfo: emptyInsurance, carMetadataURI: ''});
    }

    CarInfo memory car = carQuery.getCar(carId);
    InsuranceRequirement memory requirement = insuranceService.getInsuranceRequirement(carId);

    return Schemas.CarInfoWithInsurance({
      carInfo: CarMapper.toLegacyCarInfo(car.asset, car.car),
      insuranceInfo: Schemas.InsuranceCarInfo({required: requirement.required, priceInUsdCents: requirement.priceInUsdCents}),
      carMetadataURI: carMain.tokenURI(carId)
    });
  }

  function getCarDetails(uint256 carId) external view returns (Schemas.CarDetails memory) {
    CarInfo memory car = carQuery.getCar(carId);
    UserProfileKYCInfo memory hostKyc = userProfileQuery.getKYCInfo(car.asset.owner);

    return Schemas.CarDetails({
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

  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory) {
    PublicHostCarInfo[] memory cars = carQuery.getCarsOfHost(host);
    Schemas.PublicHostCarDTO[] memory result = new Schemas.PublicHostCarDTO[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = CarMapper.toLegacyPublicHostCarDTO(cars[i]);
    }

    return result;
  }

  function getUniqCarsBrand() external view returns (string[] memory brandsArray) {
    return carQueryFacet2.getUniqCarsBrand();
  }

  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray) {
    return carQueryFacet2.getUniqModelsByBrand(brand);
  }

  function getFilterInfo(uint64 duration) external view returns (Schemas.FilterInfoDTO memory) {
    return carQueryFacet2.getFilterInfo(address(pricingService), duration);
  }

  function getDimoVehicles() external view returns (uint[] memory) {
    return dimoService.getDimoVehicles();
  }

  function getCarMetadataURI(uint256 carId) external view returns (string memory) {
    return carMain.tokenURI(carId);
  }

  function getTotalCarsAmount() external view returns (uint256) {
    return carMain.totalSupply();
  }

  function getDeliveryData(uint256 carId) external view returns (Schemas.DeliveryData memory) {
    CarInfo memory car = carQuery.getCar(carId);
    DeliveryPrices memory prices = carQuery.getUserDeliveryPrices(car.asset.owner);

    return Schemas.DeliveryData({
      locationInfo: geoService.getLocationInfo(car.car.locationHash),
      underTwentyFiveMilesInUsdCents: prices.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: prices.aboveTwentyFiveMilesInUsdCents,
      insuranceIncluded: car.car.insuranceIncluded
    });
  }

  function getUserDeliveryPrices(address user) external view returns (Schemas.DeliveryPrices memory) {
    DeliveryPrices memory prices = carQuery.getUserDeliveryPrices(user);
    return Schemas.DeliveryPrices({
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
    address carQueryFacet1Address,
    address carQueryFacet2Address,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address carTaxAdapterAddress,
    address currencyConverterAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) internal {
    carMain = CarMain(carMainAddress);
    carQuery = CarQuery(carQueryAddress);
    carQueryFacet1 = CarQueryFacet1(carQueryFacet1Address);
    carQueryFacet2 = CarQueryFacet2(carQueryFacet2Address);
    tripQuery = ICarViewGatewayTripQuery(tripQueryAddress);
    userProfileMain = ICarViewGatewayUserProfileMain(userProfileMainAddress);
    userProfileQuery = ICarViewGatewayUserProfileQuery(userProfileQueryAddress);
    pricingService = ICarViewGatewayPricingService(pricingServiceAddress);
    insuranceService = ICarViewGatewayInsuranceService(insuranceServiceAddress);
    carTaxAdapter = carTaxAdapterAddress;
    currencyConverter = ICarViewGatewayCurrencyConverter(currencyConverterAddress);
    dimoService = ICarViewGatewayDimoService(dimoServiceAddress);
    geoService = ICarViewGatewayGeoService(geoServiceAddress);
  }
}
