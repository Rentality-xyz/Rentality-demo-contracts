// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../base/referral/ReferralTypes.sol';
import '../common/CommonTypes.sol';
import '../insurance/InsuranceTypes.sol';
import './TripLib.sol';
import './TripMain.sol';
import './TripTypes.sol';

interface ITripMainFacet1Access {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface ITripMainFacet1ReferralProgram {
  function passReferralProgram(
    ReferralProgram selector,
    bytes memory callbackArgs,
    address user,
    address promoServiceAddress
  ) external;
}

interface ITripMainFacet1NotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract TripMainFacet1 is UUPSOwnable {
  TripMain public tripMain;
  ITripMainFacet1Access public userAccess;
  address public userProfileMainAddress;
  address public carQueryAddress;
  address public carTaxAdapterAddress;
  address public pricingServiceAddress;
  address public paymentServiceAddress;
  address public currencyConverterAddress;
  address public insuranceServiceAddress;
  address public promoServiceAddress;
  ITripMainFacet1ReferralProgram public referralProgram;
  ITripMainFacet1NotificationService public notificationService;

  constructor() {
    _disableInitializers();
  }

  modifier onlyPlatform() {
    require(address(userAccess) != address(0) && userAccess.isRentalityPlatform(msg.sender), 'only Rentality platform');
    _;
  }

  function initialize(
    address tripMainAddress,
    address userAccessAddress,
    address userProfileMainAddress_,
    address carQueryAddress_,
    address carTaxAdapterAddress_,
    address pricingServiceAddress_,
    address paymentServiceAddress_,
    address currencyConverterAddress_,
    address insuranceServiceAddress_,
    address promoServiceAddress_,
    address referralProgramAddress_,
    address notificationServiceAddress_
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      tripMainAddress,
      userAccessAddress,
      userProfileMainAddress_,
      carQueryAddress_,
      carTaxAdapterAddress_,
      pricingServiceAddress_,
      paymentServiceAddress_,
      currencyConverterAddress_,
      insuranceServiceAddress_,
      promoServiceAddress_,
      referralProgramAddress_,
      notificationServiceAddress_
    );
  }

  function updateServiceAddresses(
    address tripMainAddress,
    address userAccessAddress,
    address userProfileMainAddress_,
    address carQueryAddress_,
    address carTaxAdapterAddress_,
    address pricingServiceAddress_,
    address paymentServiceAddress_,
    address currencyConverterAddress_,
    address insuranceServiceAddress_,
    address promoServiceAddress_,
    address referralProgramAddress_,
    address notificationServiceAddress_
  ) external onlyOwner {
    _setServiceAddresses(
      tripMainAddress,
      userAccessAddress,
      userProfileMainAddress_,
      carQueryAddress_,
      carTaxAdapterAddress_,
      pricingServiceAddress_,
      paymentServiceAddress_,
      currencyConverterAddress_,
      insuranceServiceAddress_,
      promoServiceAddress_,
      referralProgramAddress_,
      notificationServiceAddress_
    );
  }

  function createTripRequestWithDelivery(
    TripGatewayTypes.GatewayCreateTripRequestWithDelivery memory request,
    string memory promo,
    address sender
  ) external payable onlyPlatform {
    TripLib.createTripRequestWithDelivery(
      tripMain,
      userProfileMainAddress,
      carQueryAddress,
      carTaxAdapterAddress,
      pricingServiceAddress,
      paymentServiceAddress,
      currencyConverterAddress,
      insuranceServiceAddress,
      promoServiceAddress,
      request,
      promo,
      sender
    );
  }

  function calculatePaymentsWithDelivery(
    uint256 carId,
    uint64 daysOfTrip,
    address currency,
    LocationInfo memory pickUpLocation,
    LocationInfo memory returnLocation,
    string memory promo,
    address sender
  ) external view returns (TripGatewayTypes.GatewayCalculatePaymentsDTO memory) {
    return TripLib.calculatePaymentsWithDelivery(
      carQueryAddress,
      pricingServiceAddress,
      insuranceServiceAddress,
      promoServiceAddress,
      currencyConverterAddress,
      carTaxAdapterAddress,
      carId,
      daysOfTrip,
      currency,
      pickUpLocation,
      returnLocation,
      promo,
      sender
    );
  }

  function approveTripRequest(uint256 tripId, address sender) external onlyPlatform {
    TripLib.approveTripRequest(
      tripMain,
      carQueryAddress,
      pricingServiceAddress,
      paymentServiceAddress,
      currencyConverterAddress,
      insuranceServiceAddress,
      promoServiceAddress,
      address(notificationService),
      tripId,
      sender
    );
  }

  function rejectTripRequest(uint256 tripId, address sender) external onlyPlatform {
    TripLib.rejectTripRequest(
      tripMain,
      pricingServiceAddress,
      paymentServiceAddress,
      currencyConverterAddress,
      insuranceServiceAddress,
      promoServiceAddress,
      address(notificationService),
      tripId,
      sender
    );
  }

  function confirmCheckOut(uint256 tripId, address sender) external onlyPlatform {
    TripLib.confirmCheckOut(
      tripMain,
      userProfileMainAddress,
      pricingServiceAddress,
      paymentServiceAddress,
      currencyConverterAddress,
      insuranceServiceAddress,
      promoServiceAddress,
      address(notificationService),
      tripId,
      sender
    );
  }

  function finishTrip(uint256 tripId, address sender) external onlyPlatform {
    TripLib.finishTrip(
      tripMain,
      pricingServiceAddress,
      paymentServiceAddress,
      currencyConverterAddress,
      insuranceServiceAddress,
      promoServiceAddress,
      address(notificationService),
      tripId,
      sender
    );
  }

  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber,
    address sender
  ) external onlyPlatform {
    if (bytes(insuranceNumber).length > 0 || bytes(insuranceCompany).length > 0) {
      ITripLibWriteInsuranceService(insuranceServiceAddress).saveTripInsuranceInfo(
        tripId,
        SaveInsuranceRequest(insuranceCompany, insuranceNumber, '', '', InsuranceType.OneTime),
        sender
      );
    }

    tripMain.checkInByHost(tripId, panelParams, insuranceCompany, insuranceNumber, sender);
    Trip memory trip = tripMain.getTrip(tripId);
    _emitTripEvent(tripId, TripStatus.CheckedInByHost, trip.booking.provider, trip.booking.customer);
  }

  function checkInByGuest(uint256 tripId, uint64[] memory panelParams, address sender) external onlyPlatform {
    tripMain.checkInByGuest(tripId, panelParams, sender);
    Trip memory trip = tripMain.getTrip(tripId);
    _emitTripEvent(tripId, TripStatus.CheckedInByGuest, trip.booking.customer, trip.booking.provider);
  }

  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams, address sender) external onlyPlatform {
    Trip memory tripBefore = tripMain.getTrip(tripId);

    referralProgram.passReferralProgram(
      ReferralProgram.FinishTripAsGuest,
      abi.encode(tripBefore.booking.startDateTime, tripBefore.booking.endDateTime),
      sender,
      promoServiceAddress
    );

    tripMain.checkOutByGuest(tripId, panelParams, sender);
    Trip memory trip = tripMain.getTrip(tripId);
    _emitTripEvent(tripId, TripStatus.CheckedOutByGuest, trip.booking.customer, trip.booking.provider);
  }

  function checkOutByHost(uint256 tripId, uint64[] memory panelParams, address sender) external onlyPlatform {
    tripMain.checkOutByHost(tripId, panelParams, sender);
    Trip memory trip = tripMain.getTrip(tripId);
    _emitTripEvent(tripId, TripStatus.CheckedOutByHost, trip.booking.provider, trip.booking.customer);
  }

  function _setServiceAddresses(
    address tripMainAddress,
    address userAccessAddress,
    address userProfileMainAddress_,
    address carQueryAddress_,
    address carTaxAdapterAddress_,
    address pricingServiceAddress_,
    address paymentServiceAddress_,
    address currencyConverterAddress_,
    address insuranceServiceAddress_,
    address promoServiceAddress_,
    address referralProgramAddress_,
    address notificationServiceAddress_
  ) internal {
    tripMain = TripMain(tripMainAddress);
    userAccess = ITripMainFacet1Access(userAccessAddress);
    userProfileMainAddress = userProfileMainAddress_;
    carQueryAddress = carQueryAddress_;
    carTaxAdapterAddress = carTaxAdapterAddress_;
    pricingServiceAddress = pricingServiceAddress_;
    paymentServiceAddress = paymentServiceAddress_;
    currencyConverterAddress = currencyConverterAddress_;
    insuranceServiceAddress = insuranceServiceAddress_;
    promoServiceAddress = promoServiceAddress_;
    referralProgram = ITripMainFacet1ReferralProgram(referralProgramAddress_);
    notificationService = ITripMainFacet1NotificationService(notificationServiceAddress_);
  }

  function _emitTripEvent(uint256 tripId, TripStatus status, address from, address to) internal {
    if (address(notificationService) == address(0)) {
      return;
    }
    notificationService.emitEvent(EventType.Trip, tripId, uint8(status), from, to);
  }
}
