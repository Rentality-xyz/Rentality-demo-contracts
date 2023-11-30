# Solidity API

## RentalityTripService

_Manages the lifecycle of rental trips, including creation, approval, and completion._

### TripStatus

```solidity
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
```

### CurrencyType

```solidity
enum CurrencyType {
  ETH
}
```

### PaymentInfo

```solidity
struct PaymentInfo {
  uint256 tripId;
  address from;
  address to;
  uint64 totalDayPriceInUsdCents;
  uint64 taxPriceInUsdCents;
  uint64 depositInUsdCents;
  uint64 resolveAmountInUsdCents;
  enum RentalityTripService.CurrencyType currencyType;
  int256 ethToCurrencyRate;
  uint8 ethToCurrencyDecimals;
  uint64 resolveFuelAmountInUsdCents;
  uint64 resolveMilesAmountInUsdCents;
}
```

### Trip

```solidity
struct Trip {
  uint256 tripId;
  uint256 carId;
  enum RentalityTripService.TripStatus status;
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
  struct RentalityTripService.PaymentInfo paymentInfo;
  uint256 approvedDateTime;
  uint256 rejectedDateTime;
  address rejectedBy;
  uint256 checkedInByHostDateTime;
  uint64 startFuelLevelInGal;
  uint64 startOdometr;
  uint256 checkedInByGuestDateTime;
  uint256 checkedOutByGuestDateTime;
  uint64 endFuelLevelInGal;
  uint64 endOdometr;
  uint256 checkedOutByHostDateTime;
}
```

### TripCreated

```solidity
event TripCreated(uint256 tripId)
```

_Event emitted when a new trip is created._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the newly created trip. |

### TripStatusChanged

```solidity
event TripStatusChanged(uint256 tripId, enum RentalityTripService.TripStatus newStatus)
```

_Event emitted when the status of a trip is changed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip whose status changed. |
| newStatus | enum RentalityTripService.TripStatus | The new status of the trip. |

### constructor

```solidity
constructor(address currencyConverterServiceAddress, address carServiceAddress, address paymentServiceAddress, address userServiceAddress) public
```

_Constructor for the RentalityTripService contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| currencyConverterServiceAddress | address | The address of the currency converter service. |
| carServiceAddress | address | The address of the car service. |
| paymentServiceAddress | address | The address of the payment service. |
| userServiceAddress | address | The address of the user service. |

### totalTripCount

```solidity
function totalTripCount() public view returns (uint256)
```

_Get the total number of trips created._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The total number of trips. |

### createNewTrip

```solidity
function createNewTrip(uint256 carId, address guest, address host, uint64 pricePerDayInUsdCents, uint64 startDateTime, uint64 endDateTime, string startLocation, string endLocation, uint64 milesIncludedPerDay, uint64 fuelPricePerGalInUsdCents, struct RentalityTripService.PaymentInfo paymentInfo) public
```

_Create a new trip with the provided details._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car for the trip. |
| guest | address | The address of the guest initiating the trip. |
| host | address | The address of the host for the trip. |
| pricePerDayInUsdCents | uint64 | The daily rental price in USD cents. |
| startDateTime | uint64 | The start date and time of the trip. |
| endDateTime | uint64 | The end date and time of the trip. |
| startLocation | string | The starting location of the trip. |
| endLocation | string | The ending location of the trip. |
| milesIncludedPerDay | uint64 | The number of miles included per day. |
| fuelPricePerGalInUsdCents | uint64 | The fuel price per gallon in USD cents. |
| paymentInfo | struct RentalityTripService.PaymentInfo | The payment information for the trip. |

### approveTrip

```solidity
function approveTrip(uint256 tripId) public
```

Approves a trip by changing its status to Approved.
 Requirements:
  - Only the host of the trip can approve it.
  - The trip must be in status Created.
 @param tripId The ID of the trip to be approved.

### rejectTrip

```solidity
function rejectTrip(uint256 tripId) public
```

Reject a trip by changing its status to Canceled.
 Requirements:
  - Only the host or guest of the trip can reject it.
  - The trip must be in status Created, Approved, or CheckedInByHost.
 @param tripId The ID of the trip to be Rejected

### searchAvailableCarsForUser

```solidity
function searchAvailableCarsForUser(address user, uint64 startDateTime, uint64 endDateTime, struct RentalityCarToken.SearchCarParams searchParams) public view returns (struct RentalityCarToken.CarInfo[])
```

_Searches for available cars for a user within a specified time range and search parameters._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user for whom to search available cars. |
| startDateTime | uint64 | The start date and time of the search period. |
| endDateTime | uint64 | The end date and time of the search period. |
| searchParams | struct RentalityCarToken.SearchCarParams | The search parameters for filtering available cars. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityCarToken.CarInfo[] | An array of available car information matching the search criteria. |

### checkInByHost

```solidity
function checkInByHost(uint256 tripId, uint64 startFuelLevelInPermille, uint64 startOdometr) public
```

Performs the check-in process by the host, updating the trip status and details.
Requirements:
- The caller must be the host of the trip.
- The trip must be in status Approved.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to be checked in by the host. |
| startFuelLevelInPermille | uint64 | The starting fuel level of the car in permille. |
| startOdometr | uint64 | The starting odometer reading of the car. |

### checkInByGuest

```solidity
function checkInByGuest(uint256 tripId, uint64 startFuelLevelInPermille, uint64 startOdometr) public
```

Performs the check-in process by the guest, updating the trip status and details.
Requirements:
- The caller must be the guest of the trip.
- The trip must be in status CheckedInByHost.
- The trip params must match.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to be checked in by the guest. |
| startFuelLevelInPermille | uint64 | The starting fuel level of the car in permille. |
| startOdometr | uint64 | The starting odometer reading of the car. |

### checkOutByGuest

```solidity
function checkOutByGuest(uint256 tripId, uint64 endFuelLevelInPermille, uint64 endOdometr) public
```

@dev Initiates the check-out process by the guest, updating trip status, and recording end details.
   Requirements:
 - Only the guest of the trip can check out.
 - The trip must be in status CheckedInByGuest.
 - The end odometer reading must be greater than or equal to the start odometer reading.
 @param tripId The ID of the trip to be checked out by the guest.
 @param endFuelLevelInPermille The fuel level at the end of the trip in permille.
 @param endOdometr The odometer reading at the end of the trip. than or equal to the start odometer reading.

### checkOutByHost

```solidity
function checkOutByHost(uint256 tripId, uint64 endFuelLevelInPermille, uint64 endOdometr) public
```

@dev Initiates the check-out process by the host, updating trip status, and validating end details.
     Requirements:
     - Only the host of the trip can check out.
     - The trip must be in status CheckedOutByGuest.
     - End fuel level and odometer readings must match the recorded values at guest check-out.
 @param tripId The ID of the trip to be checked out by the host.
 @param endFuelLevelInPermille The fuel level at the end of the trip in permille.
 @param endOdometr The odometer reading at the end of the trip.

### finishTrip

```solidity
function finishTrip(uint256 tripId) public
```

_Finalizes a trip, updating its status to Finished and calculating resolution amounts.
   Requirements:
   - The trip must be in status CheckedOutByHost._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to be finished. Emits a `TripStatusChanged` event with the new status Finished. |

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(struct RentalityTripService.Trip tripInfo) public pure returns (uint64, uint64)
```

@dev Calculates the resolved amount in USD cents for a trip.
 @param tripInfo The information about the trip.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | Returns the resolved amounts for miles and fuel in USD cents as a tuple. |
| [1] | uint64 |  |

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(uint64 startOdometr, uint64 endOdometr, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays, uint64 startFuelLevelInGal, uint64 endFuelLevelInGal, uint64 fuelPricePerGalInUsdCents) public pure returns (uint64, uint64)
```

_Calculates the resolution amounts (miles and fuel) for a given set of parameters._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startOdometr | uint64 | The starting odometer reading. |
| endOdometr | uint64 | The ending odometer reading. |
| milesIncludedPerDay | uint64 | The number of miles included per day. |
| pricePerDayInUsdCents | uint64 | The rental price per day in USD cents. |
| tripDays | uint64 | The number of days for the trip. |
| startFuelLevelInGal | uint64 | The starting fuel level in gallons. |
| endFuelLevelInGal | uint64 | The ending fuel level in gallons. |
| fuelPricePerGalInUsdCents | uint64 | The fuel price per gallon in USD cents. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | resolveMilesAmountInUsdCents The resolution amount for extra miles in USD cents. |
| [1] | uint64 | resolveFuelAmountInUsdCents The resolution amount for extra fuel consumption in USD cents. |

### getDrivenMilesResolveAmountInUsdCents

```solidity
function getDrivenMilesResolveAmountInUsdCents(uint64 startOdometr, uint64 endOdometr, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays) public pure returns (uint64)
```

_Calculates the resolution amount for extra driven miles._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startOdometr | uint64 | The starting odometer reading. |
| endOdometr | uint64 | The ending odometer reading. |
| milesIncludedPerDay | uint64 | The number of miles included per day. |
| pricePerDayInUsdCents | uint64 | The rental price per day in USD cents. |
| tripDays | uint64 | The number of days for the trip. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | resolveMilesAmountInUsdCents The resolution amount for extra miles in USD cents. |

### getFuelResolveAmountInUsdCents

```solidity
function getFuelResolveAmountInUsdCents(uint64 startFuelLevelInGal, uint64 endFuelLevelInGal, uint64 fuelPricePerGalInUsdCents) public pure returns (uint64)
```

_Calculates the resolution amount for extra fuel consumption._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startFuelLevelInGal | uint64 | The starting fuel level in gallons. |
| endFuelLevelInGal | uint64 | The ending fuel level in gallons. |
| fuelPricePerGalInUsdCents | uint64 | The fuel price per gallon in USD cents. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | resolveFuelAmountInUsdCents The resolution amount for extra fuel consumption in USD cents. |

### getTrip

```solidity
function getTrip(uint256 tripId) public view returns (struct RentalityTripService.Trip)
```

_Retrieves the details of a specific trip by its ID._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to retrieve. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip | trip The details of the requested trip. |

### getTripsByGuest

```solidity
function getTripsByGuest(address guest) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips associated with a specific guest address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| guest | address | The address of the guest. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip[] | trips An array of trips associated with the specified guest. |

### getTripsByHost

```solidity
function getTripsByHost(address host) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips associated with a specific host address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| host | address | The address of the host. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip[] | trips An array of trips associated with the specified host. |

### getTripsByCar

```solidity
function getTripsByCar(uint256 carId) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips associated with a specific car ID._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip[] | trips An array of trips associated with the specified car ID. |

### getTripsForCarThatIntersect

```solidity
function getTripsForCarThatIntersect(uint256 carId, uint64 startDateTime, uint64 endDateTime) public view returns (struct RentalityTripService.Trip[])
```

@dev Checks if a specific car ID has intersecting trips within a given time range.
 @param carId The ID of the car to check.
 @param startDateTime The start date and time of the time range.
 @param endDateTime The end date and time of the time range.
 @return trips An array of intersecting trips for the specified car within the specified time range.

### getTripsThatIntersect

```solidity
function getTripsThatIntersect(uint64 startDateTime, uint64 endDateTime) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips that intersect with a given time range._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startDateTime | uint64 | The start date and time of the time range. |
| endDateTime | uint64 | The end date and time of the time range. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip[] | intersectingTrips An array of trips that intersect with the specified time range. |

### getAddressesByTripId

```solidity
function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress)
```

@dev Retrieves the addresses of the host and guest associated with a specific trip ID.
 @param tripId The ID of the trip.
 @return hostAddress The address of the host.
 @return guestAddress The address of the guest.

