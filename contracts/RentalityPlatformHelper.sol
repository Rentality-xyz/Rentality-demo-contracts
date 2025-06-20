/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './features/RentalityClaimService.sol';
import './abstract/IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './payments/RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './payments/RentalityPaymentService.sol';
import './Schemas.sol';
import './RentalityAdminGateway.sol';
import {RentalityCarDelivery} from './features/RentalityCarDelivery.sol';
import {UUPSOwnable} from './proxy/UUPSOwnable.sol';
import {RentalityUtils} from './libs/RentalityUtils.sol';
import {RentalityDimoService} from './features/RentalityDimoService.sol';
import './RentalityView.sol';
import {RentalityReferralProgram} from './features/refferalProgram/RentalityReferralProgram.sol';
import './payments/RentalityInsurance.sol';
import {RentalityPromoService} from './features/RentalityPromo.sol';
import {ARentalityContext} from './abstract/ARentalityContext.sol';
import {RentalityNotificationService} from './features/RentalityNotificationService.sol';
import {RentalityHostInsurance} from './payments/RentalityHostInsurance.sol';


/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityPlatformHelper is UUPSOwnable, ARentalityContext {
  RentalityContract private addresses;

  RentalityInsurance private insuranceService;
  RentalityDimoService private dimoService;

  RentalityReferralProgram private refferalProgram;
  RentalityPromoService private promoService;
  address private trustedForwarderAddress;
  RentalityNotificationService private notificationService;
  RentalityHostInsurance private hostInsurance;

  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) public {
    address user = _msgGatewaySender();
    insuranceService.saveGuestInsurance(insuranceInfo, user);
    notificationService.emitEvent(Schemas.EventType.Insurance, 0, uint8(insuranceInfo.insuranceType), user, user);
  }

  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addUserDiscount(Schemas.BaseDiscount memory data) public {
    address user = _msgGatewaySender();
    addresses.paymentService.addBaseDiscount(user, data);
    notificationService.emitEvent(Schemas.EventType.Discount, 0, uint8(Schemas.EventCreator.User), user, user);
  }

  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) public {
    address sender = _msgGatewaySender();
    addresses.deliveryService.setUserDeliveryPrices(
      underTwentyFiveMilesInUsdCents,
      aboveTwentyFiveMilesInUsdCents,
      sender
    );
     notificationService.emitEvent(Schemas.EventType.Delivery, 0, uint8(Schemas.EventCreator.User), sender, sender);
  }
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) public {
    dimoService.saveButch(dimoTokenIds, carIds, _msgGatewaySender());
  }
  function useKycCommission(address user) public {
    addresses.userService.useKycCommission(user);
  }

  function addUserCurrency(address currency) public {
    address sender = _msgGatewaySender();
    addresses.currencyConverterService.addUserCurrency(_msgGatewaySender(), currency);
    notificationService.emitEvent(Schemas.EventType.Currency, 0, uint8(Schemas.EventCreator.User), sender, sender);
  }

  function payKycCommission(address currency) public payable {
    (uint valueToPay, , ) = addresses.currencyConverterService.getFromUsdCentsLatest(
      currency,
      addresses.userService.getKycCommission()
    );

    addresses.paymentService.payKycCommission{value: msg.value}(valueToPay, currency, _msgGatewaySender());
  }

  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) public {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    address sender = _msgGatewaySender();
    require(trip.host == sender || trip.guest == sender, 'For trip host or guest');
    insuranceService.saveTripInsuranceInfo(tripId, insuranceInfo, sender);
    notificationService.emitEvent(Schemas.EventType.SaveTripInsurance, tripId, 0, sender, sender);
  }

  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) public {
    require(RentalityUtils.isCarEditable(addresses, request.carId), 'Car is not available for update.');

    if (location.signature.length > 0) addresses.carService.verifySignedLocationInfo(location);
    refferalProgram.passReferralProgram(
      Schemas.RefferalProgram.UnlistedCar,
      abi.encode(addresses.carService.getCarInfoById(request.carId).currentlyListed, request.currentlyListed),
      _msgGatewaySender(),
      promoService
    );
    insuranceService.saveInsuranceRequired(
      request.carId,
      request.insurancePriceInUsdCents,
      request.insuranceRequired,
      _msgGatewaySender()
    );
    return
      addresses.carService.updateCarInfo(
        request,
        location.locationInfo,
        location.signature.length > 0,
        _msgGatewaySender()
      );
  }

  function setPhoneNumber(address user, string memory phone, bool isVerified) public {
    addresses.userService.setPhoneNumber(user, phone, isVerified);
  }

   function setEmail(address user, string memory email, bool isVerified) public {
     addresses.userService.setEmail(user, email, isVerified);
   }
    function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) public {
    refferalProgram.passReferralProgram(Schemas.RefferalProgram.PassCivic, bytes(''), user, promoService);
    addresses.userService.setCivicKYCInfo(user, civicKycInfo);
  }
    /// @notice Sets Know Your Customer (KYC) information for the caller.
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    bytes4 hash
  ) public {
    address sender = _msgGatewaySender();
    refferalProgram.generateReferralHash(sender);
    bool isGuest = addresses.userService.isGuest(sender);
    refferalProgram.saveRefferalHash(hash, isGuest, sender);
    refferalProgram.passReferralProgram(Schemas.RefferalProgram.SetKYC, bytes(''), sender, promoService);
    addresses.userService.setKYCInfo(nickName, mobilePhoneNumber, profilePhoto, email, TCSignature, sender);
    notificationService.emitEvent(Schemas.EventType.User, 0, 0, sender, sender);
  }


  function trustedForwarder() internal view override returns (address) {
    return trustedForwarderAddress;
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return forwarder == trustedForwarderAddress;
  }
  function setTrustedForwarder(address forwarder) public onlyOwner {
    trustedForwarderAddress = forwarder;
  }

   function setNotificationService(address notificationServiceAddress) public {
    require(addresses.userService.isAdmin(tx.origin), 'Only admin.');
    notificationService = RentalityNotificationService(notificationServiceAddress);
  }

    function setHostInsurance(uint insuranceId) public {
    address sender = _msgGatewaySender();
    hostInsurance.setHostInsurance(insuranceId, sender);
  }

  function setHostInsuranceAddress(address _hostInsurance) public onlyOwner {
    hostInsurance = RentalityHostInsurance(payable(_hostInsurance));
  }
  /// @notice Constructor to initialize the RentalityPlatform with service contract addresses.
  /// @param carServiceAddress The address of the RentalityCarToken contract.
  /// @param currencyConverterServiceAddress The address of the RentalityCurrencyConverter contract.
  /// @param tripServiceAddress The address of the RentalityTripService contract.
  /// @param userServiceAddress The address of the RentalityUserService contract.
  /// @param paymentServiceAddress The address of the RentalityPaymentService contract.
  function initialize(
    address carServiceAddress,
    address currencyConverterServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address paymentServiceAddress,
    address claimServiceAddress,
    address carDeliveryAddress,
    address viewService,
    address insuranceServiceAddress,
    address refferalProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress,
    address notificationServiceAddress,
    address _hostInsurance
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(address(this)),
      RentalityPaymentService(payable(paymentServiceAddress)),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(address(0)),
      RentalityCarDelivery(carDeliveryAddress),
      RentalityView(viewService)
    );
    insuranceService = RentalityInsurance(insuranceServiceAddress);
    refferalProgram = RentalityReferralProgram(refferalProgramAddress);
    promoService = RentalityPromoService(promoServiceAddress);

    dimoService = RentalityDimoService(dimoServiceAddress);
    notificationService = RentalityNotificationService(notificationServiceAddress);
    hostInsurance = RentalityHostInsurance(payable(_hostInsurance));
    __Ownable_init();
  }
}
