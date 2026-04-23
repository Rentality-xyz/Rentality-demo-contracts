// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/car/CarMain.sol';
import '../../models/car/CarQuery.sol';
import '../../models/car/CarQueryFacet1.sol';
import '../../models/car/CarQueryFacet2.sol';
import '../../models/car/CarTypes.sol';
import '../../models/pricing/PricingTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../ARentalityContext.sol';

import './ICarViewGatewayFacet.sol';
import '../mappers/CarMapper.sol';

interface ICarViewGatewayUserProfileMain {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ICarViewGatewayUserProfileQuery {
}

interface ICarViewGatewayTripQuery {}

interface ICarViewGatewayPricingService {
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function defineTaxesType(address carService, uint256 carId) external view returns (uint256);
  function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
    external
    view
    returns (uint64 totalTax, PricingTaxValue[] memory taxes);
  function getBaseDiscount(address user) external view returns (PricingBaseDiscount memory);
}

interface ICarViewGatewayInsuranceService {
  function isGuestHasInsurance(address guest) external view returns (bool);
}

interface ICarViewGatewayDimoService {
  function getDimoVehicles() external view returns (uint256[] memory);
}

interface ICarViewGatewayGeoService {}

interface ICarViewGatewayCurrencyConverter {
  function getUserCurrency(address user) external view returns (UserCurrencyInfo memory);
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

  function getAvailableCarsForUser(address user) external view returns (CarGatewayTypes.GatewayCarInfo[] memory) {
    CarInfo[] memory cars = carQuery.getAvailableCarsForUser(user);
    CarGatewayTypes.GatewayCarInfo[] memory result = new CarGatewayTypes.GatewayCarInfo[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = CarMapper.toLegacyCarInfo(cars[i].asset, cars[i].car);
    }

    return result;
  }

  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo
  ) external view returns (CarGatewayTypes.AvailableCarDTO memory) {
    return CarMapper.toLegacyAvailableCarInfo(carQueryFacet1.buildAvailableCarDTO(
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
      CarMapper.toCommonLocationInfo(pickUpInfo),
      CarMapper.toCommonLocationInfo(returnInfo),
      _msgGatewaySender()
    ));
  }

  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    CarGatewayTypes.SearchCarParams memory searchParams,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (CarGatewayTypes.SearchCarsWithDistanceDTO memory) {
    return CarMapper.toLegacySearchCarsWithDistanceInfo(carQueryFacet1.searchAvailableCarsWithDelivery(
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
      CarMapper.toCommonLocationInfo(pickUpInfo),
      CarMapper.toCommonLocationInfo(returnInfo),
      from,
      to
    ));
  }

  function getCarsOfHost(address host) external view returns (CarGatewayTypes.PublicHostCarDTO[] memory) {
    PublicHostCarInfo[] memory cars = carQuery.getCarsOfHost(host);
    CarGatewayTypes.PublicHostCarDTO[] memory result = new CarGatewayTypes.PublicHostCarDTO[](cars.length);

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

  function getFilterInfo(uint64 duration) external view returns (CarGatewayTypes.FilterInfoDTO memory) {
    return CarMapper.toLegacyFilterInfo(carQueryFacet2.getFilterInfo(address(pricingService), duration));
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

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
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
