// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../models/base/asset/AssetTypes.sol';
import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../../models/car/CarTypes.sol';
import '../../models/pricing/RentalPricingTypes.sol';

library CarMapper {
  function toLegacyCarInfo(Asset memory asset, CarData memory car) internal pure returns (CarGatewayTypes.GatewayCarInfo memory) {
    return CarGatewayTypes.GatewayCarInfo({
      carId: asset.id,
      carVinNumber: car.carVinNumber,
      carVinNumberHash: car.carVinNumberHash,
      createdBy: asset.owner,
      brand: car.brand,
      model: car.model,
      yearOfProduction: car.yearOfProduction,
      pricePerDayInUsdCents: car.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
      engineType: car.engineType,
      engineParams: car.engineParams,
      milesIncludedPerDay: car.milesIncludedPerDay,
      timeBufferBetweenTripsInSec: car.timeBufferBetweenTripsInSec,
      currentlyListed: car.currentlyListed,
      geoVerified: car.geoVerified,
      timeZoneId: car.timeZoneId,
      insuranceIncluded: car.insuranceIncluded,
      locationHash: car.locationHash
    });
  }

  function toLegacyPublicHostCarDTO(PublicHostCarInfo memory car) internal pure returns (CarGatewayTypes.PublicHostCarDTO memory) {
    return CarGatewayTypes.PublicHostCarDTO({
      carId: car.carId,
      metadataURI: car.metadataURI,
      brand: car.brand,
      model: car.model,
      yearOfProduction: car.yearOfProduction,
      pricePerDayInUsdCents: car.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
      milesIncludedPerDay: car.milesIncludedPerDay,
      currentlyListed: car.currentlyListed
    });
  }

  function toLegacyCarInfoDTO(
    Asset memory asset,
    CarData memory car,
    string memory metadataURI,
    bool isEditable,
    uint256 dimoTokenId
  ) internal pure returns (CarGatewayTypes.GatewayCarInfoDTO memory) {
    return CarGatewayTypes.GatewayCarInfoDTO({
      carInfo: toLegacyCarInfo(asset, car),
      metadataURI: metadataURI,
      isEditable: isEditable,
      dimoTokenId: dimoTokenId
    });
  }

  function toLegacyCarInfoWithInsurance(
    Asset memory asset,
    CarData memory car,
    InsuranceRequirement memory requirement,
    string memory metadataURI
  ) internal pure returns (CarGatewayTypes.GatewayCarInfoWithInsurance memory) {
    return CarGatewayTypes.GatewayCarInfoWithInsurance({
      carInfo: toLegacyCarInfo(asset, car),
      insuranceInfo: CarGatewayTypes.InsuranceCarInfo({
        required: requirement.required,
        priceInUsdCents: requirement.priceInUsdCents
      }),
      carMetadataURI: metadataURI
    });
  }

  function toLegacyCarDetails(
    uint256 carId,
    Asset memory asset,
    CarData memory car,
    string memory hostName,
    string memory hostPhotoUrl,
    bool geoVerified,
    LocationInfo memory location,
    string memory metadataURI,
    uint256 dimoTokenId
  ) internal pure returns (CarGatewayTypes.GatewayCarDetails memory) {
    return CarGatewayTypes.GatewayCarDetails({
      carId: carId,
      hostName: hostName,
      hostPhotoUrl: hostPhotoUrl,
      host: asset.owner,
      brand: car.brand,
      model: car.model,
      yearOfProduction: car.yearOfProduction,
      pricePerDayInUsdCents: car.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
      milesIncludedPerDay: car.milesIncludedPerDay,
      engineType: car.engineType,
      engineParams: car.engineParams,
      geoVerified: geoVerified,
      currentlyListed: car.currentlyListed,
      locationInfo: toLegacyLocationInfo(location),
      carVinNumber: car.carVinNumber,
      carMetadataURI: metadataURI,
      dimoTokenId: dimoTokenId
    });
  }

  function toLegacyFilterInfo(CarFilterInfo memory filterInfo) internal pure returns (CarGatewayTypes.FilterInfoDTO memory) {
    return CarGatewayTypes.FilterInfoDTO({
      maxCarPrice: filterInfo.maxCarPrice,
      minCarYearOfProduction: filterInfo.minCarYearOfProduction
    });
  }

  function toLegacyAllCarsInfo(AllCarsInfo memory allCars) internal pure returns (CarGatewayTypes.AllCarsDTO memory) {
    CarGatewayTypes.AdminCarDTO[] memory cars = new CarGatewayTypes.AdminCarDTO[](allCars.cars.length);

    for (uint256 i = 0; i < allCars.cars.length; i++) {
      cars[i] = CarGatewayTypes.AdminCarDTO({
        car: toLegacyCarDetails(allCars.cars[i].car),
        carMetadataURI: allCars.cars[i].carMetadataURI
      });
    }

    return CarGatewayTypes.AllCarsDTO({cars: cars, totalPageCount: allCars.totalPageCount});
  }

  function toLegacyCarDetails(CarDetails memory details) internal pure returns (CarGatewayTypes.GatewayCarDetails memory) {
    return CarGatewayTypes.GatewayCarDetails({
      carId: details.carId,
      hostName: details.hostName,
      hostPhotoUrl: details.hostPhotoUrl,
      host: details.host,
      brand: details.brand,
      model: details.model,
      yearOfProduction: details.yearOfProduction,
      pricePerDayInUsdCents: details.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: details.securityDepositPerTripInUsdCents,
      milesIncludedPerDay: details.milesIncludedPerDay,
      engineType: details.engineType,
      engineParams: details.engineParams,
      geoVerified: details.geoVerified,
      currentlyListed: details.currentlyListed,
      locationInfo: toLegacyLocationInfo(details.locationInfo),
      carVinNumber: details.carVinNumber,
      carMetadataURI: details.carMetadataURI,
      dimoTokenId: details.dimoTokenId
    });
  }

  function toLegacyAvailableCarInfo(AvailableCarInfo memory car) internal pure returns (CarGatewayTypes.AvailableCarDTO memory) {
    return CarGatewayTypes.AvailableCarDTO({
      carId: car.carId,
      brand: car.brand,
      model: car.model,
      yearOfProduction: car.yearOfProduction,
      pricePerDayInUsdCents: car.pricePerDayInUsdCents,
      pricePerDayWithDiscount: car.pricePerDayWithDiscount,
      tripDays: car.tripDays,
      totalPriceWithDiscount: car.totalPriceWithDiscount,
      securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
      engineType: car.engineType,
      milesIncludedPerDay: car.milesIncludedPerDay,
      host: car.host,
      hostName: car.hostName,
      hostPhotoUrl: car.hostPhotoUrl,
      metadataURI: car.metadataURI,
      underTwentyFiveMilesInUsdCents: car.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: car.aboveTwentyFiveMilesInUsdCents,
      pickUp: car.pickUp,
      dropOf: car.dropOf,
      insuranceIncluded: car.insuranceIncluded,
      locationInfo: toLegacyLocationInfo(car.locationInfo),
      insuranceInfo: toLegacyCarInsuranceInfo(car.insuranceInfo),
      fuelPrice: car.fuelPrice,
      carDiscounts: toLegacyBaseDiscount(car.carDiscounts),
      distance: car.distance,
      isGuestHasInsurance: car.isGuestHasInsurance,
      dimoTokenId: car.dimoTokenId,
      taxes: toLegacyTaxes(car.taxes),
      totalTax: car.totalTax,
      hostCurrency: toLegacyUserCurrencyInfo(car.hostCurrency)
    });
  }

  function toLegacyDeliveryData(
    LocationInfo memory location,
    DeliveryPrices memory prices,
    bool insuranceIncluded
  ) internal pure returns (CarGatewayTypes.DeliveryData memory) {
    return CarGatewayTypes.DeliveryData({
      locationInfo: toLegacyLocationInfo(location),
      underTwentyFiveMilesInUsdCents: prices.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: prices.aboveTwentyFiveMilesInUsdCents,
      insuranceIncluded: insuranceIncluded
    });
  }

  function toLegacyDeliveryPrices(DeliveryPrices memory prices) internal pure returns (CarGatewayTypes.GatewayDeliveryPrices memory) {
    return CarGatewayTypes.GatewayDeliveryPrices({
      underTwentyFiveMilesInUsdCents: prices.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: prices.aboveTwentyFiveMilesInUsdCents,
      initialized: prices.initialized
    });
  }

  function toLegacySearchCarsWithDistanceInfo(SearchCarsWithDistanceInfo memory result)
    internal
    pure
    returns (CarGatewayTypes.SearchCarsWithDistanceDTO memory)
  {
    CarGatewayTypes.SearchCarWithDistance[] memory cars = new CarGatewayTypes.SearchCarWithDistance[](result.cars.length);

    for (uint256 i = 0; i < result.cars.length; i++) {
      cars[i] = CarGatewayTypes.SearchCarWithDistance({
        car: toLegacySearchCarInfo(result.cars[i].car),
        distance: result.cars[i].distance
      });
    }

    return CarGatewayTypes.SearchCarsWithDistanceDTO({cars: cars, totalCarsSupply: result.totalCarsSupply});
  }

  function toLegacySearchCarInfo(SearchCarInfo memory car) internal pure returns (CarGatewayTypes.SearchCar memory) {
    return CarGatewayTypes.SearchCar({
      carId: car.carId,
      brand: car.brand,
      model: car.model,
      yearOfProduction: car.yearOfProduction,
      pricePerDayInUsdCents: car.pricePerDayInUsdCents,
      pricePerDayWithDiscount: car.pricePerDayWithDiscount,
      tripDays: car.tripDays,
      totalPriceWithDiscount: car.totalPriceWithDiscount,
      taxes: car.taxes,
      securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
      engineType: car.engineType,
      milesIncludedPerDay: car.milesIncludedPerDay,
      host: car.host,
      hostName: car.hostName,
      hostPhotoUrl: car.hostPhotoUrl,
      metadataURI: car.metadataURI,
      underTwentyFiveMilesInUsdCents: car.underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents: car.aboveTwentyFiveMilesInUsdCents,
      pickUp: car.pickUp,
      dropOf: car.dropOf,
      insuranceIncluded: car.insuranceIncluded,
      locationInfo: toLegacyLocationInfo(car.locationInfo),
      insuranceInfo: toLegacyCarInsuranceInfo(car.insuranceInfo),
      isGuestHasInsurance: car.isGuestHasInsurance,
      dimoTokenId: car.dimoTokenId,
      hostCurrency: toLegacyUserCurrencyInfo(car.hostCurrency),
      fuelPrice: car.fuelPrice,
      carDiscounts: toLegacyBaseDiscount(car.carDiscounts),
      taxesInfo: toLegacyTaxes(car.taxesInfo),
      engineParams: car.engineParams
    });
  }

  function toLegacyCarInsuranceInfo(CarInsuranceInfo memory insuranceInfo)
    internal
    pure
    returns (CarGatewayTypes.InsuranceCarInfo memory)
  {
    return CarGatewayTypes.InsuranceCarInfo({
      required: insuranceInfo.required,
      priceInUsdCents: insuranceInfo.priceInUsdCents
    });
  }

  function toLegacyBaseDiscount(RentalBaseDiscount memory discount) internal pure returns (RentalBaseDiscount memory) {
    return RentalBaseDiscount({
      threeDaysDiscount: discount.threeDaysDiscount,
      sevenDaysDiscount: discount.sevenDaysDiscount,
      thirtyDaysDiscount: discount.thirtyDaysDiscount,
      initialized: discount.initialized
    });
  }

  function toLegacyTaxes(RentalTaxValue[] memory taxes) internal pure returns (RentalTaxValue[] memory) {
    RentalTaxValue[] memory result = new RentalTaxValue[](taxes.length);

    for (uint256 i = 0; i < taxes.length; i++) {
      result[i] = RentalTaxValue({
        name: taxes[i].name,
        value: taxes[i].value,
        tType: RentalPricingTaxesType(uint8(taxes[i].tType))
      });
    }

    return result;
  }

  function toLegacyUserCurrencyInfo(UserCurrencyInfo memory currency)
    internal
    pure
    returns (UserCurrencyInfo memory)
  {
    return UserCurrencyInfo({
      currency: currency.currency,
      name: currency.name,
      initialized: currency.initialized
    });
  }

  function toCommonLocationInfo(LocationInfo memory location) internal pure returns (LocationInfo memory) {
    return LocationInfo({
      userAddress: location.userAddress,
      country: location.country,
      state: location.state,
      city: location.city,
      latitude: location.latitude,
      longitude: location.longitude,
      timeZoneId: location.timeZoneId
    });
  }

  function toLegacyLocationInfo(LocationInfo memory location) internal pure returns (LocationInfo memory) {
    return LocationInfo({
      userAddress: location.userAddress,
      country: location.country,
      state: location.state,
      city: location.city,
      latitude: location.latitude,
      longitude: location.longitude,
      timeZoneId: location.timeZoneId
    });
  }

  function toCommonSignedLocationInfo(SignedLocationInfo memory location)
    internal
    pure
    returns (SignedLocationInfo memory)
  {
    return SignedLocationInfo({locationInfo: toCommonLocationInfo(location.locationInfo), signature: location.signature});
  }

  function toCommonSearchCarParams(CarGatewayTypes.SearchCarParams memory params)
    internal
    pure
    returns (CarSearchParams memory)
  {
    return CarSearchParams({
      country: params.country,
      state: params.state,
      city: params.city,
      brand: params.brand,
      model: params.model,
      yearOfProductionFrom: params.yearOfProductionFrom,
      yearOfProductionTo: params.yearOfProductionTo,
      pricePerDayInUsdCentsFrom: params.pricePerDayInUsdCentsFrom,
      pricePerDayInUsdCentsTo: params.pricePerDayInUsdCentsTo,
      userLocation: toCommonLocationInfo(params.userLocation)
    });
  }

  function toCreateCarRequest(CarGatewayTypes.GatewayCreateCarRequest memory request) internal pure returns (CreateCarRequest memory) {
    return CreateCarRequest({
      asset: CreateAssetRequest({name: '', metadataURI: request.tokenUri}),
      carVinNumber: request.carVinNumber,
      brand: request.brand,
      model: request.model,
      yearOfProduction: request.yearOfProduction,
      pricePerDayInUsdCents: request.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: request.securityDepositPerTripInUsdCents,
      engineParams: request.engineParams,
      engineType: request.engineType,
      milesIncludedPerDay: request.milesIncludedPerDay,
      timeBufferBetweenTripsInSec: request.timeBufferBetweenTripsInSec,
      locationInfo: toCommonSignedLocationInfo(request.locationInfo),
      currentlyListed: request.currentlyListed
    });
  }

  function toUpdateCarRequest(
    CarGatewayTypes.UpdateCarInfoRequest memory request,
    string memory currentMetadataURI,
    LocationInfo memory location,
    bool updateLocation
  ) internal pure returns (UpdateCarRequest memory) {
    return UpdateCarRequest({
      asset: UpdateAssetRequest({
        name: '',
        metadataURI: bytes(request.tokenUri).length == 0 ? currentMetadataURI : request.tokenUri
      }),
      pricePerDayInUsdCents: request.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: request.securityDepositPerTripInUsdCents,
      engineParams: request.engineParams,
      milesIncludedPerDay: request.milesIncludedPerDay,
      timeBufferBetweenTripsInSec: request.timeBufferBetweenTripsInSec,
      currentlyListed: request.currentlyListed,
      engineType: request.engineType,
      location: toCommonLocationInfo(location),
      updateLocation: updateLocation
    });
  }
}


