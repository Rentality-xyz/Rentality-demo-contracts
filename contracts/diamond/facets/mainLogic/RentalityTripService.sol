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


contract RentalityTripServiceFacet is ARentalityEventManager {


  /// @notice Approves a trip by changing its status to Approved.
  ///  Requirements:
  ///   - Only the host of the trip can approve it.
  ///   - The trip must be in status Created.
  ///  @param tripId The ID of the trip to be approved.
  function approveTripRequest(uint256 tripId) public {
    Schemas.Trip memory trip = TripServiceStorage.getTrip(tripId);
    Schemas.Trip[] memory intersectedTrips = RentalityTripsHelperDiamond.getTripsForCarThatIntersect(
      trip.carId,
      trip.startDateTime,
      trip.endDateTime
    );
    if (intersectedTrips.length > 0) {
      for (uint256 i = 0; i < intersectedTrips.length; i++) {
        if (intersectedTrips[i].status == Schemas.TripStatus.Created && intersectedTrips[i].tripId != tripId) {
          rejectTripRequest(intersectedTrips[i].tripId);
        }
      }
    }
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    address host = trip.host;
    require(host == msg.sender, 'Only host of the trip can approve it');
    require(trip.status == Schemas.TripStatus.Created, 'The trip is not in status Created');

    s.idToTripInfo[tripId].status = Schemas.TripStatus.Approved;
    s.idToTripInfo[tripId].approvedDateTime = block.timestamp;

    emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.Approved),
      host,
      s.idToTripInfo[tripId].guest
    );
  }

//   /// @notice Reject a trip by changing its status to Canceled.
//   ///  Requirements:
//   ///   - Only the host or guest of the trip can reject it.
//   ///   - The trip must be in status Created, Approved, or CheckedInByHost.
//   ///  @param tripId The ID of the trip to be Rejected
  function rejectTripRequest(
    uint256 tripId
  ) public {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    Schemas.Trip memory trip = s.idToTripInfo[tripId];

    uint insurance = InsuranceServiceStorage.getInsurancePriceByTrip(tripId);
    uint64 totalTax = TaxesStorage.getTotalTripTax(tripId);
    uint valueToReturnInUsdCents = CurrencyConverterStorage.calculateTripReject(trip.paymentInfo, insurance, totalTax);

    Schemas.TripStatus status = trip.status;

    address host = trip.host;
    address guest = trip.guest;
    bool controversialSituation = UserServiceStorage.isAdmin(msg.sender) && status == Schemas.TripStatus.CheckedOutByHost;

    require(
      trip.host == msg.sender || trip.guest == msg.sender || controversialSituation,
      'Only host or guest of the trip can reject it'
    );

    require(
      trip.status == Schemas.TripStatus.Created ||
        trip.status == Schemas.TripStatus.Approved ||
        trip.status == Schemas.TripStatus.CheckedInByHost ||
        controversialSituation,
      'The trip is not in status Created, Approved'
    );
    _removeActiveTrip(trip.carId, tripId);
    _removeActiveTripFromUser(tripId, trip.host);
    _removeActiveTripFromUser(tripId, trip.guest);
    s.idToTripInfo[tripId].status = Schemas.TripStatus.Canceled;
    s.idToTripInfo[tripId].rejectedDateTime = block.timestamp;
    s.idToTripInfo[tripId].rejectedBy = msg.sender;

    saveTransactionInfo(tripId, 0, status, valueToReturnInUsdCents, 0);


       /* you should not recalculate the value with convertor,
     for return during rejection,
     but instead, use: 'addresses.tripService.tripIdToEthSumInTripCreation(tripId)'*/
 
    PaymentsStorage.payRejectTrip(trip, s.tripIdToEthSumInTripCreation[tripId]);


    emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.Canceled),
      msg.sender,
      msg.sender == guest ? guest : host
    );
  }
//   /// @notice Allows the host to perform a check-in for a specific trip.
//   /// This action typically occurs at the start of the trip and records key information
//   /// such as fuel level, odometer reading, insurance details, and any other relevant data.
//   /// @param tripId The unique identifier for the trip being checked in.
//   /// @param panelParams An array of numeric parameters representing important vehicle details.
//   ///   - panelParams[0]: Fuel level (e.g., as a percentage)
//   ///   - panelParams[1]: Odometer reading (e.g., in kilometers or miles)
//   ///   - Additional parameters can be added based on the engine and vehicle characteristics.
//   /// @param insuranceCompany The name of the insurance company covering the vehicle.
//   /// @param insuranceNumber The insurance policy number.
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) public {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
     if (bytes(insuranceNumber).length > 0 || bytes(insuranceCompany).length > 0)
        InsuranceServiceStorage.saveTripInsuranceInfo(
        tripId,
        Schemas.SaveInsuranceRequest(insuranceCompany, insuranceNumber, '', '', Schemas.InsuranceType.OneTime),
        msg.sender
      );
    Schemas.Trip memory trip = s.idToTripInfo[tripId];
    require(trip.host == msg.sender, 'For host only');

    uint[] memory totalTrips = s.carIdToActiveTrips[trip.carId];
    for (uint i = 0; i < totalTrips.length; i++) {
      Schemas.Trip memory check_trip = s.idToTripInfo[totalTrips[i]];

      if (
        check_trip.carId == trip.carId &&
        (check_trip.status == Schemas.TripStatus.CheckedInByGuest ||
          check_trip.status == Schemas.TripStatus.CheckedInByHost ||
          check_trip.status == Schemas.TripStatus.CheckedOutByGuest)
      ) {
        revert('Car on the trip.');
      }
      else if(check_trip.status == Schemas.TripStatus.Canceled)
        revert('Trip canceled');
    }
    CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();
    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(trip.carId);

    carStorage.enginesService.verifyStartParams(panelParams, carInfo.engineType);

    require(trip.status == Schemas.TripStatus.Approved, 'The trip is not in status Approved');

    s.idToTripInfo[tripId].status = Schemas.TripStatus.CheckedInByHost;
    s.idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
    s.idToTripInfo[tripId].startParamLevels = panelParams;
    s.idToTripInfo[tripId].guestInsuranceCompanyName = insuranceCompany;
    s.idToTripInfo[tripId].guestInsurancePolicyNumber = insuranceNumber;

    emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedInByHost),
      trip.host,
      trip.guest
    );
  }

//   /// @notice Performs the check-in process by the guest, updating the trip status and details.
//   /// Requirements:
//   /// - The caller must be the guest of the trip.
//   /// - The trip must be in status CheckedInByHost.
//   /// - The trip params must match.
//   /// @param tripId The ID of the trip to be checked in by the guest.
//   /// @param panelParams An array representing parameters related to fuel, odometer,
//   /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) public {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();
    Schemas.Trip memory trip = s.idToTripInfo[tripId];

    require(trip.guest == msg.sender, 'Only for guest');

    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(trip.carId);

    require(
      s.idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost,
      'The trip is not in status CheckedInByHost'
    );
    carStorage.enginesService.compareParams(panelParams, trip.startParamLevels, carInfo.engineType);
    s.idToTripInfo[tripId].tripStartedBy = msg.sender;
    s.idToTripInfo[tripId].status = Schemas.TripStatus.CheckedInByGuest;
    s.idToTripInfo[tripId].checkedInByGuestDateTime = block.timestamp;

    emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedInByGuest),
      trip.guest,
      trip.host
    );
  }

//   ///  @dev Initiates the check-out process by the guest, updating trip status, and recording end details.
//   ///    Requirements:
//   ///  - Only the guest of the trip can check out.
//   ///  - The trip must be in status CheckedInByGuest.
//   ///  - The end odometer reading must be greater than or equal to the start odometer reading.
//   ///  @param tripId The ID of the trip to be checked out by the guest.
//   /// @param panelParams An array representing parameters related to fuel, odometer,
//   /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) public {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();
    address user = msg.sender;
    Schemas.Trip memory trip = s.idToTripInfo[tripId];

     RefferalServiceStorage.passReferralProgram(
      Schemas.RefferalProgram.FinishTripAsGuest,
      abi.encode(trip.startDateTime, trip.endDateTime),
      user
    //   promoService
    );
    

    require(trip.guest == user, 'For trip guest only');
    Schemas.CarInfo memory carInfo = CarTokenStorage.getCarInfoById(trip.carId);

    require(
      trip.status == Schemas.TripStatus.CheckedInByGuest,
      'The trip is not in status CheckedInByGuest'
    );
    carStorage.enginesService.verifyEndParams(trip.startParamLevels, panelParams, carInfo.engineType);
    s.idToTripInfo[tripId].endParamLevels = panelParams;
    s.idToTripInfo[tripId].tripFinishedBy = user;

    s.idToTripInfo[tripId].status = Schemas.TripStatus.CheckedOutByGuest;
    (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = RentalityTripsHelperDiamond.getResolveAmountInUsdCents(
      carInfo.engineType,
      s.idToTripInfo[tripId],
      carInfo.engineParams
    );
    s.idToTripInfo[tripId].paymentInfo.resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
    s.idToTripInfo[tripId].paymentInfo.resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

    uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;

    if (resolveAmountInUsdCents > s.idToTripInfo[tripId].paymentInfo.depositInUsdCents) {
      resolveAmountInUsdCents = s.idToTripInfo[tripId].paymentInfo.depositInUsdCents;
    }
    s.idToTripInfo[tripId].paymentInfo.resolveAmountInUsdCents = resolveAmountInUsdCents;
    s.idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;

    emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedOutByGuest),
      trip.guest,
      trip.host
    );
  }

//   ///  @dev Initiates the check-out process by the host, updating trip status, and validating end details.
//   ///      Requirements:
//   ///      - Only the host of the trip can check out.
//   ///      - The trip must be in status CheckedOutByGuest.
//   ///      - End fuel level and odometer readings must match the recorded values at guest check-out.
//   ///  @param tripId The ID of the trip to be checked out by the host.
//   /// @param panelParams An array representing parameters related to fuel, odometer,
//   /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) public {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    CarTokenStorage.CarTokenFaucetStorage storage carStorage = CarTokenStorage.accessStorage();
    Schemas.Trip memory trip = s.idToTripInfo[tripId];
    address user = msg.sender;
    require(trip.host == user, 'For trip host only');

    require(
      trip.status == Schemas.TripStatus.CheckedOutByGuest ||
        trip.status == Schemas.TripStatus.CheckedInByHost ||
        trip.status == Schemas.TripStatus.CheckedInByGuest,
      'The trip is not in status CheckedOutByGuest, CheckedInByHost or CheckedInByGuest'
    );

    Schemas.CarInfo memory carInfo = carStorage.idToCarInfo[trip.carId];

    if (
      trip.status == Schemas.TripStatus.CheckedInByHost ||
      trip.status == Schemas.TripStatus.CheckedInByGuest
    ) {
      carStorage.enginesService.verifyEndParams(trip.startParamLevels, panelParams, carInfo.engineType);
      s.idToTripInfo[tripId].endParamLevels = panelParams;
      (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = RentalityTripsHelperDiamond.getResolveAmountInUsdCents(
        carInfo.engineType,
        trip,
        carInfo.engineParams
      );
      s.idToTripInfo[tripId].paymentInfo.resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
      s.idToTripInfo[tripId].paymentInfo.resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

      uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;

      if (resolveAmountInUsdCents > trip.paymentInfo.depositInUsdCents) {
        resolveAmountInUsdCents = trip.paymentInfo.depositInUsdCents;
      }
      s.idToTripInfo[tripId].paymentInfo.resolveAmountInUsdCents = resolveAmountInUsdCents;
      s.idToTripInfo[tripId].tripFinishedBy = user;
    } else {
      carStorage.enginesService.compareParams(trip.endParamLevels, panelParams, carInfo.engineType);
    }
    s.idToTripInfo[tripId].status = Schemas.TripStatus.CheckedOutByHost;
    s.idToTripInfo[tripId].checkedOutByHostDateTime = block.timestamp;

    emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedOutByHost),
      trip.host,
      trip.guest
    );
  }

//   /// @dev Finalizes a trip, updating its status to Finished and calculating resolution amounts.
//   ///    Requirements:
//   ///    - The trip must be in status CheckedOutByHost.
//   /// @param tripId The ID of the trip to be finished.
//   /// Emits a `TripStatusChanged` event with the new status Finished.
  function finishTrip(uint256 tripId) public {
    address user = msg.sender;
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    Schemas.Trip storage trip = s.idToTripInfo[tripId];

     require(
      trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest,
      'The trip is not CheckedOutByHost'
    );


    trip.status = Schemas.TripStatus.Finished;

    _removeActiveTrip(trip.carId, tripId);
    _removeActiveTripFromUser(tripId, trip.host);
    _removeActiveTripFromUser(tripId, trip.guest);
    trip.finishDateTime = block.timestamp;
    s.completedByAdmin[tripId] = UserServiceStorage.isAdmin(user) && trip.host != user && trip.guest != user;


       uint256 rentalityFee = PaymentsStorage.getPlatformFeeFrom(
      trip.paymentInfo.priceWithDiscount + trip.paymentInfo.pickUpFee + trip.paymentInfo.dropOfFee
    );
    uint insurancePrice = InsuranceServiceStorage.getInsurancePriceByTrip(tripId);
    (
      uint valueToHost,
      uint valueToGuest,
      uint valueToHostInUsdCents,
      uint valueToGuestInUsdCents,
      uint totalIncome
    ) = CurrencyConverterStorage.calculateTripFinsish(
        trip.paymentInfo,
        rentalityFee,
        insurancePrice
        // promoService
      );

    PaymentsStorage.payFinishTrip(trip, valueToHost, valueToGuest, totalIncome);

    saveTransactionInfo(
      tripId,
      rentalityFee,
      Schemas.TripStatus.Finished,
      valueToGuestInUsdCents,
      valueToHostInUsdCents - trip.paymentInfo.resolveAmountInUsdCents - insurancePrice
    );

    emitEvent(Schemas.EventType.Trip, tripId, uint8(Schemas.TripStatus.Finished), trip.host, trip.guest);
  }



//   /// @dev Function to save transaction information for a finished trip.
//   /// @param tripId Trip ID for which the transaction information is saved.
//   /// @param rentalityFee Rentality fee for the transaction.
//   /// @param depositRefund Amount refunded as deposit.
//   /// @param tripEarnings Earnings from the completed trip.
  function saveTransactionInfo(
    uint256 tripId,
    uint256 rentalityFee,
    Schemas.TripStatus status,
    uint256 depositRefund,
    uint256 tripEarnings
  ) private {
   TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    s.idToTripInfo[tripId].transactionInfo.rentalityFee = rentalityFee;
    s.idToTripInfo[tripId].transactionInfo.depositRefund = depositRefund;
    s.idToTripInfo[tripId].transactionInfo.tripEarnings = tripEarnings;
    s.idToTripInfo[tripId].transactionInfo.dateTime = block.timestamp;
    s.idToTripInfo[tripId].transactionInfo.statusBeforeCancellation = status;
  }


  function _removeActiveTrip(uint carId, uint tripId) private {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    uint[] memory activeTrips = s.carIdToActiveTrips[carId];
    for (uint i = 0; i < activeTrips.length; i++) {
      if (activeTrips[i] == tripId) {
        for (uint j = i; j < activeTrips.length - 1; j++) activeTrips[j] = activeTrips[j + 1];

        s.carIdToActiveTrips[carId] = activeTrips;
        break;
      }
    }
  }

  function _removeActiveTripFromUser(uint tripId, address user) private {
    TripServiceStorage.TripServiceFaucetStorage storage s = TripServiceStorage.accessStorage();
    uint[] memory activeTrips = s.userToActiveTrips[user];
    for (uint i = 0; i < activeTrips.length; i++) {
      if (activeTrips[i] == tripId) {
        for (uint j = i; j < activeTrips.length - 1; j++) activeTrips[j] = activeTrips[j + 1];

        s.userToActiveTrips[user] = activeTrips;
        break;
      }
    }
  }


}