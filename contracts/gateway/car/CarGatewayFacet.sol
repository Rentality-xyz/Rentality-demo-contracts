// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/car/CarMain.sol';
import '../../models/car/CarQuery.sol';
import '../../models/car/CarTypes.sol';
import '../../models/profile/UserProfileTypes.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../../rentality_old/Schemas.sol';
import '../../rentality_old/abstract/ARentalityContext.sol';

import './ICarGatewayFacet.sol';
import './CarGatewayFacetLib.sol';

interface ICarGatewayUserProfileMain {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ICarGatewayUserProfileQuery {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface ICarGatewayTripQuery {
  function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface ICarGatewayPricingService {
  function taxExist(Schemas.LocationInfo memory locationInfo) external view returns (uint256);
}

interface ICarGatewayInsuranceService {
  function saveInsuranceRequired(uint256 carId, uint256 priceInUsdCents, bool required, address user) external;
  function getInsuranceRequirement(uint256 objectId) external view returns (InsuranceRequirement memory);
}

interface ICarGatewayReferralService {
  function passReferralProgram(ReferralProgram program, bytes memory data, address user, address promoServiceAddress) external;
}

interface ICarGatewayDimoService {
  function saveDimoTokenId(uint256 dimoTokenId, uint256 carId, address user, bytes memory signature) external;
  function getDimoTokenId(uint256 carId) external view returns (uint256);
}

interface ICarGatewayGeoService {
  function getLocationInfo(bytes32 hash) external view returns (Schemas.LocationInfo memory);
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);
}

contract CarGatewayFacet is UUPSOwnable, ARentalityContext, ICarGatewayFacet {
  CarMain public carMain;
  CarQuery public carQuery;
  ICarGatewayTripQuery public tripQuery;
  ICarGatewayUserProfileMain public userProfileMain;
  ICarGatewayUserProfileQuery public userProfileQuery;
  ICarGatewayPricingService public pricingService;
  ICarGatewayInsuranceService public insuranceService;
  ICarGatewayReferralService public referralProgram;
  address public promoService;
  ICarGatewayDimoService public dimoService;
  ICarGatewayGeoService public geoService;

  function initialize(
    address carMainAddress,
    address carQueryAddress,
    address tripQueryAddress,
    address userProfileMainAddress,
    address userProfileQueryAddress,
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address referralProgramAddress,
    address promoServiceAddress,
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
      pricingServiceAddress,
      insuranceServiceAddress,
      referralProgramAddress,
      promoServiceAddress,
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
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address referralProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      tripQueryAddress,
      userProfileMainAddress,
      userProfileQueryAddress,
      pricingServiceAddress,
      insuranceServiceAddress,
      referralProgramAddress,
      promoServiceAddress,
      dimoServiceAddress,
      geoServiceAddress
    );
  }

  function addCar(Schemas.CreateCarRequest memory request) external returns (uint newTokenId) {
    address sender = _msgGatewaySender();

    referralProgram.passReferralProgram(ReferralProgram.AddCar, abi.encode(request.currentlyListed), sender, promoService);
    require(pricingService.taxExist(request.locationInfo.locationInfo) != 0, 'Tax not exist.');

    newTokenId = carMain.createCar(CarGatewayFacetLib.toCreateCarRequest(request), sender);
    dimoService.saveDimoTokenId(request.dimoTokenId, newTokenId, sender, request.signedDimoTokenId);
    insuranceService.saveInsuranceRequired(newTokenId, request.insurancePriceInUsdCents, request.insuranceRequired, sender);
  }

  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external {
    require(_isCarEditable(request.carId), 'Car is not available for update.');

    address sender = _msgGatewaySender();
    bool updateLocation = location.signature.length > 0;
    if (updateLocation) {
      carQuery.verifySignedLocationInfo(CarGatewayFacetLib.toCommonSignedLocationInfo(location));
    }

    bool wasListed = carQuery.getCar(request.carId).car.currentlyListed;
    referralProgram.passReferralProgram(
      ReferralProgram.UnlistedCar,
      abi.encode(wasListed, request.currentlyListed),
      sender,
      promoService
    );
    insuranceService.saveInsuranceRequired(request.carId, request.insurancePriceInUsdCents, request.insuranceRequired, sender);

    string memory currentMetadataURI = carQuery.getCar(request.carId).asset.metadataURI;
    carMain.updateCar(
      request.carId,
      CarGatewayFacetLib.toUpdateCarRequest(request, currentMetadataURI, location.locationInfo, updateLocation),
      sender
    );
  }

  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory) {
    CarInfo[] memory cars = carQuery.getAvailableCarsForUser(user);
    Schemas.CarInfo[] memory result = new Schemas.CarInfo[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = CarGatewayFacetLib.toLegacyCarInfo(cars[i].asset, cars[i].car);
    }

    return result;
  }

  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory) {
    address sender = _msgGatewaySender();
    CarInfo[] memory cars = carQuery.getCarsOfOwner(sender);
    Schemas.CarInfoDTO[] memory result = new Schemas.CarInfoDTO[](cars.length);

    for (uint256 i = 0; i < cars.length; i++) {
      result[i] = Schemas.CarInfoDTO({
        carInfo: CarGatewayFacetLib.toLegacyCarInfo(cars[i].asset, cars[i].car),
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
      carInfo: CarGatewayFacetLib.toLegacyCarInfo(car.asset, car.car),
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
      result[i] = CarGatewayFacetLib.toLegacyPublicHostCarDTO(cars[i]);
    }

    return result;
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
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address referralProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress,
    address geoServiceAddress
  ) internal {
    carMain = CarMain(carMainAddress);
    carQuery = CarQuery(carQueryAddress);
    tripQuery = ICarGatewayTripQuery(tripQueryAddress);
    userProfileMain = ICarGatewayUserProfileMain(userProfileMainAddress);
    userProfileQuery = ICarGatewayUserProfileQuery(userProfileQueryAddress);
    pricingService = ICarGatewayPricingService(pricingServiceAddress);
    insuranceService = ICarGatewayInsuranceService(insuranceServiceAddress);
    referralProgram = ICarGatewayReferralService(referralProgramAddress);
    promoService = promoServiceAddress;
    dimoService = ICarGatewayDimoService(dimoServiceAddress);
    geoService = ICarGatewayGeoService(geoServiceAddress);
  }
}
