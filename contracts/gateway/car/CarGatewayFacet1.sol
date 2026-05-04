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
import '../GatewayContext.sol';

interface ICarGatewayUserProfileMain1 {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ICarGatewayUserProfileQuery1 {
}

interface ICarGatewayTripQuery1 {}

interface ICarGatewayPricingService1 {
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function defineTaxesType(address carService, uint256 carId) external view returns (uint256);
  function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
    external
    view
    returns (uint64 totalTax, PricingTaxValue[] memory taxes);
  function getBaseDiscount(address user) external view returns (PricingBaseDiscount memory);
}

interface ICarGatewayInsuranceService1 {
  function isGuestHasInsurance(address guest) external view returns (bool);
}

interface ICarGatewayDimoService1 {
  function getDimoVehicles() external view returns (uint256[] memory);
}

interface ICarGatewayGeoService1 {}

interface ICarGatewayCurrencyConverter1 {
  function getUserCurrency(address user) external view returns (UserCurrencyInfo memory);
}

contract CarGatewayFacet1 is UUPSOwnable, GatewayContext {
  CarMain public carMain;
  CarQuery public carQuery;
  CarQueryFacet1 public carQueryFacet1;
  CarQueryFacet2 public carQueryFacet2;
  ICarGatewayTripQuery1 public tripQuery;
  ICarGatewayUserProfileMain1 public userProfileMain;
  ICarGatewayUserProfileQuery1 public userProfileQuery;
  ICarGatewayPricingService1 public pricingService;
  ICarGatewayInsuranceService1 public insuranceService;
  address public carTaxAdapter;
  ICarGatewayCurrencyConverter1 public currencyConverter;
  ICarGatewayDimoService1 public dimoService;
  ICarGatewayGeoService1 public geoService;

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

  function getAvailableCarsForUser(address user) external view returns (CarInfo[] memory) {
    return carQuery.getAvailableCarsForUser(user);
  }

  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo
  ) external view returns (AvailableCarInfo memory) {
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
    CarSearchParams memory searchParams,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (SearchCarsWithDistanceInfo memory) {
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
      searchParams,
      pickUpInfo,
      returnInfo,
      from,
      to
    );
  }

  function getCarsOfHost(address host) external view returns (PublicHostCarInfo[] memory) {
    return carQuery.getCarsOfHost(host);
  }

  function getUniqCarsBrand() external view returns (string[] memory brandsArray) {
    return carQueryFacet2.getUniqCarsBrand();
  }

  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray) {
    return carQueryFacet2.getUniqModelsByBrand(brand);
  }

  function getFilterInfo(uint64 duration) external view returns (CarFilterInfo memory) {
    return carQueryFacet2.getFilterInfo(address(pricingService), duration);
  }

  function getAllCars(uint page, uint itemsPerPage) external view returns (AllCarsInfo memory allCars) {
    return carQueryFacet2.getAllCarsForAdmin(address(userProfileQuery), address(geoService), address(dimoService), page, itemsPerPage);
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
    tripQuery = ICarGatewayTripQuery1(tripQueryAddress);
    userProfileMain = ICarGatewayUserProfileMain1(userProfileMainAddress);
    userProfileQuery = ICarGatewayUserProfileQuery1(userProfileQueryAddress);
    pricingService = ICarGatewayPricingService1(pricingServiceAddress);
    insuranceService = ICarGatewayInsuranceService1(insuranceServiceAddress);
    carTaxAdapter = carTaxAdapterAddress;
    currencyConverter = ICarGatewayCurrencyConverter1(currencyConverterAddress);
    dimoService = ICarGatewayDimoService1(dimoServiceAddress);
    geoService = ICarGatewayGeoService1(geoServiceAddress);
  }

}
