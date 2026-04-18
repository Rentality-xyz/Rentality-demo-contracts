// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/car/CarMain.sol';
import '../../models/car/CarQuery.sol';
import '../../models/base/referral/ReferralTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../../rentality_old/Schemas.sol';
import '../../rentality_old/abstract/ARentalityContext.sol';

import './ICarGatewayFacet.sol';
import './CarGatewayFacetLib.sol';

interface ICarGatewayUserProfileMain {
  function isRentalityPlatform(address user) external view returns (bool);
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
}

interface ICarGatewayReferralService {
  function passReferralProgram(ReferralProgram program, bytes memory data, address user, address promoServiceAddress) external;
}

interface ICarGatewayDimoService {
  function saveDimoTokenId(uint256 dimoTokenId, uint256 carId, address user, bytes memory signature) external;
}

contract CarGatewayFacet is UUPSOwnable, ARentalityContext, ICarGatewayFacet {
  CarMain public carMain;
  CarQuery public carQuery;
  ICarGatewayTripQuery public tripQuery;
  ICarGatewayUserProfileMain public userProfileMain;
  ICarGatewayPricingService public pricingService;
  ICarGatewayInsuranceService public insuranceService;
  ICarGatewayReferralService public referralProgram;
  address public promoService;
  ICarGatewayDimoService public dimoService;

  function initialize(
    address carMainAddress,
    address carQueryAddress,
    address tripQueryAddress,
    address userProfileMainAddress,
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address referralProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      tripQueryAddress,
      userProfileMainAddress,
      pricingServiceAddress,
      insuranceServiceAddress,
      referralProgramAddress,
      promoServiceAddress,
      dimoServiceAddress
    );
  }

  function updateServiceAddresses(
    address carMainAddress,
    address carQueryAddress,
    address tripQueryAddress,
    address userProfileMainAddress,
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address referralProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      carMainAddress,
      carQueryAddress,
      tripQueryAddress,
      userProfileMainAddress,
      pricingServiceAddress,
      insuranceServiceAddress,
      referralProgramAddress,
      promoServiceAddress,
      dimoServiceAddress
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

  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external {
    carMain.setUserDeliveryPrices(
      underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents,
      _msgGatewaySender()
    );
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
    address pricingServiceAddress,
    address insuranceServiceAddress,
    address referralProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress
  ) internal {
    carMain = CarMain(carMainAddress);
    carQuery = CarQuery(carQueryAddress);
    tripQuery = ICarGatewayTripQuery(tripQueryAddress);
    userProfileMain = ICarGatewayUserProfileMain(userProfileMainAddress);
    pricingService = ICarGatewayPricingService(pricingServiceAddress);
    insuranceService = ICarGatewayInsuranceService(insuranceServiceAddress);
    referralProgram = ICarGatewayReferralService(referralProgramAddress);
    promoService = promoServiceAddress;
    dimoService = ICarGatewayDimoService(dimoServiceAddress);
  }
}
