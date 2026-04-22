pragma solidity ^0.8.20;

import '../../models/base/asset/AssetTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../../models/car/CarTypes.sol';
import '../../models/common/Schemas.sol';

library CarMapper {
  function toLegacyCarInfo(Asset memory asset, CarData memory car) internal pure returns (Schemas.CarInfo memory) {
    return Schemas.CarInfo({
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

  function toLegacyPublicHostCarDTO(PublicHostCarInfo memory car) internal pure returns (Schemas.PublicHostCarDTO memory) {
    return Schemas.PublicHostCarDTO({
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

  function toCommonLocationInfo(Schemas.LocationInfo memory location) internal pure returns (LocationInfo memory) {
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

  function toCommonSignedLocationInfo(Schemas.SignedLocationInfo memory location)
    internal
    pure
    returns (SignedLocationInfo memory)
  {
    return SignedLocationInfo({locationInfo: toCommonLocationInfo(location.locationInfo), signature: location.signature});
  }

  function toCommonSearchCarParams(Schemas.SearchCarParams memory params)
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

  function toCreateCarRequest(Schemas.CreateCarRequest memory request) internal pure returns (CreateCarRequest memory) {
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
    Schemas.UpdateCarInfoRequest memory request,
    string memory currentMetadataURI,
    Schemas.LocationInfo memory location,
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


