# Solidity API

## RentalityCarToken

ERC-721 token for representing cars in the Rentality platform.
This contract allows users to add, update, and manage information about cars for rental.
Cars can be listed, updated, and verified for geographic coordinates.

### CarInfo

```solidity
struct CarInfo {
  uint256 carId;
  string carVinNumber;
  bytes32 carVinNumberHash;
  address createdBy;
  string brand;
  string model;
  uint32 yearOfProduction;
  uint64 pricePerDayInUsdCents;
  uint64 securityDepositPerTripInUsdCents;
  uint8 engineType;
  uint64 milesIncludedPerDay;
  bool currentlyListed;
  bool geoVerified;
}
```

### CreateCarRequest

```solidity
struct CreateCarRequest {
  string tokenUri;
  string carVinNumber;
  string brand;
  string model;
  uint32 yearOfProduction;
  uint64 pricePerDayInUsdCents;
  uint64 securityDepositPerTripInUsdCents;
  uint64[] engineParams;
  uint8 engineType;
  uint64 milesIncludedPerDay;
  string locationAddress;
  string geoApiKey;
}
```

### UpdateCarInfoRequest

```solidity
struct UpdateCarInfoRequest {
  uint256 carId;
  uint64 pricePerDayInUsdCents;
  uint64 securityDepositPerTripInUsdCents;
  uint64[] engineParams;
  uint64 milesIncludedPerDay;
  bool currentlyListed;
}
```

### SearchCarParams

```solidity
struct SearchCarParams {
  string country;
  string state;
  string city;
  string brand;
  string model;
  uint32 yearOfProductionFrom;
  uint32 yearOfProductionTo;
  uint64 pricePerDayInUsdCentsFrom;
  uint64 pricePerDayInUsdCentsTo;
}
```

### CarAddedSuccess

```solidity
event CarAddedSuccess(uint256 CarId, string carVinNumber, address createdBy, uint64 pricePerDayInUsdCents, bool currentlyListed)
```

Event emitted when a new car is successfully added.

### CarUpdatedSuccess

```solidity
event CarUpdatedSuccess(uint256 carId, uint64 pricePerDayInUsdCents, bool currentlyListed)
```

Event emitted when a car's information is successfully updated.

### CarRemovedSuccess

```solidity
event CarRemovedSuccess(uint256 carId, string CarVinNumber, address removedBy)
```

Event emitted when a car is successfully removed.

### constructor

```solidity
constructor(address _geoServiceAddress, address _rentalityEngine) public
```

Constructor to initialize the RentalityCarToken contract.

#### Parameters

| Name                | Type    | Description                                      |
| ------------------- | ------- | ------------------------------------------------ |
| \_geoServiceAddress | address | The address of the RentalityGeoService contract. |
| \_rentalityEngine   | address |                                                  |

### totalSupply

```solidity
function totalSupply() public view returns (uint256)
```

Returns the total supply of cars.

#### Return Values

| Name | Type    | Description                             |
| ---- | ------- | --------------------------------------- |
| [0]  | uint256 | The total number of cars in the system. |

### getCarInfoById

```solidity
function getCarInfoById(uint256 carId) public view returns (struct RentalityCarToken.CarInfo)
```

Retrieves information about a car based on its ID.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type                             | Description                                              |
| ---- | -------------------------------- | -------------------------------------------------------- |
| [0]  | struct RentalityCarToken.CarInfo | A struct containing information about the specified car. |

### isUniqueVinNumber

```solidity
function isUniqueVinNumber(string carVinNumber) public view returns (bool)
```

Checks if a VIN number is unique among the listed cars.

#### Parameters

| Name         | Type   | Description                             |
| ------------ | ------ | --------------------------------------- |
| carVinNumber | string | The VIN number to check for uniqueness. |

#### Return Values

| Name | Type | Description                                        |
| ---- | ---- | -------------------------------------------------- |
| [0]  | bool | True if the VIN number is unique, false otherwise. |

### addCar

```solidity
function addCar(struct RentalityCarToken.CreateCarRequest request) public returns (uint256)
```

Adds a new car to the system with the provided information.

#### Parameters

| Name    | Type                                      | Description                                    |
| ------- | ----------------------------------------- | ---------------------------------------------- |
| request | struct RentalityCarToken.CreateCarRequest | The input parameters for creating the new car. |

#### Return Values

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| [0]  | uint256 | The ID of the newly added car. |

### verifyGeo

```solidity
function verifyGeo(uint256 carId) public
```

Verifies the geographic coordinates for a given car.

#### Parameters

| Name  | Type    | Description                  |
| ----- | ------- | ---------------------------- |
| carId | uint256 | The ID of the car to verify. |

### updateCarInfo

```solidity
function updateCarInfo(struct RentalityCarToken.UpdateCarInfoRequest request, string location, string geoApiKey) public
```

Updates the information for a specific car.

#### Parameters

| Name      | Type                                          | Description                                                                                         |
| --------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| request   | struct RentalityCarToken.UpdateCarInfoRequest | The input parameters for updating the car.                                                          |
| location  | string                                        | The location for verifying geographic coordinates. can be empty, for left old location information. |
| geoApiKey | string                                        | The API key for the geographic verification service. can be empty, if location param is empty.      |

### updateCarTokenUri

```solidity
function updateCarTokenUri(uint256 carId, string tokenUri) public
```

Updates the token URI associated with a specific car.

#### Parameters

| Name     | Type    | Description        |
| -------- | ------- | ------------------ |
| carId    | uint256 | The ID of the car. |
| tokenUri | string  | The new token URI. |

### burnCar

```solidity
function burnCar(uint256 carId) public
```

Burns a specific car token, removing it from the system.

#### Parameters

| Name  | Type    | Description                     |
| ----- | ------- | ------------------------------- |
| carId | uint256 | The ID of the car to be burned. |

### getAllCars

```solidity
function getAllCars() public view returns (struct RentalityCarToken.CarInfo[])
```

Retrieves information about all cars in the system.

#### Return Values

| Name | Type                               | Description                                     |
| ---- | ---------------------------------- | ----------------------------------------------- |
| [0]  | struct RentalityCarToken.CarInfo[] | An array containing information about all cars. |

### getAvailableCarsForUser

```solidity
function getAvailableCarsForUser(address user) public view returns (struct RentalityCarToken.CarInfo[])
```

Retrieves available cars for a specific user.

_Only used by main contract_

#### Parameters

| Name | Type    | Description              |
| ---- | ------- | ------------------------ |
| user | address | The address of the user. |

#### Return Values

| Name | Type                               | Description                                                        |
| ---- | ---------------------------------- | ------------------------------------------------------------------ |
| [0]  | struct RentalityCarToken.CarInfo[] | An array containing information about available cars for the user. |

### fetchAvailableCarsForUser

```solidity
function fetchAvailableCarsForUser(address user, struct RentalityCarToken.SearchCarParams searchCarParams) public view returns (struct RentalityCarToken.CarInfo[])
```

Fetches available cars for a specific user based on search parameters.

_Iterates through all cars to find those that are available for the user._

#### Parameters

| Name            | Type                                     | Description                                               |
| --------------- | ---------------------------------------- | --------------------------------------------------------- |
| user            | address                                  | The address of the user for whom to fetch available cars. |
| searchCarParams | struct RentalityCarToken.SearchCarParams | The parameters used to filter available cars.             |

#### Return Values

| Name | Type                               | Description                                                       |
| ---- | ---------------------------------- | ----------------------------------------------------------------- |
| [0]  | struct RentalityCarToken.CarInfo[] | An array of CarInfo representing the available cars for the user. |

### getCarsOwnedByUser

```solidity
function getCarsOwnedByUser(address user) public view returns (struct RentalityCarToken.CarInfo[])
```

Gets the cars owned by a specific user.

_Iterates through all cars to find those owned by the user._

#### Parameters

| Name | Type    | Description                                           |
| ---- | ------- | ----------------------------------------------------- |
| user | address | The address of the user for whom to fetch owned cars. |

#### Return Values

| Name | Type                               | Description                                                  |
| ---- | ---------------------------------- | ------------------------------------------------------------ |
| [0]  | struct RentalityCarToken.CarInfo[] | An array of CarInfo representing the cars owned by the user. |
