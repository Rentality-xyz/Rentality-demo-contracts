// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Schemas.sol';
import './RentalityUserService.sol';
import './RentalityCarToken.sol';
import './payments/RentalityInsurance.sol';
import './features/RentalityClaimService.sol';
import './payments/RentalityCurrencyConverter.sol';
import './libs/RentalityTripsQuery.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import './libs/RentalityTripsQuery.sol';
import {RentalityView} from './RentalityView.sol';
import {ARentalityContext} from './abstract/ARentalityContext.sol';

import {RentalityDimoService} from './features/RentalityDimoService.sol';
import {RentalityViewLib} from './libs/RentalityViewLib.sol';
import {RentalityAiDamageAnalyzeV2} from './features/RentalityAiDamageAnalyzeV2.sol';
import {RentalityHostInsurance} from './payments/RentalityHostInsurance.sol';

error FunctionNotFound();
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityTripsQuery doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityTripsView is UUPSUpgradeable, Initializable, ARentalityContext {
  RentalityContract private addresses;
  using RentalityTripsQuery for RentalityContract;

  RentalityInsurance private insuranceService;
  RentalityPromoService private promoService;
  RentalityDimoService private dimoService;
  address private trustedForwarderAddress;

  RentalityAiDamageAnalyzeV2 private aiDamageAnalyzeService;
  RentalityHostInsurance private hostInsurance;

  function updateServiceAddresses(
    RentalityContract memory contracts,
    address insurance,
    address promoServiceAddress,
    address dimoServiceAddress,
    address aiDamageAnalyzeServiceAddress
  ) public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = contracts;
    insuranceService = RentalityInsurance(insurance);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);
    aiDamageAnalyzeService = RentalityAiDamageAnalyzeV2(aiDamageAnalyzeServiceAddress);
  }
  fallback(bytes calldata) external returns (bytes memory) {
    revert FunctionNotFound();
  }

  /// @notice Get contact information for a specific trip on the Rentality platform.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  //// Refactoring for getTripContactInfo with RentalityContract
  function getTripContactInfo(
    uint256 tripId
  ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    return
      RentalityTripsQuery.getTripContactInfo(tripId, address(addresses.tripService), address(addresses.userService));
  }

  /// @notice Retrieves information about a trip by ID.
  /// @param tripId The ID of the trip.
  /// @return Trip information.
  function getTrip(uint256 tripId) public view returns (Schemas.TripDTO memory) {
    Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
    return
      RentalityTripsQuery.getTripDTO(
        addresses,
        insuranceService,
        tripId,
        promoService,
        dimoService,
        _msgGatewaySender(),
        trip
      );
  }

  /// @notice Retrieves information about trips where the caller is the guest.
  /// @return An array of trip information.
  function getTripsAs(bool host) public view returns (Schemas.TripDTO[] memory) {
    return
      RentalityTripsQuery.getTripsAs(addresses, insuranceService, _msgGatewaySender(), host, promoService, dimoService);
  }

  /// @notice Calculates the KYC commission in a specific currency based on the current exchange rate.
  /// @dev This function uses the currency converter service to calculate the commission in the specified currency.
  /// @param currency The address of the currency in which the commission should be calculated.
  /// @return The KYC commission amount in the specified currency.
  function calculateKycCommission(address currency) public view returns (uint) {
    (uint result, , ) = addresses.currencyConverterService.getFromUsdCentsLatest(
      currency,
      addresses.userService.getKycCommission()
    );

    return result;
  }

  function updateViewService(RentalityView viewService) public {
    require(addresses.userService.isAdmin(tx.origin), 'Only admin');
    addresses.viewService = viewService;
  }

  function checkPromo(
    string memory promo,
    uint startDateTime,
    uint endDateTime
  ) public view returns (Schemas.CheckPromoDTO memory) {
    return promoService.checkPromo(promo, startDateTime, endDateTime);
  }

  function getUniqCarsBrand() public view returns (string[] memory brandsArray) {
    return RentalityViewLib.getUniqCarsBrand(addresses.carService);
  }
  function getUniqModelsByBrand(string memory brand) public view returns (string[] memory modelsArray) {
    return RentalityViewLib.getUniqModelsByBrand(addresses.carService, brand);
  }

  function getAvaibleCurrencies() public view returns (Schemas.Currency[] memory) {
    return addresses.currencyConverterService.getAllCurrencies();
  }
  function getFilterInfo(uint64 duration) public view returns (Schemas.FilterInfoDTO memory) {
    uint64 maxCarPrice = 0;
    RentalityCarToken carService = addresses.carService;
    uint minCarYearOfProduction = carService.getCarInfoById(1).yearOfProduction;

    for (uint i = 2; i <= carService.totalSupply(); i++) {
      Schemas.CarInfo memory car = carService.getCarInfoById(i);

      uint64 sumWithDiscount = addresses.paymentService.calculateSumWithDiscount(
        carService.ownerOf(i),
        duration,
        car.pricePerDayInUsdCents
      );
      if (sumWithDiscount > maxCarPrice) maxCarPrice = sumWithDiscount;
      if (car.yearOfProduction < minCarYearOfProduction) minCarYearOfProduction = car.yearOfProduction;
    }
    return Schemas.FilterInfoDTO(maxCarPrice, minCarYearOfProduction);
  }

  function getAiDamageAnalyzeCaseRequest(
    uint tripId,
    Schemas.CaseType caseType
  ) public view returns (Schemas.AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest) {
    Schemas.CarInfo memory car = addresses.carService.getCarInfoById(addresses.tripService.getTrip(tripId).carId);
    Schemas.FullKYCInfoDTO memory kyc = addresses.userService.getMyFullKYCInfo(_msgGatewaySender());

    return
      Schemas.AiDamageAnalyzeCaseRequestDTO(
        aiDamageAnalyzeService.getLatestCaseId(),
        kyc.additionalKYC.email,
        kyc.kyc.surname,
        aiDamageAnalyzeService.getCaseTokenForTrip(tripId, caseType),
        car.carVinNumber
      );
  }
  function getDimoVehicles() public view returns (uint[] memory) {
    return dimoService.getDimoVehicles();
  }

  function getUserCurrency(address user) public view returns (Schemas.UserCurrencyDTO memory userCurrency) {
    return addresses.currencyConverterService.getUserCurrency(user);
  }

  /// @notice Retrieves the metadata URI of a car by its ID.
  /// @param carId The ID of the car.
  /// @return The metadata URI of the car.
  function getCarMetadataURI(uint256 carId) public view returns (string memory) {
    return addresses.carService.tokenURI(carId);
  }

  function getTotalCarsAmount() public view returns (uint) {
    return addresses.carService.totalSupply();
  }

  function getGuestInsurance(address guest) public view returns (Schemas.InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(guest);
  }
  function getTaxesInfoById(uint taxId) public view returns (Schemas.TaxesInfoDTO memory) {
    return addresses.paymentService.getTaxesInfoById(taxId);
  }

  function getPlatformInfo() public view returns(Schemas.PlatformInfoDTO memory) {
   return Schemas.PlatformInfoDTO(
      addresses.userService.getPlatformUsersCount(),
      addresses.tripService.totalTripCount(),
      addresses.carService.totalSupply()
    );
  }
  function trustedForwarder() internal view override returns (address) {
    return trustedForwarderAddress;
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return forwarder == trustedForwarderAddress;
  }
  function setTrustedForwarder(address forwarder) public {
    require(addresses.userService.isAdmin(tx.origin), 'Only for Admin.');
    trustedForwarderAddress = forwarder;
  }
  function getHostInsuranceClaims() public view returns(Schemas.FullClaimInfo[] memory claimInfos) {
    uint[] memory claimIds = hostInsurance.getInsuranceClaims();
    claimInfos = new Schemas.FullClaimInfo[](claimIds.length);
    uint counter = 0;
    for (uint i = 0; i < claimIds.length; i++) {
      Schemas.ClaimV2 memory claim = addresses.claimService.getClaim(claimIds[i]);
      Schemas.Trip memory trip = addresses.tripService.getTrip(claim.tripId);

        claimInfos[counter++] = Schemas.FullClaimInfo(
          claim,
          trip.host,
          trip.guest,
          addresses.userService.getKYCInfo(trip.guest).mobilePhoneNumber,
          addresses.userService.getKYCInfo(trip.host).mobilePhoneNumber,
          addresses.carService.getCarInfoById(trip.carId),
          RentalityQuery._getClaimValueInCurrency(
          trip.paymentInfo.currencyType,
          claim.amountInUsdCents,
          claim,
          addresses.claimService,
          addresses.currencyConverterService
        ),
          IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarTimeZoneId(
            addresses.carService.getCarInfoById(trip.carId).locationHash
          ),
          addresses.claimService.getClaimTypeInfo(claim.claimType),
          addresses.currencyConverterService.getUserCurrency(trip.host)
        );
      }
    }


    function getHostInsuranceRule(address host) public view returns(Schemas.HostInsuranceRuleDTO memory insuranceRules) {
    return hostInsurance.getHostInsuranceRule(host);
    }
    function getAllInsuranceRules() public view returns(Schemas.HostInsuranceRuleDTO[] memory insuranceRules) { 
      return hostInsurance.getAllInsuranceRules();
    }
    function setHostInsuranceAddress(address _hostInsurance) public {
    require(addresses.userService.isAdmin(tx.origin), 'Only for Admin.');
    hostInsurance = RentalityHostInsurance(payable(_hostInsurance));
  }

  function initialize(
    address carServiceAddress,
    address currencyConverterServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address paymentServiceAddress,
    address claimServiceAddress,
    address carDeliveryAddress,
    address insuranceAddress,
    address promoServiceAddress,
    address dimoServiceAddress,
    address aiDamageAnalyzeServiceAddress,
    address _hostInsurance
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(address(0)),
      RentalityPaymentService(payable(paymentServiceAddress)),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(address(0)),
      RentalityCarDelivery(carDeliveryAddress),
      RentalityView(address(0))
    );
    insuranceService = RentalityInsurance(insuranceAddress);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);
    aiDamageAnalyzeService = RentalityAiDamageAnalyzeV2(aiDamageAnalyzeServiceAddress);
    hostInsurance = RentalityHostInsurance(payable(_hostInsurance));
  }

  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(addresses.userService.isAdmin(msg.sender), 'Only for Admin.');
  }
}
