// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x417886Ca72048E92E8Bf2082cf193ab8DB4ED09f
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityPaymentService.sol";
import "./RentalityCarToken.sol";
import "./RentalityUtils.sol";
import "./RentalityUserService.sol";

/// @title RentalityTripService
/// @dev Manages the lifecycle of rental trips, including creation, approval, and completion.
contract RentalityTripService {
    using Counters for Counters.Counter;
    Counters.Counter private _tripIdCounter;

    /// @dev Enumeration representing various states of a trip.
    enum TripStatus {
        Created,
        Approved,
        CheckedInByHost,
        CheckedInByGuest,
        CheckedOutByGuest,
        CheckedOutByHost,
        Finished,
        Canceled
    }

    /// @dev Enumeration representing the currency type used for payments.
    enum CurrencyType {
        ETH
    }

    /// @dev Struct containing payment information for a trip.
    struct PaymentInfo {
        uint256 tripId;
        address from;
        address to;
        uint64 totalDayPriceInUsdCents;
        uint64 taxPriceInUsdCents;
        uint64 depositInUsdCents;
        uint64 resolveAmountInUsdCents;
        CurrencyType currencyType;
        int256 ethToCurrencyRate;
        uint8 ethToCurrencyDecimals;
        uint64 resolveFuelAmountInUsdCents;
        uint64 resolveMilesAmountInUsdCents;
    }

    /// @dev Struct containing information about a trip.
    struct Trip {
        uint256 tripId;
        uint256 carId;
        TripStatus status;
        address guest;
        address host;
        string guestName;
        string hostName;
        uint64 pricePerDayInUsdCents;
        uint64 startDateTime;
        uint64 endDateTime;
        string startLocation;
        string endLocation;
        uint64 milesIncludedPerDay;
        uint64 fuelPricePerGalInUsdCents;
        PaymentInfo paymentInfo;
        uint approvedDateTime;
        uint rejectedDateTime;
        address rejectedBy;
        uint checkedInByHostDateTime;
        uint64 startFuelLevelInGal;
        uint64 startOdometr;
        uint checkedInByGuestDateTime;
        uint checkedOutByGuestDateTime;
        uint64 endFuelLevelInGal;
        uint64 endOdometr;
        uint checkedOutByHostDateTime;
    }

    struct AvailableCarResponse {
        RentalityCarToken.CarInfo car;
        string hostPhotoUrl;
        string hostName;
    }

    mapping(uint256 => Trip) private idToTripInfo;

    /// @dev Event emitted when a new trip is created.
    /// @param tripId The ID of the newly created trip.
    event TripCreated(uint256 tripId);

    /// @dev Event emitted when the status of a trip is changed.
    /// @param tripId The ID of the trip whose status changed.
    /// @param newStatus The new status of the trip.
    event TripStatusChanged(uint256 tripId, TripStatus newStatus);

    RentalityCurrencyConverter private currencyConverterService;
    RentalityCarToken private carService;
    RentalityPaymentService private paymentService;
    RentalityUserService private userService;

    /// @dev Constructor for the RentalityTripService contract.
    /// @param currencyConverterServiceAddress The address of the currency converter service.
    /// @param carServiceAddress The address of the car service.
    /// @param paymentServiceAddress The address of the payment service.
    /// @param userServiceAddress The address of the user service.
    constructor(
        address currencyConverterServiceAddress,
        address carServiceAddress,
        address paymentServiceAddress,
        address userServiceAddress
    ) {
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
        paymentService = RentalityPaymentService(paymentServiceAddress);
        carService = RentalityCarToken(carServiceAddress);
        userService = RentalityUserService(userServiceAddress);
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
    /// @param fuelPricePerGalInUsdCents The fuel price per gallon in USD cents.
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
        uint64 fuelPricePerGalInUsdCents,
        PaymentInfo memory paymentInfo
    ) public {
        _tripIdCounter.increment();
        uint256 newTripId = _tripIdCounter.current();
        if (milesIncludedPerDay == 0) {
            milesIncludedPerDay = 2 ** 32 - 1;
        }
        paymentInfo.tripId = newTripId;

        string memory guestName = userService.getKYCInfo(tx.origin).name;
        string memory hostName = userService.getKYCInfo(host).name;

        idToTripInfo[newTripId] = Trip(
            newTripId,
            carId,
            TripStatus.Created,
            guest,
            host,
            guestName,
            hostName,
            pricePerDayInUsdCents,
            startDateTime,
            endDateTime,
            startLocation,
            endLocation,
            milesIncludedPerDay,
            fuelPricePerGalInUsdCents,
            paymentInfo,
            0,
            0,
            address(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );

        emit TripCreated(newTripId);
    }

    /// @notice Approves a trip by changing its status to Approved.
    ///  Requirements:
    ///   - Only the host of the trip can approve it.
    ///   - The trip must be in status Created.
    ///  @param tripId The ID of the trip to be approved.
    function approveTrip(uint256 tripId) public {
        require(
            idToTripInfo[tripId].host == tx.origin,
            "Only host of the trip can approve it"
        );
        require(
            idToTripInfo[tripId].status == TripStatus.Created,
            "The trip is not in status Created"
        );

        idToTripInfo[tripId].status = TripStatus.Approved;
        idToTripInfo[tripId].approvedDateTime = block.timestamp;

        emit TripStatusChanged(tripId, TripStatus.Approved);
    }

    /// @notice Reject a trip by changing its status to Canceled.
    ///  Requirements:
    ///   - Only the host or guest of the trip can reject it.
    ///   - The trip must be in status Created, Approved, or CheckedInByHost.
    ///  @param tripId The ID of the trip to be Rejected
    function rejectTrip(uint256 tripId) public {
        require(
            idToTripInfo[tripId].host == tx.origin ||
            idToTripInfo[tripId].guest == tx.origin,
            "Only host or guest of the trip can reject it"
        );
        require(
            idToTripInfo[tripId].status == TripStatus.Created ||
            idToTripInfo[tripId].status == TripStatus.Approved ||
            idToTripInfo[tripId].status == TripStatus.CheckedInByHost,
            "The trip is not in status Created, Approved or CheckedInByHost"
        );

        idToTripInfo[tripId].status = TripStatus.Canceled;
        idToTripInfo[tripId].rejectedDateTime = block.timestamp;
        idToTripInfo[tripId].rejectedBy = tx.origin;

        emit TripStatusChanged(tripId, TripStatus.Canceled);
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
        RentalityCarToken.SearchCarParams memory searchParams
    ) public view returns (AvailableCarResponse[] memory) {
// if (startDateTime < block.timestamp){
//     return new RentalityCarToken.CarInfo[](0);
// }
        RentalityCarToken.CarInfo[] memory availableCars = carService.fetchAvailableCarsForUser(user, searchParams);
        if (availableCars.length == 0) return new AvailableCarResponse[](0);

        Trip[] memory trips = getTripsThatIntersect(startDateTime, endDateTime);
        RentalityCarToken.CarInfo[] memory temp;
        uint256 resultCount;

        if (trips.length == 0)
        {
            temp = availableCars;
            resultCount = availableCars.length;
        }
        else
        {
            temp = new RentalityCarToken.CarInfo[](availableCars.length);
            resultCount = 0;

            for (uint i = 0; i < availableCars.length; i++) {
                bool hasIntersectTrip = false;

                for (uint j = 0; j < trips.length; j++) {
                    if (
                        trips[j].status == TripStatus.Created ||
                        trips[j].status == TripStatus.Finished ||
                        trips[j].status == TripStatus.Canceled
                    ) {
                        continue;
                    }

                    if (trips[j].carId == availableCars[i].carId) {
                        hasIntersectTrip = true;
                        break;
                    }
                }

                if (!hasIntersectTrip) {
                    temp[resultCount] = availableCars[i];
                    resultCount++;
                }
            }
        }
        AvailableCarResponse[] memory result = new AvailableCarResponse[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            string memory hostPhotoUrl = userService.getKYCInfo(temp[i].createdBy).profilePhoto;
            string memory hostName = userService.getKYCInfo(temp[i].createdBy).name;
            result[i] = AvailableCarResponse(temp[i], hostPhotoUrl, hostName);
        }
        return result;
    }

    /// @notice Performs the check-in process by the host, updating the trip status and details.
    /// Requirements:
    /// - The caller must be the host of the trip.
    /// - The trip must be in status Approved.
    /// @param tripId The ID of the trip to be checked in by the host.
    /// @param startFuelLevelInPermille The starting fuel level of the car in permille.
    /// @param startOdometr The starting odometer reading of the car.
    function checkInByHost(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        Trip memory trip = getTrip(tripId);
        require(trip.host == tx.origin, "For host only");

        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 startFuelLevelInGal = (carInfo.tankVolumeInGal *
            startFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.Approved,
            "The trip is not in status Approved"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedInByHost;
        idToTripInfo[tripId].checkedInByHostDateTime = block.timestamp;
        idToTripInfo[tripId].startFuelLevelInGal = startFuelLevelInGal;
        idToTripInfo[tripId].startOdometr = startOdometr;

        emit TripStatusChanged(tripId, TripStatus.CheckedInByHost);
    }

    /// @notice Performs the check-in process by the guest, updating the trip status and details.
    /// Requirements:
    /// - The caller must be the guest of the trip.
    /// - The trip must be in status CheckedInByHost.
    /// - The trip params must match.
    /// @param tripId The ID of the trip to be checked in by the guest.
    /// @param startFuelLevelInPermille The starting fuel level of the car in permille.
    /// @param startOdometr The starting odometer reading of the car.
    function checkInByGuest(
        uint256 tripId,
        uint64 startFuelLevelInPermille,
        uint64 startOdometr
    ) public {
        RentalityTripService.Trip memory trip = getTrip(tripId);
        require(trip.guest == tx.origin, "Only for guest");

        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 startFuelLevelInGal = (carInfo.tankVolumeInGal *
            startFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.CheckedInByHost,
            "The trip is not in status CheckedInByHost"
        );
        require(
            idToTripInfo[tripId].startFuelLevelInGal == startFuelLevelInGal,
            "Start fuel level does not match"
        );
        require(
            idToTripInfo[tripId].startOdometr == startOdometr,
            "Start odometr does not match"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedInByGuest;
        idToTripInfo[tripId].checkedInByGuestDateTime = block.timestamp;

        emit TripStatusChanged(tripId, TripStatus.CheckedInByGuest);
    }

    ///  @dev Initiates the check-out process by the guest, updating trip status, and recording end details.
    ///    Requirements:
    ///  - Only the guest of the trip can check out.
    ///  - The trip must be in status CheckedInByGuest.
    ///  - The end odometer reading must be greater than or equal to the start odometer reading.
    ///  @param tripId The ID of the trip to be checked out by the guest.
    ///  @param endFuelLevelInPermille The fuel level at the end of the trip in permille.
    ///  @param endOdometr The odometer reading at the end of the trip. than or equal to the start odometer reading.
    function checkOutByGuest(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        RentalityTripService.Trip memory trip = getTrip(tripId);
        require(
            trip.guest == tx.origin, "For trip guest only"
        );
        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 endFuelLevelInGal = (carInfo.tankVolumeInGal *
            endFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.CheckedInByGuest,
            "The trip is not in status CheckedInByGuest"
        );
        require(
            idToTripInfo[tripId].startOdometr <= endOdometr,
            "End odometr should be greater than start odometr"
        );
        idToTripInfo[tripId].status = TripStatus.CheckedOutByGuest;
        idToTripInfo[tripId].checkedOutByGuestDateTime = block.timestamp;
        idToTripInfo[tripId].endFuelLevelInGal = endFuelLevelInGal;
        idToTripInfo[tripId].endOdometr = endOdometr;

        emit TripStatusChanged(tripId, TripStatus.CheckedOutByGuest);
    }

    ///  @dev Initiates the check-out process by the host, updating trip status, and validating end details.
    ///      Requirements:
    ///      - Only the host of the trip can check out.
    ///      - The trip must be in status CheckedOutByGuest.
    ///      - End fuel level and odometer readings must match the recorded values at guest check-out.
    ///  @param tripId The ID of the trip to be checked out by the host.
    ///  @param endFuelLevelInPermille The fuel level at the end of the trip in permille.
    ///  @param endOdometr The odometer reading at the end of the trip.
    function checkOutByHost(
        uint256 tripId,
        uint64 endFuelLevelInPermille,
        uint64 endOdometr
    ) public {
        RentalityTripService.Trip memory trip = getTrip(tripId);
        require(
            trip.host == tx.origin, "For trip host only"
        );
        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(trip.carId);
        uint64 endFuelLevelInGal = (carInfo.tankVolumeInGal *
            endFuelLevelInPermille) / 1000;

        require(
            idToTripInfo[tripId].status == TripStatus.CheckedOutByGuest,
            "The trip is not in status CheckedOutByGuest"
        );
        require(
            idToTripInfo[tripId].endFuelLevelInGal == endFuelLevelInGal,
            "End fuel level does not match"
        );
        require(
            idToTripInfo[tripId].endOdometr == endOdometr,
            "End odometr does not match"
        );

        idToTripInfo[tripId].status = TripStatus.CheckedOutByHost;
        idToTripInfo[tripId].checkedOutByHostDateTime = block.timestamp;

        emit TripStatusChanged(tripId, TripStatus.CheckedOutByHost);
    }

    /// @dev Finalizes a trip, updating its status to Finished and calculating resolution amounts.
    ///    Requirements:
    ///    - The trip must be in status CheckedOutByHost.
    /// @param tripId The ID of the trip to be finished.
    /// Emits a `TripStatusChanged` event with the new status Finished.
    function finishTrip(uint256 tripId) public {
//require(idToTripInfo[tripId].status != TripStatus.CheckedOutByHost,"The trip is not in status CheckedOutByHost");
        require(
            idToTripInfo[tripId].status == TripStatus.CheckedOutByHost,
            "The trip is not in status CheckedOutByHost"
        );
        idToTripInfo[tripId].status = TripStatus.Finished;

        (uint64 resolveMilesAmountInUsdCents, uint64 resolveFuelAmountInUsdCents) = getResolveAmountInUsdCents(
            idToTripInfo[tripId]
        );
        idToTripInfo[tripId]
        .paymentInfo
        .resolveMilesAmountInUsdCents = resolveMilesAmountInUsdCents;
        idToTripInfo[tripId]
        .paymentInfo
        .resolveFuelAmountInUsdCents = resolveFuelAmountInUsdCents;

        uint64 resolveAmountInUsdCents = resolveMilesAmountInUsdCents + resolveFuelAmountInUsdCents;

        if (
            resolveAmountInUsdCents >
            idToTripInfo[tripId].paymentInfo.depositInUsdCents
        ) {
            resolveAmountInUsdCents = idToTripInfo[tripId]
                .paymentInfo
                .depositInUsdCents;
        }
        idToTripInfo[tripId]
        .paymentInfo
        .resolveAmountInUsdCents = resolveAmountInUsdCents;

        emit TripStatusChanged(tripId, TripStatus.Finished);
    }

    ///  @dev Calculates the resolved amount in USD cents for a trip.
    ///  @param tripInfo The information about the trip.
    /// @return Returns the resolved amounts for miles and fuel in USD cents as a tuple.
    function getResolveAmountInUsdCents(
        Trip memory tripInfo
    ) public pure returns (uint64, uint64) {
        uint64 tripDays = RentalityUtils.getCeilDays(tripInfo.startDateTime, tripInfo.endDateTime);

        return
            getResolveAmountInUsdCents(
            tripInfo.startOdometr,
            tripInfo.endOdometr,
            tripInfo.milesIncludedPerDay,
            tripInfo.pricePerDayInUsdCents,
            tripDays,
            tripInfo.startFuelLevelInGal,
            tripInfo.endFuelLevelInGal,
            tripInfo.fuelPricePerGalInUsdCents
        );
    }

    /// @dev Calculates the resolution amounts (miles and fuel) for a given set of parameters.
    /// @param startOdometr The starting odometer reading.
    /// @param endOdometr The ending odometer reading.
    /// @param milesIncludedPerDay The number of miles included per day.
    /// @param pricePerDayInUsdCents The rental price per day in USD cents.
    /// @param tripDays The number of days for the trip.
    /// @param startFuelLevelInGal The starting fuel level in gallons.
    /// @param endFuelLevelInGal The ending fuel level in gallons.
    /// @param fuelPricePerGalInUsdCents The fuel price per gallon in USD cents.
    /// @return resolveMilesAmountInUsdCents The resolution amount for extra miles in USD cents.
    /// @return resolveFuelAmountInUsdCents The resolution amount for extra fuel consumption in USD cents.
    function getResolveAmountInUsdCents(
        uint64 startOdometr,
        uint64 endOdometr,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays,
        uint64 startFuelLevelInGal,
        uint64 endFuelLevelInGal,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64, uint64) {
        return (
            getDrivenMilesResolveAmountInUsdCents(
            startOdometr,
            endOdometr,
            milesIncludedPerDay,
            pricePerDayInUsdCents,
            tripDays
        ),
            getFuelResolveAmountInUsdCents(
            startFuelLevelInGal,
            endFuelLevelInGal,
            fuelPricePerGalInUsdCents
        ));
    }

    /// @dev Calculates the resolution amount for extra driven miles.
    /// @param startOdometr The starting odometer reading.
    /// @param endOdometr The ending odometer reading.
    /// @param milesIncludedPerDay The number of miles included per day.
    /// @param pricePerDayInUsdCents The rental price per day in USD cents.
    /// @param tripDays The number of days for the trip.
    /// @return resolveMilesAmountInUsdCents The resolution amount for extra miles in USD cents.
    function getDrivenMilesResolveAmountInUsdCents(
        uint64 startOdometr,
        uint64 endOdometr,
        uint64 milesIncludedPerDay,
        uint64 pricePerDayInUsdCents,
        uint64 tripDays
    ) public pure returns (uint64) {
        if (endOdometr - startOdometr <= milesIncludedPerDay * tripDays)
            return 0;

        return
            ((endOdometr - startOdometr - milesIncludedPerDay * tripDays) *
                pricePerDayInUsdCents) / milesIncludedPerDay;
    }

    /// @dev Calculates the resolution amount for extra fuel consumption.
    /// @param startFuelLevelInGal The starting fuel level in gallons.
    /// @param endFuelLevelInGal The ending fuel level in gallons.
    /// @param fuelPricePerGalInUsdCents The fuel price per gallon in USD cents.
    /// @return resolveFuelAmountInUsdCents The resolution amount for extra fuel consumption in USD cents.
    function getFuelResolveAmountInUsdCents(
        uint64 startFuelLevelInGal,
        uint64 endFuelLevelInGal,
        uint64 fuelPricePerGalInUsdCents
    ) public pure returns (uint64) {
        if (endFuelLevelInGal >= startFuelLevelInGal) return 0;

        return
            (startFuelLevelInGal - endFuelLevelInGal) *
            fuelPricePerGalInUsdCents;
    }

    /// @dev Retrieves the details of a specific trip by its ID.
    /// @param tripId The ID of the trip to retrieve.
    /// @return trip The details of the requested trip.
    function getTrip(uint256 tripId) public view returns (Trip memory) {
        return idToTripInfo[tripId];
    }

    /// @dev Retrieves an array of trips associated with a specific guest address.
    /// @param guest The address of the guest.
    /// @return trips An array of trips associated with the specified guest.
    function getTripsByGuest(
        address guest
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].guest == guest) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].guest == guest) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific host address.
    /// @param host The address of the host.
    /// @return trips An array of trips associated with the specified host.
    function getTripsByHost(address host) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].host == host) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].host == host) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Retrieves an array of trips associated with a specific car ID.
    /// @param carId The ID of the car.
    /// @return trips An array of trips associated with the specified car ID.
    function getTripsByCar(uint256 carId) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].carId == carId) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (idToTripInfo[currentId].carId == carId) {
                Trip storage currentItem = idToTripInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

/**
 * @dev Checks if a specific car has intersecting trip within a given time range.
 * @param tripId The ID of the trip to check.
 * @param startDateTime The start date and time of the time range.
 * @param endDateTime The end date and time of the time range.
 * @return hasIntersectingTrips A boolean indicating whether the car has intersecting trips within the specified time range.
 */
    function isCarThatIntersect(
        uint256 tripId,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) private view returns (bool) {
        return
            (idToTripInfo[tripId].carId == carId) &&
            (idToTripInfo[tripId].endDateTime > startDateTime) &&
            (idToTripInfo[tripId].startDateTime < endDateTime);
    }

    ///  @dev Checks if a specific car ID has intersecting trips within a given time range.
    ///  @param carId The ID of the car to check.
    ///  @param startDateTime The start date and time of the time range.
    ///  @param endDateTime The end date and time of the time range.
    ///  @return trips An array of intersecting trips for the specified car within the specified time range.
    function getTripsForCarThatIntersect(
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isCarThatIntersect(currentId, carId, startDateTime, endDateTime)
            ) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isCarThatIntersect(currentId, carId, startDateTime, endDateTime)
            ) {
                result[currentIndex] = idToTripInfo[currentId];
                currentIndex += 1;
            }
        }

        return result;
    }

    /// @dev Checks if a specific trip has intersecting trips within a given time range.
    /// @param tripId The ID of the trip to check.
    /// @param startDateTime The start date and time of the time range.
    /// @param endDateTime The end date and time of the time range.
    /// @return hasIntersectingTrips A boolean indicating whether the trip has intersecting trips within the specified time range.
    function isTripThatIntersect(
        uint256 tripId,
        uint64 startDateTime,
        uint64 endDateTime
    ) private view returns (bool) {
        return
            (idToTripInfo[tripId].endDateTime > startDateTime) &&
            (idToTripInfo[tripId].startDateTime < endDateTime);
    }

<<<<<<< HEAD
=======
    /// @dev Retrieves an array of trips that intersect with a given time range.
    /// @param startDateTime The start date and time of the time range.
    /// @param endDateTime The end date and time of the time range.
    /// @return intersectingTrips An array of trips that intersect with the specified time range.
>>>>>>> eac5975e7b89c682e254160154fbe8ecc70cddc7
    function getTripsThatIntersect(
        uint64 startDateTime,
        uint64 endDateTime
    ) public view returns (Trip[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isTripThatIntersect(currentId, startDateTime, endDateTime)
            ) {
                itemCount += 1;
            }
        }

        Trip[] memory result = new Trip[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalTripCount(); i++) {
            uint currentId = i + 1;
            if (
                isTripThatIntersect(currentId, startDateTime, endDateTime)
            ) {
                result[currentIndex] = idToTripInfo[currentId];
                currentIndex += 1;
            }
        }

        return result;
    }

    ///  @dev Retrieves the addresses of the host and guest associated with a specific trip ID.
    ///  @param tripId The ID of the trip.
    ///  @return hostAddress The address of the host.
    ///  @return guestAddress The address of the guest.
    function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress){
        return (idToTripInfo[tripId].host, idToTripInfo[tripId].guest);
    }
}
