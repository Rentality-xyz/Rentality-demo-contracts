// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//deployed 26.05.2023 11:15 to sepolia at 0x417886Ca72048E92E8Bf2082cf193ab8DB4ED09f
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import './features/RentalityClaimService.sol';
import './abstract/IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './payments/RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './RentalityPlatform.sol';
import './payments/RentalityPaymentService.sol';
import './Schemas.sol';
import './RentalityAdminGateway.sol';
import './features/RentalityCarDelivery.sol';
import './features/RentalityNotificationService.sol';

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
  RentalityContract private addresses;

  using RentalityQuery for RentalityContract;
  RentalityEnginesService private engineService;
  mapping(uint => bool) public completedByAdmin;

  mapping(uint => uint) public tripIdToEthSumInTripCreation;
  RentalityNotificationService private eventManager;
  mapping(uint => uint[]) private carIdToActiveTrips;
  mapping(uint => uint[]) private carIdToTrips;
  mapping(address => uint[]) private userToTrips;
  mapping(address => uint[]) private userToActiveTrips;

  /// @dev Updates the address of the RentalityEventManager contract.
  /// @param _eventManager The address of the new RentalityEventManager contract.
  function updateEventServiceAddress(address _eventManager) public {
    require(addresses.userService.isAdmin(msg.sender), 'Only admin.');
    eventManager = RentalityNotificationService(_eventManager);
  }

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
    bytes32 startLocation,
    bytes32 endLocation,
    uint64 milesIncludedPerDay,
    Schemas.PaymentInfo memory paymentInfo,
    uint msgValue
  ) public returns (uint) {
    require(addresses.userService.isManager(msg.sender), 'Only from manager contract.');
    _tripIdCounter.increment();
    uint256 newTripId = _tripIdCounter.current();
    if (milesIncludedPerDay == 0) {
      milesIncludedPerDay = 2 ** 32 - 1;
    }
    carIdToActiveTrips[carId].push(newTripId);
    carIdToTrips[carId].push(newTripId);
    userToTrips[host].push(newTripId);
    userToActiveTrips[host].push(newTripId);
    userToTrips[guest].push(newTripId);
    userToActiveTrips[guest].push(newTripId);

    paymentInfo.tripId = newTripId;

    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(carId);

    uint256 panelParamsAmount = engineService.getPanelParamsAmount(carInfo.engineType);

    idToTripInfo[newTripId] = Schemas.Trip(
      newTripId,
      carId,
      Schemas.TripStatus.Created,
      guest,
      host,
      addresses.userService.getKYCInfo(guest).name,
      addresses.userService.getKYCInfo(host).name,
      pricePerDayInUsdCents,
      startDateTime,
      endDateTime,
      carInfo.engineType,
      milesIncludedPerDay,
      engineService.getFuelPriceFromEngineParams(carInfo.engineType, carInfo.engineParams),
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
      startLocation == bytes32('') ? carInfo.locationHash : startLocation,
      endLocation == bytes32('') ? carInfo.locationHash : endLocation
    );
    tripIdToEthSumInTripCreation[newTripId] = msgValue;

    eventManager.emitEvent(Schemas.EventType.Trip, newTripId, uint8(Schemas.TripStatus.Created), guest, host);
    return newTripId;
  }

  /// @notice Approves a trip by changing its status to Approved.
  ///  Requirements:
  ///   - Only the host of the trip can approve it.
  ///   - The trip must be in status Created.
  ///  @param tripId The ID of the trip to be approved.
  function approveTrip(uint256 tripId, address user) public {
    require(addresses.userService.isManager(msg.sender), 'Only from manager contract.');
    address host = idToTripInfo[tripId].host;
    require(host == user, 'Only host of the trip can approve it');
    require(idToTripInfo[tripId].status == Schemas.TripStatus.Created, 'The trip is not in status Created');

    idToTripInfo[tripId].status = Schemas.TripStatus.Approved;
    idToTripInfo[tripId].approvedDateTime = block.timestamp;

    eventManager.emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.Approved),
      host,
      idToTripInfo[tripId].guest
    );
  }

  /// @notice Reject a trip by changing its status to Canceled.
  ///  Requirements:
  ///   - Only the host or guest of the trip can reject it.
  ///   - The trip must be in status Created, Approved, or CheckedInByHost.
  ///  @param tripId The ID of the trip to be Rejected
  function rejectTrip(uint256 tripId, uint256 rentalityFee, uint256 depositRefund, uint256 tripEarnings, address user) public {
    require(addresses.userService.isManager(msg.sender), 'Only from manager contract.');
    Schemas.TripStatus status = idToTripInfo[tripId].status;

    address host = idToTripInfo[tripId].host;
    address guest = idToTripInfo[tripId].guest;
    bool controversialSituation = addresses.userService.isAdmin(user) &&
      status == Schemas.TripStatus.CheckedOutByHost;

    require(
      idToTripInfo[tripId].host == user || idToTripInfo[tripId].guest == user || controversialSituation,
      'Only host or guest of the trip can reject it'
    );

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.Created ||
        idToTripInfo[tripId].status == Schemas.TripStatus.Approved ||
        idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost ||
        controversialSituation,
      'The trip is not in status Created, Approved'
    );
    _removeActiveTrip(idToTripInfo[tripId].carId, tripId);
    _removeActiveTripFromUser(tripId, idToTripInfo[tripId].host);
    _removeActiveTripFromUser(tripId, idToTripInfo[tripId].guest);
    idToTripInfo[tripId].status = Schemas.TripStatus.Canceled;
    idToTripInfo[tripId].rejectedDateTime = block.timestamp;
    idToTripInfo[tripId].rejectedBy = user;

    saveTransactionInfo(tripId, rentalityFee, status, depositRefund, tripEarnings);

    eventManager.emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.Canceled),
      user,
      user == guest ? guest : host
    );
  }
  /// @notice Allows the host to perform a check-in for a specific trip.
  /// This action typically occurs at the start of the trip and records key information
  /// such as fuel level, odometer reading, insurance details, and any other relevant data.
  /// @param tripId The unique identifier for the trip being checked in.
  /// @param panelParams An array of numeric parameters representing important vehicle details.
  ///   - panelParams[0]: Fuel level (e.g., as a percentage)
  ///   - panelParams[1]: Odometer reading (e.g., in kilometers or miles)
  ///   - Additional parameters can be added based on the engine and vehicle characteristics.
  /// @param insuranceCompany The name of the insurance company covering the vehicle.
  /// @param insuranceNumber The insurance policy number.
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber,
    address user
  ) public {
    Schemas.Trip memory trip = getTrip(tripId);
    require(trip.host == user, 'For host only');

    uint[] memory totalTrips = carIdToActiveTrips[trip.carId];
    for (uint i = 0; i < totalTrips.length; i++) {
      Schemas.Trip memory check_trip = getTrip(totalTrips[i]);

      if (
        check_trip.carId == trip.carId &&
        (check_trip.status == Schemas.TripStatus.CheckedInByGuest ||
          check_trip.status == Schemas.TripStatus.CheckedInByHost ||
          check_trip.status == Schemas.TripStatus.CheckedOutByGuest)
      ) {
        revert('Car on the trip.');
      }
    }

    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(trip.carId);

    engineService.verifyStartParams(panelParams, carInfo.engineType);

    require(idToTripInfo[tripId].status == Schemas.TripStatus.Approved, 'The trip is not in status Approved');

    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedInByHost;
    idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
    idToTripInfo[tripId].startParamLevels = panelParams;
    idToTripInfo[tripId].guestInsuranceCompanyName = insuranceCompany;
    idToTripInfo[tripId].guestInsurancePolicyNumber = insuranceNumber;

    eventManager.emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedInByHost),
      trip.host,
      trip.guest
    );
  }

  /// @notice Performs the check-in process by the guest, updating the trip status and details.
  /// Requirements:
  /// - The caller must be the guest of the trip.
  /// - The trip must be in status CheckedInByHost.
  /// - The trip params must match.
  /// @param tripId The ID of the trip to be checked in by the guest.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams, address user) public {
    require(addresses.userService.isManager(msg.sender), 'only Manager');
    Schemas.Trip memory trip = getTrip(tripId);

    require(trip.guest == user, 'Only for guest');

    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(trip.carId);

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost,
      'The trip is not in status CheckedInByHost'
    );
    engineService.compareParams(panelParams, trip.startParamLevels, carInfo.engineType);
    idToTripInfo[tripId].tripStartedBy = user;
    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedInByGuest;
    idToTripInfo[tripId].checkedInByGuestDateTime = block.timestamp;

    eventManager.emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedInByGuest),
      trip.guest,
      trip.host
    );
  }

  ///  @dev Initiates the check-out process by the guest, updating trip status, and recording end details.
  ///    Requirements:
  ///  - Only the guest of the trip can check out.
  ///  - The trip must be in status CheckedInByGuest.
  ///  - The end odometer reading must be greater than or equal to the start odometer reading.
  ///  @param tripId The ID of the trip to be checked out by the guest.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams, address user) public {
    require(addresses.userService.isManager(msg.sender), 'only Manager');
    Schemas.Trip memory trip = getTrip(tripId);

    require(trip.guest == user, 'For trip guest only');
    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(trip.carId);

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByGuest,
      'The trip is not in status CheckedInByGuest'
    );
    Schemas.CarInfo memory car = addresses.carService.getCarInfoById(idToTripInfo[tripId].carId);
    engineService.verifyEndParams(trip.startParamLevels, panelParams, carInfo.engineType);
    idToTripInfo[tripId].endParamLevels = panelParams;
    idToTripInfo[tripId].tripFinishedBy = user;

    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedOutByGuest;
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
    idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;

    eventManager.emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedOutByGuest),
      trip.guest,
      trip.host
    );
  }

  ///  @dev Initiates the check-out process by the host, updating trip status, and validating end details.
  ///      Requirements:
  ///      - Only the host of the trip can check out.
  ///      - The trip must be in status CheckedOutByGuest.
  ///      - End fuel level and odometer readings must match the recorded values at guest check-out.
  ///  @param tripId The ID of the trip to be checked out by the host.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams, address user) public {
    require(addresses.userService.isManager(msg.sender), 'only Manager');
    Schemas.Trip memory trip = getTrip(tripId);
    require(trip.host == user, 'For trip host only');

    require(
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedOutByGuest ||
        idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost ||
        idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByGuest,
      'The trip is not in status CheckedOutByGuest, CheckedInByHost or CheckedInByGuest'
    );

    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(trip.carId);

    if (
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByHost ||
      idToTripInfo[tripId].status == Schemas.TripStatus.CheckedInByGuest
    ) {
      engineService.verifyEndParams(trip.startParamLevels, panelParams, carInfo.engineType);
      idToTripInfo[tripId].endParamLevels = panelParams;
      (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = getResolveAmountInUsdCents(
        carInfo.engineType,
        idToTripInfo[tripId],
        carInfo.engineParams
      );
      idToTripInfo[tripId].paymentInfo.resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
      idToTripInfo[tripId].paymentInfo.resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

      uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;

      if (resolveAmountInUsdCents > idToTripInfo[tripId].paymentInfo.depositInUsdCents) {
        resolveAmountInUsdCents = idToTripInfo[tripId].paymentInfo.depositInUsdCents;
      }
      idToTripInfo[tripId].paymentInfo.resolveAmountInUsdCents = resolveAmountInUsdCents;
      idToTripInfo[tripId].tripFinishedBy = user;
    } else {
      engineService.compareParams(trip.endParamLevels, panelParams, carInfo.engineType);
    }
    idToTripInfo[tripId].status = Schemas.TripStatus.CheckedOutByHost;
    idToTripInfo[tripId].checkedOutByHostDateTime = block.timestamp;

    eventManager.emitEvent(
      Schemas.EventType.Trip,
      tripId,
      uint8(Schemas.TripStatus.CheckedOutByHost),
      trip.host,
      trip.guest
    );
  }

  /// @dev Finalizes a trip, updating its status to Finished and calculating resolution amounts.
  ///    Requirements:
  ///    - The trip must be in status CheckedOutByHost.
  /// @param tripId The ID of the trip to be finished.
  /// Emits a `TripStatusChanged` event with the new status Finished.
  function finishTrip(uint256 tripId, address user) public {
    //require(idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,"The trip is not in status CheckedOutByHost");
    require(addresses.userService.isManager(msg.sender), 'Only from manager contract.');
    Schemas.Trip storage trip = idToTripInfo[tripId];

    trip.status = Schemas.TripStatus.Finished;

    _removeActiveTrip(trip.carId, tripId);
    _removeActiveTripFromUser(tripId, trip.host);
    _removeActiveTripFromUser(tripId, trip.guest);
    trip.finishDateTime = block.timestamp;
    completedByAdmin[tripId] = addresses.userService.isAdmin(user) && trip.host != user && trip.guest != user;

    eventManager.emitEvent(Schemas.EventType.Trip, tripId, uint8(Schemas.TripStatus.Finished), trip.host, trip.guest);
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
    uint64 duration = tripInfo.endDateTime - tripInfo.startDateTime;
    uint64 tripDays = uint64(Math.ceilDiv(duration, 1 days));

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
    require(addresses.userService.isManager(msg.sender), 'Manager only.');

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
  function _removeActiveTrip(uint carId, uint tripId) private {
    uint[] memory activeTrips = carIdToActiveTrips[carId];
    for (uint i = 0; i < activeTrips.length; i++) {
      if (activeTrips[i] == tripId) {
        for (uint j = i; j < activeTrips.length - 1; j++) activeTrips[j] = activeTrips[j + 1];

        carIdToActiveTrips[carId] = activeTrips;
        break;
      }
    }
  }

    function _removeActiveTripFromUser(uint tripId, address user) private {
    uint[] memory activeTrips = userToActiveTrips[user];
    for (uint i = 0; i < activeTrips.length; i++) {
      if (activeTrips[i] == tripId) {
        for (uint j = i; j < activeTrips.length - 1; j++) activeTrips[j] = activeTrips[j + 1];

        userToActiveTrips[user] = activeTrips;
        break;
      }
    }
  }
  function getActiveTrips(uint carId) public view returns (uint[] memory) {
    return carIdToActiveTrips[carId];
  }
  function getCarTrips(uint carId) public view returns (uint[] memory) {
    return carIdToTrips[carId];
  }
   function getActiveTripsByUser(address host) public view returns (uint[] memory) {
    return userToActiveTrips[host];
  }
    function getTripsByUser(address host) public view returns (uint[] memory) {
    return userToTrips[host];
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
    address eventManagerAddress
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(address(this)),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(address(0)),
      RentalityPaymentService(payable(paymentServiceAddress)),
      RentalityClaimService(address(0)),
      RentalityAdminGateway(address(0)),
      RentalityCarDelivery(address(0)),
      RentalityView(address(0))
    );
    engineService = RentalityEnginesService(engineServiceAddress);
    eventManager = RentalityNotificationService(eventManagerAddress);
  }

  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(addresses.userService.isAdmin(msg.sender), 'Only for Admin.');
  }
}
