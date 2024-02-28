// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//deployed 26.05.2023 11:15 to sepolia at 0x417886Ca72048E92E8Bf2082cf193ab8DB4ED09f
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './RentalityCurrencyConverter.sol';
import './RentalityPaymentService.sol';
import './RentalityCarToken.sol';
import './RentalityUserService.sol';
import './libs/RentalityQuery.sol';
import './libs/RentalityUtils.sol';
import './engine/RentalityEnginesService.sol';
import './Schemas.sol';
import './RentalityAutomation.sol';

/// @title RentalityTripService
/// @dev Manages the lifecycle of rental trips, including creation, approval, and completion.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityTripService is Initializable, UUPSUpgradeable {
  using Counters for Counters.Counter;
  Counters.Counter private _tripIdCounter;

  mapping(uint256 => Schemas.Trip) private idToTripInfo;

  /// @dev Event emitted when a new trip is created.
  /// @param tripId The ID of the newly created trip.
  event TripCreated(uint256 tripId);

  /// @dev Event emitted when the status of a trip is changed.
  /// @param tripId The ID of the trip whose status changed.
  /// @param newStatus The new status of the trip.
  event TripStatusChanged(uint256 tripId, Schemas.TripStatus newStatus);

  RentalityCurrencyConverter private currencyConverterService;
  RentalityCarToken private carService;
  RentalityPaymentService private paymentService;
  RentalityUserService private userService;
  RentalityEnginesService private engineService;
  RentalityAutomation private automationService;

  /// @dev Get the total number of trips created.
  /// @return The total number of trips.
  function totalTripCount() public view returns (uint) {
    return _tripIdCounter.current();
  }

  /// @dev Create a new trip with the provided details.
  /// @param carId The ID of the car for the trip.
  /// @param guest The address of the guest initiating the trip.
  /// @param host The address of the host for the trip.
  /// @param pricePerDayInUsdCents The daily rental price in USD cents.
  /// @param startDateTime The start date and time of the trip.
  /// @param endDateTime The end date and time of the trip.
  /// @param startLocation The starting location of the trip.
  /// @param endLocation The ending location of the trip.
  /// @param milesIncludedPerDay The number of miles included per day.
  /// @param paymentInfo The payment information for the trip.
  function createNewTrip(
    uint256 carId,
    address guest,
    address host,
    uint64 pricePerDayInUsdCents,
    uint64 startDateTime,
    uint64 endDateTime,
    string memory startLocation,
    string memory endLocation,
    uint64 milesIncludedPerDay,
    Schemas.PaymentInfo memory paymentInfo
  ) public {
    require(userService.isManager(msg.sender), 'Only from manager contract.');
    _tripIdCounter.increment();
    uint256 newTripId = _tripIdCounter.current();
    if (milesIncludedPerDay == 0) {
      milesIncludedPerDay = 2 ** 32 - 1;
    }
    paymentInfo.tripId = newTripId;

    automationService.addAutomation(
      newTripId,
      block.timestamp + automationService.getAutoCancellationTimeInSec(),
      Schemas.AutomationType.Rejection
    );

    Schemas.CarInfo memory carInfo = carService.getCarInfoById(carId);

    uint256 panelParamsAmount = engineService.getPanelParamsAmount(carInfo.engineType);

    idToTripInfo[newTripId] = Schemas.Trip(
      newTripId,
      carId,
      Schemas.TripStatus.Created,
      guest,
      host,
      userService.getKYCInfo(tx.origin).name,
      userService.getKYCInfo(host).name,
      pricePerDayInUsdCents,
      startDateTime,
      endDateTime,
      carInfo.engineType,
      startLocation,
      endLocation,
      milesIncludedPerDay,
      engineService.getFuelPricesFromEngineParams(carInfo.engineType, carInfo.engineParams),
      paymentInfo,
      block.timestamp,
      0,
      0,
      address(0),
      0,
      new uint64[](panelParamsAmount),
      0,
      address(0),
      0,
      address(0),
      new uint64[](panelParamsAmount),
      0,
      Schemas.TransactionInfo(0, 0, 0, 0, Schemas.TripStatus.Created)
    );

    emit TripCreated(newTripId);
  }

  /// @notice Approves a trip by changing its status to Approved.
  ///  Requirements:
  ///   - Only the host of the trip can approve it.
  ///   - The trip must be in status Created.
  ///  @param tripId The ID of the trip to be approved.
  function approveTrip(uint256 tripId) public {
    require(userService.isManager(msg.sender), 'Only from manager contract.');
    require(idToTripInfo[tripId].host == tx.origin, 'Only host of the trip can approve it');
    require(idToTripInfo[tripId].status == Schemas.TripStatus.Created, 'The trip is not in status Created');

    automationService.removeAutomation(tripId, Schemas.AutomationType.Rejection);

    idToTripInfo[tripId].status = Schemas.TripStatus.Approved;
    idToTripInfo[tripId].approvedDateTime = block.timestamp;

    emit TripStatusChanged(tripId, Schemas.TripStatus.Approved);
  }

  /// @notice Reject a trip by changing its status to Canceled.
  ///  Requirements:
  ///   - Only the host or guest of the trip can reject it.
  ///   - The trip must be in status Created, Approved, or CheckedInByHost.
  ///  @param tripId The ID of the trip to be Rejected
  function rejectTrip(uint256 tripId) public {
    require(userService.isManager(msg.sender), 'Only from manager contract.');

    Schemas.AutomationData memory automation = automationService.getAutomation(
      tripId,
      Schemas.AutomationType.Rejection
    );
    require(
      idToTripInfo[tripId].host == tx.origin ||
        idToTripInfo[tripId].guest == tx.origin ||
        (automation.whenToCallInSec != 0 && automation.whenToCallInSec <= block.timestamp),
      'Only host or guest of the trip can reject it'
    );

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.Created ||
        idToTripInfo[tripId].status == Schemas.TripStatus.Approved ||
        idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost,
      'The trip is not in status Created, Approved'
    );
    bool isAutomaticCall = idToTripInfo[tripId].host != tx.origin && idToTripInfo[tripId].guest != tx.origin;

    idToTripInfo[tripId].status = Schemas.TripStatus.Canceled;
    idToTripInfo[tripId].rejectedDateTime = block.timestamp;

    if (!isAutomaticCall) {
      idToTripInfo[tripId].rejectedBy = tx.origin;
    }
    automationService.removeAutomation(tripId, Schemas.AutomationType.Rejection);

    emit TripStatusChanged(tripId, Schemas.TripStatus.Canceled);
  }

  /// @dev Searches for available cars for a user within a specified time range and search parameters.
  /// @param user The address of the user for whom to search available cars.
  /// @param startDateTime The start date and time of the search period.
  /// @param endDateTime The end date and time of the search period.
  /// @param searchParams The search parameters for filtering available cars.
  /// @return An array of available car information matching the search criteria.
  function searchAvailableCarsForUser(
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams
  ) public view returns (Schemas.SearchCar[] memory) {
    return
      RentalityQuery.searchAvailableCarsForUser(
        user,
        startDateTime,
        endDateTime,
        searchParams,
        address(carService),
        address(userService),
        address(this)
      );
  }

  /// @notice Performs the check-in process by the host, updating the trip status and details.
  /// Requirements:
  /// - The caller must be the host of the trip.
  /// - The trip must be in status Approved.
  /// @param tripId The ID of the trip to be checked in by the host.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByHost(uint256 tripId, uint64[] memory panelParams) public {
    Schemas.Trip memory trip = getTrip(tripId);
    require(trip.host == tx.origin, 'For host only');

    for (uint i = 1; i <= totalTripCount(); i++) {
      Schemas.Trip memory check_trip = getTrip(i);

      if (
        check_trip.carId == trip.carId &&
        (check_trip.status == Schemas.TripStatus.CheckedInByGuest ||
          check_trip.status == Schemas.TripStatus.CheckedInByHost ||
          check_trip.status == Schemas.TripStatus.CheckedOutByGuest)
      ) {
        revert('Car on the trip.');
      }
    }

    Schemas.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);

    engineService.verifyStartParams(panelParams, carInfo.engineType);

    require(idToTripInfo[tripId].status == Schemas.TripStatus.Approved, 'The trip is not in status Approved');

    automationService.addAutomation(
      tripId,
      block.timestamp + automationService.getAutoStatusChangeTimeInSec(),
      Schemas.AutomationType.StartTrip
    );

    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedInByHost;
    idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
    idToTripInfo[tripId].startParamLevels = panelParams;
    emit TripStatusChanged(tripId, Schemas.TripStatus.CheckedInByHost);
  }

  /// @notice Performs the check-in process by the guest, updating the trip status and details.
  /// Requirements:
  /// - The caller must be the guest of the trip.
  /// - The trip must be in status CheckedInByHost.
  /// - The trip params must match.
  /// @param tripId The ID of the trip to be checked in by the guest.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) public {
    Schemas.Trip memory trip = getTrip(tripId);
    Schemas.AutomationData memory automation = automationService.getAutomation(
      tripId,
      Schemas.AutomationType.StartTrip
    );

    require(
      trip.guest == tx.origin || (automation.whenToCallInSec != 0 && automation.whenToCallInSec <= block.timestamp),
      'Only for guest'
    );

    bool isAutomatic = trip.guest != tx.origin;

    Schemas.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost,
      'The trip is not in status CheckedInByHost'
    );
    if (!isAutomatic) {
      engineService.compareParams(panelParams, trip.startParamLevels, carInfo.engineType);
      idToTripInfo[tripId].tripStartedBy = tx.origin;
    }
    automationService.removeAutomation(tripId, Schemas.AutomationType.StartTrip);
    automationService.addAutomation(
      tripId,
      trip.endDateTime + automationService.getAutoStatusChangeTimeInSec(),
      Schemas.AutomationType.FinishTrip
    );

    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedInByGuest;
    idToTripInfo[tripId].checkedInByGuestDateTime = block.timestamp;

    emit TripStatusChanged(tripId, Schemas.TripStatus.CheckedInByGuest);
  }

  ///  @dev Initiates the check-out process by the guest, updating trip status, and recording end details.
  ///    Requirements:
  ///  - Only the guest of the trip can check out.
  ///  - The trip must be in status CheckedInByGuest.
  ///  - The end odometer reading must be greater than or equal to the start odometer reading.
  ///  @param tripId The ID of the trip to be checked out by the guest.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) public {
    Schemas.Trip memory trip = getTrip(tripId);
    Schemas.AutomationData memory automation = automationService.getAutomation(
      tripId,
      Schemas.AutomationType.FinishTrip
    );

    require(
      trip.guest == tx.origin || (automation.whenToCallInSec != 0 && automation.whenToCallInSec <= block.timestamp),
      'For trip guest only'
    );
    Schemas.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);

    bool isAutomation = trip.guest != tx.origin;

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByGuest,
      'The trip is not in status CheckedInByGuest'
    );
    automationService.removeAutomation(tripId, Schemas.AutomationType.FinishTrip);
    if (!isAutomation) {
      engineService.verifyEndParams(trip.startParamLevels, panelParams, carInfo.engineType);
      idToTripInfo[tripId].endParamLevels = panelParams;
      idToTripInfo[tripId].tripFinishedBy = tx.origin;
    } else {
      idToTripInfo[tripId].endParamLevels = idToTripInfo[tripId].startParamLevels;
    }

    automationService.removeAutomation(tripId, Schemas.AutomationType.FinishTrip);

    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedOutByGuest;
    idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;

    emit TripStatusChanged(tripId, Schemas.TripStatus.CheckedOutByGuest);
  }

  ///  @dev Initiates the check-out process by the host, updating trip status, and validating end details.
  ///      Requirements:
  ///      - Only the host of the trip can check out.
  ///      - The trip must be in status CheckedOutByGuest.
  ///      - End fuel level and odometer readings must match the recorded values at guest check-out.
  ///  @param tripId The ID of the trip to be checked out by the host.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) public {
    Schemas.Trip memory trip = getTrip(tripId);
    require(trip.host == tx.origin, 'For trip host only');

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedOutByGuest,
      'The trip is not in status CheckedOutByGuest'
    );

    Schemas.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);

    engineService.compareParams(trip.endParamLevels, panelParams, carInfo.engineType);

    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedOutByHost;
    idToTripInfo[tripId].checkedOutByHostDateTime = block.timestamp;

    emit TripStatusChanged(tripId, Schemas.TripStatus.CheckedOutByHost);
  }

  /// @dev Finalizes a trip, updating its status to Finished and calculating resolution amounts.
  ///    Requirements:
  ///    - The trip must be in status CheckedOutByHost.
  /// @param tripId The ID of the trip to be finished.
  /// Emits a `TripStatusChanged` event with the new status Finished.
  function finishTrip(uint256 tripId) public {
    //require(idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,"The trip is not in status CheckedOutByHost");
    require(userService.isManager(msg.sender), 'Only from manager contract.');

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedOutByHost,
      'The trip is not in status CheckedOutByHost'
    );
    idToTripInfo[tripId].status = Schemas.TripStatus.Finished;

    Schemas.CarInfo memory car = carService.getCarInfoById(idToTripInfo[tripId].carId);

    (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = getResolveAmountInUsdCents(
      car.engineType,
      idToTripInfo[tripId],
      car.engineParams
    );
    idToTripInfo[tripId].paymentInfo.resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
    idToTripInfo[tripId].paymentInfo.resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

    uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;

    if (resolveAmountInUsdCents > idToTripInfo[tripId].paymentInfo.depositInUsdCents) {
      resolveAmountInUsdCents = idToTripInfo[tripId].paymentInfo.depositInUsdCents;
    }
    idToTripInfo[tripId].paymentInfo.resolveAmountInUsdCents = resolveAmountInUsdCents;

    emit TripStatusChanged(tripId, Schemas.TripStatus.Finished);
  }

  ///  @dev Calculates the resolved amount in USD cents for a trip.
  ///  @param eType the engine type
  ///  @param engineParams, engine data params
  ///  @param tripInfo The information about the trip.
  ///  @return Returns the resolved amounts for miles and fuel in USD cents as a tuple.
  function getResolveAmountInUsdCents(
    uint8 eType,
    Schemas.Trip memory tripInfo,
    uint64[] memory engineParams
  ) public view returns (uint64, uint64) {
    uint64 tripDays = RentalityUtils.getCeilDays(tripInfo.startDateTime, tripInfo.endDateTime);

    return
      engineService.getResolveAmountInUsdCents(
        eType,
        tripInfo.fuelPrice,
        tripInfo.startParamLevels,
        tripInfo.endParamLevels,
        engineParams,
        tripInfo.milesIncludedPerDay,
        tripInfo.pricePerDayInUsdCents,
        tripDays
      );
  }

  /// @dev Function to save transaction information for a finished trip.
  /// @param tripId Trip ID for which the transaction information is saved.
  /// @param rentalityFee Rentality fee for the transaction.
  /// @param depositRefund Amount refunded as deposit.
  /// @param tripEarnings Earnings from the completed trip.
  function saveTransactionInfo(
    uint256 tripId,
    uint256 rentalityFee,
    Schemas.TripStatus status,
    uint256 depositRefund,
    uint256 tripEarnings
  ) public {
    require(userService.isManager(msg.sender), 'Manager only.');

    idToTripInfo[tripId].transactionInfo.rentalityFee = rentalityFee;
    idToTripInfo[tripId].transactionInfo.depositRefund = depositRefund;
    idToTripInfo[tripId].transactionInfo.tripEarnings = tripEarnings;
    idToTripInfo[tripId].transactionInfo.dateTime = block.timestamp;
    idToTripInfo[tripId].transactionInfo.statusBeforeCancellation = status;
  }

  /// @dev Retrieves the details of a specific trip by its ID.
  /// @param tripId The ID of the trip to retrieve.
  /// @return trip The details of the requested trip.
  function getTrip(uint256 tripId) public view returns (Schemas.Trip memory) {
    return idToTripInfo[tripId];
  }

  ///  @dev Retrieves the addresses of the host and guest associated with a specific trip ID.
  ///  @param tripId The ID of the trip.
  ///  @return hostAddress The address of the host.
  ///  @return guestAddress The address of the guest.
  function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress) {
    return (idToTripInfo[tripId].host, idToTripInfo[tripId].guest);
  }

  /// @param currencyConverterServiceAddress The address of the currency converter service.
  /// @param carServiceAddress The address of the car service.
  /// @param paymentServiceAddress The address of the payment service.
  /// @param userServiceAddress The address of the user service.
  function initialize(
    address currencyConverterServiceAddress,
    address carServiceAddress,
    address paymentServiceAddress,
    address userServiceAddress,
    address engineServiceAddress,
    address automationServiceAddress
  ) public initializer {
    currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
    carService = RentalityCarToken(carServiceAddress);
    paymentService = RentalityPaymentService(paymentServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    engineService = RentalityEnginesService(engineServiceAddress);
    automationService = RentalityAutomation(automationServiceAddress);
  }

  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(userService.isAdmin(msg.sender), 'Only for Admin.');
  }
}
