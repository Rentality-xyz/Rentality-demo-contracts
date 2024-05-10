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
  uint64[] fuelPrices;
  struct RentalityTripService.PaymentInfo paymentInfo;
  uint256 approvedDateTime;
  uint256 rejectedDateTime;
  address rejectedBy;
  uint256 checkedInByHostDateTime;
  uint64[] startParamLevels;
  uint256 checkedInByGuestDateTime;
  uint256 checkedOutByGuestDateTime;
  uint64[] endParamLevels;
  uint256 checkedOutByHostDateTime;
}
```

### AvailableCarResponse

```solidity
struct AvailableCarResponse {
  struct RentalityCarToken.CarInfo car;
  string hostPhotoUrl;
  string hostName;
}
```

### TripCreated

```solidity
event TripCreated(uint256 tripId)
```

_Event emitted when a new trip is created._

#### Parameters

| Name   | Type    | Description                       |
| ------ | ------- | --------------------------------- |
| tripId | uint256 | The ID of the newly created trip. |

### TripStatusChanged

```solidity
event TripStatusChanged(uint256 tripId, enum RentalityTripService.TripStatus newStatus)
```

_Event emitted when the status of a trip is changed._

#### Parameters

| Name      | Type                                 | Description                              |
| --------- | ------------------------------------ | ---------------------------------------- |
| tripId    | uint256                              | The ID of the trip whose status changed. |
| newStatus | enum RentalityTripService.TripStatus | The new status of the trip.              |

### constructor

```solidity
constructor(address currencyConverterServiceAddress, address carServiceAddress, address paymentServiceAddress, address userServiceAddress, address engineServiceAddress) public
```

_Constructor for the RentalityTripService contract._

#### Parameters

| Name                            | Type    | Description                                    |
| ------------------------------- | ------- | ---------------------------------------------- |
| currencyConverterServiceAddress | address | The address of the currency converter service. |
| carServiceAddress               | address | The address of the car service.                |
| paymentServiceAddress           | address | The address of the payment service.            |
| userServiceAddress              | address | The address of the user service.               |
| engineServiceAddress            | address |                                                |

### totalTripCount

```solidity
function totalTripCount() public view returns (uint256)
```

_Get the total number of trips created._

#### Return Values

| Name | Type    | Description                |
| ---- | ------- | -------------------------- |
| [0]  | uint256 | The total number of trips. |

### createNewTrip

```solidity
function createNewTrip(uint256 carId, address guest, address host, uint64 pricePerDayInUsdCents, uint64 startDateTime, uint64 endDateTime, string startLocation, string endLocation, uint64 milesIncludedPerDay, uint64[] fuelPricesPerUnits, struct RentalityTripService.PaymentInfo paymentInfo) public
```

_Create a new trip with the provided details._

#### Parameters

| Name                  | Type                                    | Description                                   |
| --------------------- | --------------------------------------- | --------------------------------------------- |
| carId                 | uint256                                 | The ID of the car for the trip.               |
| guest                 | address                                 | The address of the guest initiating the trip. |
| host                  | address                                 | The address of the host for the trip.         |
| pricePerDayInUsdCents | uint64                                  | The daily rental price in USD cents.          |
| startDateTime         | uint64                                  | The start date and time of the trip.          |
| endDateTime           | uint64                                  | The end date and time of the trip.            |
| startLocation         | string                                  | The starting location of the trip.            |
| endLocation           | string                                  | The ending location of the trip.              |
| milesIncludedPerDay   | uint64                                  | The number of miles included per day.         |
| fuelPricesPerUnits    | uint64[]                                | The fuel prices per units depends on engine.  |
| paymentInfo           | struct RentalityTripService.PaymentInfo | The payment information for the trip.         |

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
function searchAvailableCarsForUser(address user, uint64 startDateTime, uint64 endDateTime, struct RentalityCarToken.SearchCarParams searchParams) public view returns (struct RentalityTripService.AvailableCarResponse[])
```

_Searches for available cars for a user within a specified time range and search parameters._

#### Parameters

| Name          | Type                                     | Description                                                |
| ------------- | ---------------------------------------- | ---------------------------------------------------------- |
| user          | address                                  | The address of the user for whom to search available cars. |
| startDateTime | uint64                                   | The start date and time of the search period.              |
| endDateTime   | uint64                                   | The end date and time of the search period.                |
| searchParams  | struct RentalityCarToken.SearchCarParams | The search parameters for filtering available cars.        |

#### Return Values

| Name | Type                                               | Description                                                         |
| ---- | -------------------------------------------------- | ------------------------------------------------------------------- |
| [0]  | struct RentalityTripService.AvailableCarResponse[] | An array of available car information matching the search criteria. |

### checkInByHost

```solidity
function checkInByHost(uint256 tripId, uint64[] panelParams) public
```

Performs the check-in process by the host, updating the trip status and details.
Requirements:

- The caller must be the host of the trip.
- The trip must be in status Approved.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  | The ID of the trip to be checked in by the host.                                                          |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### checkInByGuest

```solidity
function checkInByGuest(uint256 tripId, uint64[] panelParams) public
```

Performs the check-in process by the guest, updating the trip status and details.
Requirements:

- The caller must be the guest of the trip.
- The trip must be in status CheckedInByHost.
- The trip params must match.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  | The ID of the trip to be checked in by the guest.                                                         |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### checkOutByGuest

```solidity
function checkOutByGuest(uint256 tripId, uint64[] panelParams) public
```

@dev Initiates the check-out process by the guest, updating trip status, and recording end details.
Requirements:

- Only the guest of the trip can check out.
- The trip must be in status CheckedInByGuest.
- The end odometer reading must be greater than or equal to the start odometer reading.
  @param tripId The ID of the trip to be checked out by the guest.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  |                                                                                                           |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### checkOutByHost

```solidity
function checkOutByHost(uint256 tripId, uint64[] panelParams) public
```

@dev Initiates the check-out process by the host, updating trip status, and validating end details.
Requirements: - Only the host of the trip can check out. - The trip must be in status CheckedOutByGuest. - End fuel level and odometer readings must match the recorded values at guest check-out.
@param tripId The ID of the trip to be checked out by the host.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  |                                                                                                           |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### finishTrip

```solidity
function finishTrip(uint256 tripId) public
```

\_Finalizes a trip, updating its status to Finished and calculating resolution amounts.
Requirements:

- The trip must be in status CheckedOutByHost.\_

#### Parameters

| Name   | Type    | Description                                                                                        |
| ------ | ------- | -------------------------------------------------------------------------------------------------- |
| tripId | uint256 | The ID of the trip to be finished. Emits a `TripStatusChanged` event with the new status Finished. |

### getTrip

```solidity
function getTrip(uint256 tripId) public view returns (struct RentalityTripService.Trip)
```

_Retrieves the details of a specific trip by its ID._

#### Parameters

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| tripId | uint256 | The ID of the trip to retrieve. |

#### Return Values

| Name | Type                             | Description                             |
| ---- | -------------------------------- | --------------------------------------- |
| [0]  | struct RentalityTripService.Trip | trip The details of the requested trip. |

### getAddressesByTripId

```solidity
function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress)
```

@dev Retrieves the addresses of the host and guest associated with a specific trip ID.
@param tripId The ID of the trip.
@return hostAddress The address of the host.
@return guestAddress The address of the guest.
