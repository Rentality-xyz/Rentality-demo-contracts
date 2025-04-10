  // SPDX-License-Identifier: MIT
  pragma solidity ^0.8.0;


  import {Schemas} from "../../../Schemas.sol";
import {TripServiceStorage} from "../../libraries/TripServiceStorage.sol";
import {CarTokenStorage} from "../../libraries/CarTokenStorage.sol";
import {TaxesStorage} from "../../libraries/TaxesStorage.sol";
import {CurrencyConverterStorage} from "../../libraries/CurrencyConverterStorage.sol";
import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {RentalityTripsHelperDiamond} from "../../libraries/getters/RentalityTripsHelperDiamond.sol";
import {RentalityUtilsDiamond} from "../../libraries/getters/RentalityUtilsDiamond.sol";
import {InsuranceServiceStorage} from "../../libraries/InsuranceServiceStorage.sol";
import {PaymentsStorage} from "../../libraries/PaymentsStorage.sol";
import {RefferalServiceStorage} from "../../libraries/RefferalServiceStorage.sol";
import {GeoServiceStorage} from "../../libraries/GeoServiceStorage.sol";
import {ARentalityEventManager} from "../abstract/ARentalityEventManager.sol";

struct CreateTripRequestParams {
    Schemas.CreateTripRequestWithDelivery request;
    uint64 pickUp;
    uint64 dropOf;
    bytes32 pickUpHash;
    bytes32 returnHash;
    string promo;
}

contract RentalityTripServiceFacet2 is ARentalityEventManager {

    function createTripRequestWithDelivery(
    Schemas.CreateTripRequestWithDelivery memory request,
    string memory promo
) public payable {
    (uint64 pickUp, uint64 dropOf) = RentalityTripsHelperDiamond.calculateDelivery(request);
    bytes32 pickUpHash = GeoServiceStorage.createSignedLocationInfo(
        request.pickUpInfo
    );
    bytes32 returnHash = GeoServiceStorage.createSignedLocationInfo(
        request.returnInfo
    );
    // Create the struct and pass it
    CreateTripRequestParams memory params = CreateTripRequestParams({
        request: request,
        pickUp: pickUp,
        dropOf: dropOf,
        pickUpHash: pickUpHash,
        returnHash: returnHash,
        promo: promo
});
    createNewTrip(params);
}


  function createNewTrip(
    CreateTripRequestParams memory params
  ) private returns (uint) {

    address host = CarTokenStorage.ownerOf(params.request.carId);

    address currencyType =  CurrencyConverterStorage.getUserCurrency(host).currency;
    RentalityTripsHelperDiamond.validateTripRequest(
        currencyType,
        params.request.carId,
        params.request.startDateTime,
        params.request.endDateTime,
        msg.sender
    );

    uint insurance = InsuranceServiceStorage.calculateInsuranceForTrip(
        params.request.carId,
        params.request.startDateTime,
        params.request.endDateTime,
        msg.sender
    );
    uint64 priceWithDiscount = PaymentsStorage.calculateSumWithDiscount(
        CarTokenStorage.ownerOf(params.request.carId),
        RentalityUtilsDiamond.getCeilDays(params.request.startDateTime, params.request.endDateTime),
        CarTokenStorage.getCarInfoById(params.request.carId).pricePerDayInUsdCents
    );
    uint tripId = TripServiceStorage.totalTripCount() + 1;

    (
        Schemas.PaymentInfo memory paymentInfo,
        uint valueSumInCurrency,
        uint hostEarningsInCurrency,
        uint hostEarnings,
        bool usePromo
    ) = RentalityTripsHelperDiamond.createPaymentInfo(
        params.request.carId,
        currencyType,
        params.pickUp,
        params.dropOf,
        // promoService,
        params.promo,
        msg.sender,
        insurance,
        TaxesStorage.calculateAndSaveTaxes(
            TaxesStorage.defineTaxesType(params.request.carId),
            RentalityUtilsDiamond.getCeilDays(params.request.startDateTime, params.request.endDateTime),
            priceWithDiscount + params.pickUp + params.dropOf,
            tripId
        ),
        RentalityUtilsDiamond.getCeilDays(params.request.startDateTime, params.request.endDateTime),
        priceWithDiscount
    );

    PaymentsStorage.payCreateTrip(
        currencyType,
        valueSumInCurrency,
        msg.sender,
        params.request.carId
    );
    TripServiceStorage.incrementTripIdCounter();

    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(params.request.carId);
    uint64 milesIncludedPerDay = carInfo.milesIncludedPerDay;
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    if (milesIncludedPerDay == 0) {
      milesIncludedPerDay = 2 ** 32 - 1;
    }

    s.carIdToActiveTrips[params.request.carId].push(tripId);
    s.carIdToTrips[params.request.carId].push(tripId);
    s.userToTrips[host].push(tripId);
    s.userToActiveTrips[host].push(tripId);
    s.userToTrips[msg.sender].push(tripId);
    s.userToActiveTrips[msg.sender].push(tripId);

    paymentInfo.tripId = tripId;
    CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();

    uint256 panelParamsAmount = carStorage.enginesService.getPanelParamsAmount(carInfo.engineType);

    s.idToTripInfo[tripId] = Schemas.Trip(
      tripId,
      params.request.carId,
      Schemas.TripStatus.Created,
      msg.sender,
      host,
      UserServiceStorage.getKYCInfo(msg.sender).name,
      UserServiceStorage.getKYCInfo(host).name,
      carInfo.pricePerDayInUsdCents,
      params.request.startDateTime,
      params.request.endDateTime,
      carInfo.engineType,
      milesIncludedPerDay,
      carStorage.enginesService.getFuelPriceFromEngineParams(carInfo.engineType, carInfo.engineParams),
      paymentInfo,
      block.timestamp,
      0,
      0,
      '',
      '',
      address(0),
      0,
      new uint64[](panelParamsAmount),
      0,
      address(0),
      0,
      address(0),
      new uint64[](panelParamsAmount),
      0,
      Schemas.TransactionInfo(0, 0, 0, 0, Schemas.TripStatus.Created),
      0,
      params.pickUpHash == bytes32('') ? carInfo.locationHash : params.pickUpHash,
      params.returnHash == bytes32('') ? carInfo.locationHash : params.returnHash
    );
    s.tripIdToEthSumInTripCreation[tripId] = msg.value;

    emitEvent(Schemas.EventType.Trip, tripId, uint8(Schemas.TripStatus.Created), msg.sender, host);

    InsuranceServiceStorage.saveGuestinsurancePayment(tripId, params.request.carId, insurance, msg.sender);
    return tripId;
  }

    function getActiveTrips(uint carId) public view returns (uint[] memory) {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    return s.carIdToActiveTrips[carId];
  }
  function getCarTrips(uint carId) public view returns (uint[] memory) {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    return s.carIdToTrips[carId];
  }
  function getActiveTripsByUser(address host) public view returns (uint[] memory) {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    return s.userToActiveTrips[host];
  }
  function getTripsByUser(address host) public view returns (uint[] memory) {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    return s.userToTrips[host];
  }


  
  }