# Solidity API

## IRentalityGateway

This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.

_All functions in this interface are meant to be implemented by the Rentality Gateway contract._

### CreateTripRequest

```solidity
struct CreateTripRequest {
  uint256 carId;
  address host;
  uint64 startDateTime;
  uint64 endDateTime;
  string startLocation;
  string endLocation;
  uint64 totalDayPriceInUsdCents;
  uint64 taxPriceInUsdCents;
  uint64 depositInUsdCents;
  uint64 fuelPricePerGalInUsdCents;
  int256 ethToCurrencyRate;
  uint8 ethToCurrencyDecimals;
}
```

### ChatInfo

```solidity
struct ChatInfo {
  uint256 tripId;
  address guestAddress;
  string guestName;
  string guestPhotoUrl;
  address hostAddress;
  string hostName;
  string hostPhotoUrl;
  uint256 tripStatus;
  string carBrand;
  string carModel;
  uint32 carYearOfProduction;
  string carMetadataUrl;
}
```

### getCarServiceAddress

```solidity
function getCarServiceAddress() external view returns (address)
```

Get the address of the Car Service contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the Car Service contract. |

### updateCarService

```solidity
function updateCarService(address contractAddress) external
```

Update the Car Service contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the Car Service contract. |

### getCurrencyConverterServiceAddress

```solidity
function getCurrencyConverterServiceAddress() external view returns (address)
```

Get the address of the Currency Converter Service contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the Currency Converter Service contract. |

### updateCurrencyConverterService

```solidity
function updateCurrencyConverterService(address contractAddress) external
```

Update the Currency Converter Service contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the Currency Converter Service contract. |

### getTripServiceAddress

```solidity
function getTripServiceAddress() external view returns (address)
```

Get the address of the Trip Service contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the Trip Service contract. |

### updateTripService

```solidity
function updateTripService(address contractAddress) external
```

Update the Trip Service contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the Trip Service contract. |

### getUserServiceAddress

```solidity
function getUserServiceAddress() external view returns (address)
```

Get the address of the User Service contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the User Service contract. |

### updateUserService

```solidity
function updateUserService(address contractAddress) external
```

Update the User Service contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the User Service contract. |

### getRentalityPlatformAddress

```solidity
function getRentalityPlatformAddress() external view returns (address)
```

@notice Get the address of the Rentality Platform contract.
 @return The address of the Rentality Platform contract.

### updateRentalityPlatform

```solidity
function updateRentalityPlatform(address contractAddress) external
```

Update the Rentality Platform contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the Rentality Platform contract. |

### withdrawFromPlatform

```solidity
function withdrawFromPlatform(uint256 amount) external
```

Withdraw a specified amount of funds from the platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of funds to withdraw. |

### withdrawAllFromPlatform

```solidity
function withdrawAllFromPlatform() external
```

Withdraw all funds from the platform.

### getPlatformFeeInPPM

```solidity
function getPlatformFeeInPPM() external view returns (uint32)
```

Get the platform fee in parts per million (PPM).

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint32 | The platform fee in PPM. |

### setPlatformFeeInPPM

```solidity
function setPlatformFeeInPPM(uint32 valueInPPM) external
```

Set the platform fee in parts per million (PPM).

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| valueInPPM | uint32 | The new platform fee in PPM. |

### addCar

```solidity
function addCar(struct RentalityCarToken.CreateCarRequest request) external returns (uint256)
```

Add a new car to the platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| request | struct RentalityCarToken.CreateCarRequest | The request parameters for creating a new car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The ID of the newly added car. |

### updateCarInfo

```solidity
function updateCarInfo(struct RentalityCarToken.UpdateCarInfoRequest request) external
```

Update information for an existing car, without location.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| request | struct RentalityCarToken.UpdateCarInfoRequest | the Update car parameters |

### updateCarInfoWithLocation

```solidity
function updateCarInfoWithLocation(struct RentalityCarToken.UpdateCarInfoRequest request, string location, string geoApiKey) external
```

Update information for an existing car with location
This sets geo verification status to false.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| request | struct RentalityCarToken.UpdateCarInfoRequest | the Update car parameters |
| location | string | Single string that contains the car location |
| geoApiKey | string | the key to verify location by google geo api |

### getCarMetadataURI

```solidity
function getCarMetadataURI(uint256 carId) external view returns (string)
```

Get the metadata URI for a specific car.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | The metadata URI for the specified car. |

### getCarInfoById

```solidity
function getCarInfoById(uint256 carId) external view returns (struct RentalityCarToken.CarInfo)
```

Get information about a specific car by ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityCarToken.CarInfo | CarInfo structure containing details about the specified car. |

### getMyCars

```solidity
function getMyCars() external view returns (struct RentalityCarToken.CarInfo[])
```

Get information about all cars owned by the caller.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityCarToken.CarInfo[] | An array of CarInfo structures containing details about the caller's cars. |

### getTripsAsHost

```solidity
function getTripsAsHost() external view returns (struct RentalityTripService.Trip[])
```

Get information about all trips where the caller is the host.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip[] | An array of Trip structures containing details about trips where the caller is the host. |

### approveTripRequest

```solidity
function approveTripRequest(uint256 tripId) external
```

Approve a trip request by its ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to approve. |

### rejectTripRequest

```solidity
function rejectTripRequest(uint256 tripId) external
```

Reject a trip request by its ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to reject. |

### checkInByHost

```solidity
function checkInByHost(uint256 tripId, uint64 startFuelLevelInPermille, uint64 startOdometr) external
```

Perform check-in for a trip as the host.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to check in. |
| startFuelLevelInPermille | uint64 | The start fuel level in permille. |
| startOdometr | uint64 | The start odometer reading. |

### checkOutByHost

```solidity
function checkOutByHost(uint256 tripId, uint64 endFuelLevelInPermille, uint64 endOdometr) external
```

Perform check-out for a trip as the host.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to check out. |
| endFuelLevelInPermille | uint64 | The end fuel level in permille. |
| endOdometr | uint64 | The end odometer reading. |

### finishTrip

```solidity
function finishTrip(uint256 tripId) external
```

Finish a trip as the host.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to finish. |

### getAvailableCars

```solidity
function getAvailableCars() external view returns (struct RentalityCarToken.CarInfo[])
```

Get information about all available cars.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityCarToken.CarInfo[] | An array of CarInfo structures containing details about available cars. |

### searchAvailableCars

```solidity
function searchAvailableCars(uint64 startDateTime, uint64 endDateTime, struct RentalityCarToken.SearchCarParams searchParams) external view returns (struct RentalityCarToken.CarInfo[])
```

Search for available cars based on specified criteria.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startDateTime | uint64 | The start date and time of the trip. |
| endDateTime | uint64 | The end date and time of the trip. |
| searchParams | struct RentalityCarToken.SearchCarParams | Additional parameters for searching available cars. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityCarToken.CarInfo[] | An array of CarInfo structures containing details about available cars matching the criteria. |

### createTripRequest

```solidity
function createTripRequest(struct IRentalityGateway.CreateTripRequest request) external payable
```

Create a trip request.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| request | struct IRentalityGateway.CreateTripRequest | The request parameters for creating a new trip. |

### getTripsAsGuest

```solidity
function getTripsAsGuest() external view returns (struct RentalityTripService.Trip[])
```

Get information about all trips where the caller is the guest.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip[] | An array of Trip structures containing details about trips where the caller is the guest. |

### checkInByGuest

```solidity
function checkInByGuest(uint256 tripId, uint64 startFuelLevelInPermille, uint64 startOdometr) external
```

Perform check-in for a trip as the guest.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to check in. |
| startFuelLevelInPermille | uint64 | The start fuel level in permille. |
| startOdometr | uint64 | The start odometer reading. |

### checkOutByGuest

```solidity
function checkOutByGuest(uint256 tripId, uint64 endFuelLevelInPermille, uint64 endOdometr) external
```

Perform check-out for a trip as the guest.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to check out. |
| endFuelLevelInPermille | uint64 | The end fuel level in permille. |
| endOdometr | uint64 | The end odometer reading. |

### getTrip

```solidity
function getTrip(uint256 tripId) external view returns (struct RentalityTripService.Trip)
```

Get information about a specific trip.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityTripService.Trip | Trip structure containing details about the specified trip. |

### getAddressesByTripId

```solidity
function getAddressesByTripId(uint256 tripId) external view returns (address hostAddress, address guestAddress)
```

Get the addresses (host and guest) associated with a trip ID.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| hostAddress | address | The address of the host associated with the trip. |
| guestAddress | address | The address of the guest associated with the trip. |

### getTripContactInfo

```solidity
function getTripContactInfo(uint256 tripId) external view returns (string guestPhoneNumber, string hostPhoneNumber)
```

Get contact information for a trip.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| guestPhoneNumber | string | The phone number of the guest associated with the trip. |
| hostPhoneNumber | string | The phone number of the host associated with the trip. |

### setKYCInfo

```solidity
function setKYCInfo(string name, string surname, string mobilePhoneNumber, string profilePhoto, string licenseNumber, uint64 expirationDate) external
```

Set KYC (Know Your Customer) information for the caller.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the caller. |
| surname | string | The surname of the caller. |
| mobilePhoneNumber | string | The mobile phone number of the caller. |
| profilePhoto | string | The URL of the caller's profile photo. |
| licenseNumber | string | The driver's license number of the caller. |
| expirationDate | uint64 | The expiration date of the caller's driver's license. |

### getKYCInfo

```solidity
function getKYCInfo(address user) external view returns (struct RentalityUserService.KYCInfo)
```

Get KYC (Know Your Customer) information for a specific user.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityUserService.KYCInfo | KYCInfo structure containing details about the KYC information of the specified user. |

### getMyKYCInfo

```solidity
function getMyKYCInfo() external view returns (struct RentalityUserService.KYCInfo)
```

Get KYC (Know Your Customer) information for the caller.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityUserService.KYCInfo | KYCInfo structure containing details about the KYC information of the caller. |

