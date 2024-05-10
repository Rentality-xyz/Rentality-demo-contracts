# Solidity API

## RentalityGateway

The main gateway contract that connects various services in the Rentality platform.
Users can interact with the car service, trip service, user service, and payment service through this gateway.
Admins can update the addresses of connected services.
Hosts and guests can perform actions related to car rentals and trips.

### constructor

```solidity
constructor(address carServiceAddress, address currencyConverterServiceAddress, address tripServiceAddress, address userServiceAddress, address rentalityPlatformAddress, address paymentServiceAddress) public
```

#### Parameters

| Name                            | Type    | Description                                             |
| ------------------------------- | ------- | ------------------------------------------------------- |
| carServiceAddress               | address | The address of the RentalityCarToken contract.          |
| currencyConverterServiceAddress | address | The address of the RentalityCurrencyConverter contract. |
| tripServiceAddress              | address | The address of the RentalityTripService contract.       |
| userServiceAddress              | address | The address of the RentalityUserService contract.       |
| rentalityPlatformAddress        | address | The address of the RentalityPlatform contract.          |
| paymentServiceAddress           | address | The address of the RentalityPaymentService contract.    |

### onlyAdmin

```solidity
modifier onlyAdmin()
```

Ensures that the caller is either an admin, the contract owner, or an admin from the origin transaction.

### onlyHost

```solidity
modifier onlyHost()
```

Ensures that the caller is a host.

### onlyGuest

```solidity
modifier onlyGuest()
```

Ensures that the caller is a guest.

### onlyHostOrGuest

```solidity
modifier onlyHostOrGuest()
```

Ensures that the caller is either a host or a guest.

### getCarServiceAddress

```solidity
function getCarServiceAddress() public view returns (address)
```

Retrieves the address of the RentalityCarToken contract.

#### Return Values

| Name | Type    | Description                                    |
| ---- | ------- | ---------------------------------------------- |
| [0]  | address | The address of the RentalityCarToken contract. |

### updateCarService

```solidity
function updateCarService(address contractAddress) public
```

Updates the address of the RentalityCarToken contract. Only callable by admins.

#### Parameters

| Name            | Type    | Description                                        |
| --------------- | ------- | -------------------------------------------------- |
| contractAddress | address | The new address of the RentalityCarToken contract. |

### getRentalityPlatformAddress

```solidity
function getRentalityPlatformAddress() public view returns (address)
```

Retrieves the address of the RentalityPlatform contract.

#### Return Values

| Name | Type    | Description                                    |
| ---- | ------- | ---------------------------------------------- |
| [0]  | address | The address of the RentalityPlatform contract. |

### updateRentalityPlatform

```solidity
function updateRentalityPlatform(address contractAddress) public
```

Updates the address of the RentalityPlatform contract. Only callable by admins.

#### Parameters

| Name            | Type    | Description                                        |
| --------------- | ------- | -------------------------------------------------- |
| contractAddress | address | The new address of the RentalityPlatform contract. |

### getCurrencyConverterServiceAddress

```solidity
function getCurrencyConverterServiceAddress() public view returns (address)
```

Retrieves the address of the RentalityCurrencyConverter contract.

#### Return Values

| Name | Type    | Description                                             |
| ---- | ------- | ------------------------------------------------------- |
| [0]  | address | The address of the RentalityCurrencyConverter contract. |

### updateCurrencyConverterService

```solidity
function updateCurrencyConverterService(address contractAddress) public
```

Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.

#### Parameters

| Name            | Type    | Description                                                 |
| --------------- | ------- | ----------------------------------------------------------- |
| contractAddress | address | The new address of the RentalityCurrencyConverter contract. |

### getTripServiceAddress

```solidity
function getTripServiceAddress() public view returns (address)
```

Retrieves the address of the RentalityTripService contract.

#### Return Values

| Name | Type    | Description                                       |
| ---- | ------- | ------------------------------------------------- |
| [0]  | address | The address of the RentalityTripService contract. |

### updateTripService

```solidity
function updateTripService(address contractAddress) public
```

Updates the address of the RentalityTripService contract. Only callable by admins.

#### Parameters

| Name            | Type    | Description                                           |
| --------------- | ------- | ----------------------------------------------------- |
| contractAddress | address | The new address of the RentalityTripService contract. |

### getUserServiceAddress

```solidity
function getUserServiceAddress() public view returns (address)
```

Retrieves the address of the RentalityUserService contract.

#### Return Values

| Name | Type    | Description                                       |
| ---- | ------- | ------------------------------------------------- |
| [0]  | address | The address of the RentalityUserService contract. |

### updateUserService

```solidity
function updateUserService(address contractAddress) public
```

Updates the address of the RentalityUserService contract. Only callable by admins.

#### Parameters

| Name            | Type    | Description                                           |
| --------------- | ------- | ----------------------------------------------------- |
| contractAddress | address | The new address of the RentalityUserService contract. |

### getPlatformFeeInPPM

```solidity
function getPlatformFeeInPPM() public view returns (uint32)
```

Retrieves the platform fee in parts per million (PPM).

#### Return Values

| Name | Type   | Description              |
| ---- | ------ | ------------------------ |
| [0]  | uint32 | The platform fee in PPM. |

### setPlatformFeeInPPM

```solidity
function setPlatformFeeInPPM(uint32 valueInPPM) public
```

Sets the platform fee in parts per million (PPM). Only callable by admins.

#### Parameters

| Name       | Type   | Description                        |
| ---------- | ------ | ---------------------------------- |
| valueInPPM | uint32 | The new platform fee value in PPM. |

### withdrawFromPlatform

```solidity
function withdrawFromPlatform(uint256 amount) public
```

Withdraws the specified amount from the RentalityPlatform contract.

#### Parameters

| Name   | Type    | Description             |
| ------ | ------- | ----------------------- |
| amount | uint256 | The amount to withdraw. |

### withdrawAllFromPlatform

```solidity
function withdrawAllFromPlatform() public
```

Withdraws the entire balance from the RentalityPlatform contract.

### getCarInfoById

```solidity
function getCarInfoById(uint256 carId) public view returns (struct RentalityCarToken.CarInfo)
```

Retrieves information about a car by its ID.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type                             | Description                  |
| ---- | -------------------------------- | ---------------------------- |
| [0]  | struct RentalityCarToken.CarInfo | Car information as a struct. |

### getCarMetadataURI

```solidity
function getCarMetadataURI(uint256 carId) public view returns (string)
```

Retrieves the metadata URI of a car by its ID.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description                  |
| ---- | ------ | ---------------------------- |
| [0]  | string | The metadata URI of the car. |

### addCar

```solidity
function addCar(struct RentalityCarToken.CreateCarRequest request) public returns (uint256)
```

Adds a new car using the provided request. Grants host role to the caller if not already a host.

#### Parameters

| Name    | Type                                      | Description                             |
| ------- | ----------------------------------------- | --------------------------------------- |
| request | struct RentalityCarToken.CreateCarRequest | The request containing car information. |

#### Return Values

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| [0]  | uint256 | The ID of the newly added car. |

### updateCarInfo

```solidity
function updateCarInfo(struct RentalityCarToken.UpdateCarInfoRequest request) public
```

Updates the information of a car. Only callable by hosts.

#### Parameters

| Name    | Type                                          | Description                                     |
| ------- | --------------------------------------------- | ----------------------------------------------- |
| request | struct RentalityCarToken.UpdateCarInfoRequest | The request containing updated car information. |

### updateCarInfoWithLocation

```solidity
function updateCarInfoWithLocation(struct RentalityCarToken.UpdateCarInfoRequest request, string location, string geoApiKey) public
```

Updates the information of a car, including location details. Only callable by hosts.

#### Parameters

| Name      | Type                                          | Description                                     |
| --------- | --------------------------------------------- | ----------------------------------------------- |
| request   | struct RentalityCarToken.UpdateCarInfoRequest | The request containing updated car information. |
| location  | string                                        | The new location of the car.                    |
| geoApiKey | string                                        | The API key for geocoding purposes.             |

### updateCarTokenUri

```solidity
function updateCarTokenUri(uint256 carId, string tokenUri) public
```

Updates the token URI of a car. Only callable by hosts.

#### Parameters

| Name     | Type    | Description                  |
| -------- | ------- | ---------------------------- |
| carId    | uint256 | The ID of the car to update. |
| tokenUri | string  | The new token URI.           |

### burnCar

```solidity
function burnCar(uint256 carId) public
```

Burns (disables) a car. Only callable by hosts.

#### Parameters

| Name  | Type    | Description                |
| ----- | ------- | -------------------------- |
| carId | uint256 | The ID of the car to burn. |

### getAllCars

```solidity
function getAllCars() public view returns (struct RentalityCarToken.CarInfo[])
```

Retrieves information about all cars.

#### Return Values

| Name | Type                               | Description                  |
| ---- | ---------------------------------- | ---------------------------- |
| [0]  | struct RentalityCarToken.CarInfo[] | An array of car information. |

### getAvailableCars

```solidity
function getAvailableCars() public view returns (struct RentalityCarToken.CarInfo[])
```

Retrieves information about available cars.

#### Return Values

| Name | Type                               | Description                            |
| ---- | ---------------------------------- | -------------------------------------- |
| [0]  | struct RentalityCarToken.CarInfo[] | An array of available car information. |

### getAvailableCarsForUser

```solidity
function getAvailableCarsForUser(address user) public view returns (struct RentalityCarToken.CarInfo[])
```

Retrieves information about available cars for a specific user.

#### Parameters

| Name | Type    | Description              |
| ---- | ------- | ------------------------ |
| user | address | The address of the user. |

#### Return Values

| Name | Type                               | Description                                                   |
| ---- | ---------------------------------- | ------------------------------------------------------------- |
| [0]  | struct RentalityCarToken.CarInfo[] | An array of available car information for the specified user. |

### searchAvailableCars

```solidity
function searchAvailableCars(uint64 startDateTime, uint64 endDateTime, struct RentalityCarToken.SearchCarParams searchParams) public view returns (struct RentalityTripService.AvailableCarResponse[])
```

Searches for available cars based on specified criteria.

#### Parameters

| Name          | Type                                     | Description                            |
| ------------- | ---------------------------------------- | -------------------------------------- |
| startDateTime | uint64                                   | The start date and time of the search. |
| endDateTime   | uint64                                   | The end date and time of the search.   |
| searchParams  | struct RentalityCarToken.SearchCarParams | Additional search parameters.          |

#### Return Values

| Name | Type                                               | Description                                                        |
| ---- | -------------------------------------------------- | ------------------------------------------------------------------ |
| [0]  | struct RentalityTripService.AvailableCarResponse[] | An array of available car information meeting the search criteria. |

### searchAvailableCarsForUser

```solidity
function searchAvailableCarsForUser(address user, uint64 startDateTime, uint64 endDateTime, struct RentalityCarToken.SearchCarParams searchParams) public view returns (struct RentalityTripService.AvailableCarResponse[])
```

Searches for available cars for a specific user based on specified criteria.

#### Parameters

| Name          | Type                                     | Description                            |
| ------------- | ---------------------------------------- | -------------------------------------- |
| user          | address                                  | The address of the user.               |
| startDateTime | uint64                                   | The start date and time of the search. |
| endDateTime   | uint64                                   | The end date and time of the search.   |
| searchParams  | struct RentalityCarToken.SearchCarParams | Additional search parameters.          |

#### Return Values

| Name | Type                                               | Description                                                                               |
| ---- | -------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [0]  | struct RentalityTripService.AvailableCarResponse[] | An array of available car information meeting the search criteria for the specified user. |

### getMyCars

```solidity
function getMyCars() public view returns (struct RentalityCarToken.CarInfo[])
```

Retrieves information about cars owned by the caller.

#### Return Values

| Name | Type                               | Description                                      |
| ---- | ---------------------------------- | ------------------------------------------------ |
| [0]  | struct RentalityCarToken.CarInfo[] | An array of car information owned by the caller. |

### createTripRequest

```solidity
function createTripRequest(struct IRentalityGateway.CreateTripRequest request) public payable
```

Creates a trip request. Callable by users with payment.

#### Parameters

| Name    | Type                                       | Description               |
| ------- | ------------------------------------------ | ------------------------- |
| request | struct IRentalityGateway.CreateTripRequest | The trip request details. |

### getTripContactInfo

```solidity
function getTripContactInfo(uint256 tripId) public view returns (string guestPhoneNumber, string hostPhoneNumber)
```

Retrieves contact information for a trip. Only callable by hosts or guests.

#### Parameters

| Name   | Type    | Description         |
| ------ | ------- | ------------------- |
| tripId | uint256 | The ID of the trip. |

#### Return Values

| Name             | Type   | Description |
| ---------------- | ------ | ----------- |
| guestPhoneNumber | string |             |
| hostPhoneNumber  | string |             |

### approveTripRequest

```solidity
function approveTripRequest(uint256 tripId) public
```

Approves a trip request. Only callable by hosts.

#### Parameters

| Name   | Type    | Description                    |
| ------ | ------- | ------------------------------ |
| tripId | uint256 | The ID of the trip to approve. |

### rejectTripRequest

```solidity
function rejectTripRequest(uint256 tripId) public
```

Rejects a trip request. Only callable by hosts.

#### Parameters

| Name   | Type    | Description                   |
| ------ | ------- | ----------------------------- |
| tripId | uint256 | The ID of the trip to reject. |

### checkInByHost

```solidity
function checkInByHost(uint256 tripId, uint64[] panelParams) public
```

Performs check-in by the host for a trip.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  | The ID of the trip.                                                                                       |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### checkInByGuest

```solidity
function checkInByGuest(uint256 tripId, uint64[] panelParams) public
```

Performs check-in by the guest for a trip.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  | The ID of the trip.                                                                                       |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### checkOutByGuest

```solidity
function checkOutByGuest(uint256 tripId, uint64[] panelParams) public
```

Performs check-out by the guest for a trip.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  | The ID of the trip.                                                                                       |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### checkOutByHost

```solidity
function checkOutByHost(uint256 tripId, uint64[] panelParams) public
```

Performs check-out by the host for a trip.

#### Parameters

| Name        | Type     | Description                                                                                               |
| ----------- | -------- | --------------------------------------------------------------------------------------------------------- |
| tripId      | uint256  | The ID of the trip.                                                                                       |
| panelParams | uint64[] | An array representing parameters related to fuel, odometer, and other relevant details depends on engine. |

### finishTrip

```solidity
function finishTrip(uint256 tripId) public
```

Finishes a trip. Only callable by RentalityPlatform.

#### Parameters

| Name   | Type    | Description                   |
| ------ | ------- | ----------------------------- |
| tripId | uint256 | The ID of the trip to finish. |

### getTrip

```solidity
function getTrip(uint256 tripId) public view returns (struct RentalityTripService.Trip)
```

Retrieves information about a trip by ID.

#### Parameters

| Name   | Type    | Description         |
| ------ | ------- | ------------------- |
| tripId | uint256 | The ID of the trip. |

#### Return Values

| Name | Type                             | Description       |
| ---- | -------------------------------- | ----------------- |
| [0]  | struct RentalityTripService.Trip | Trip information. |

### getTripsAsGuest

```solidity
function getTripsAsGuest() public view returns (struct RentalityTripService.Trip[])
```

Retrieves information about trips where the caller is the guest.

#### Return Values

| Name | Type                               | Description                   |
| ---- | ---------------------------------- | ----------------------------- |
| [0]  | struct RentalityTripService.Trip[] | An array of trip information. |

### getTripsByGuest

```solidity
function getTripsByGuest(address guest) public view returns (struct RentalityTripService.Trip[])
```

Retrieves information about trips where the specified user is the guest.

#### Parameters

| Name  | Type    | Description               |
| ----- | ------- | ------------------------- |
| guest | address | The address of the guest. |

#### Return Values

| Name | Type                               | Description                                           |
| ---- | ---------------------------------- | ----------------------------------------------------- |
| [0]  | struct RentalityTripService.Trip[] | An array of trip information for the specified guest. |

### getTripsAsHost

```solidity
function getTripsAsHost() public view returns (struct RentalityTripService.Trip[])
```

Retrieves information about trips where the caller is the host.

#### Return Values

| Name | Type                               | Description                   |
| ---- | ---------------------------------- | ----------------------------- |
| [0]  | struct RentalityTripService.Trip[] | An array of trip information. |

### getTripsByHost

```solidity
function getTripsByHost(address host) public view returns (struct RentalityTripService.Trip[])
```

Retrieves information about trips where the specified user is the host.

#### Parameters

| Name | Type    | Description              |
| ---- | ------- | ------------------------ |
| host | address | The address of the host. |

#### Return Values

| Name | Type                               | Description                                          |
| ---- | ---------------------------------- | ---------------------------------------------------- |
| [0]  | struct RentalityTripService.Trip[] | An array of trip information for the specified host. |

### getTripsByCar

```solidity
function getTripsByCar(uint256 carId) public view returns (struct RentalityTripService.Trip[])
```

Retrieves information about trips for a specific car.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type                               | Description                                         |
| ---- | ---------------------------------- | --------------------------------------------------- |
| [0]  | struct RentalityTripService.Trip[] | An array of trip information for the specified car. |

### setKYCInfo

```solidity
function setKYCInfo(string name, string surname, string mobilePhoneNumber, string profilePhoto, string licenseNumber, uint64 expirationDate) public
```

Sets Know Your Customer (KYC) information for the caller.

#### Parameters

| Name              | Type   | Description                                |
| ----------------- | ------ | ------------------------------------------ |
| name              | string | The name of the user.                      |
| surname           | string | The surname of the user.                   |
| mobilePhoneNumber | string | The mobile phone number of the user.       |
| profilePhoto      | string | The URL of the user's profile photo.       |
| licenseNumber     | string | The user's license number.                 |
| expirationDate    | uint64 | The expiration date of the user's license. |

### getKYCInfo

```solidity
function getKYCInfo(address user) external view returns (struct RentalityUserService.KYCInfo)
```

Retrieves KYC information for the specified user.

#### Parameters

| Name | Type    | Description              |
| ---- | ------- | ------------------------ |
| user | address | The address of the user. |

#### Return Values

| Name | Type                                | Description                             |
| ---- | ----------------------------------- | --------------------------------------- |
| [0]  | struct RentalityUserService.KYCInfo | KYC information for the specified user. |

### getMyKYCInfo

```solidity
function getMyKYCInfo() external view returns (struct RentalityUserService.KYCInfo)
```

Retrieves KYC information for the caller.

#### Return Values

| Name | Type                                | Description                     |
| ---- | ----------------------------------- | ------------------------------- |
| [0]  | struct RentalityUserService.KYCInfo | KYC information for the caller. |

### getChatInfoForHost

```solidity
function getChatInfoForHost() public view returns (struct IRentalityGateway.ChatInfo[])
```

Retrieves chat information for the caller acting as a host.

#### Return Values

| Name | Type                                | Description                   |
| ---- | ----------------------------------- | ----------------------------- |
| [0]  | struct IRentalityGateway.ChatInfo[] | An array of chat information. |

### getChatInfoForGuest

```solidity
function getChatInfoForGuest() public view returns (struct IRentalityGateway.ChatInfo[])
```

Retrieves chat information for the caller acting as a guest.

#### Return Values

| Name | Type                                | Description                   |
| ---- | ----------------------------------- | ----------------------------- |
| [0]  | struct IRentalityGateway.ChatInfo[] | An array of chat information. |
