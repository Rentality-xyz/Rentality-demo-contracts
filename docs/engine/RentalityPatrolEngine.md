# Solidity API

## RentalityPatrolEngine

This contract extends ARentalityEngine and adds functionality specific to patrol engines.

### PatrolEngine

```solidity
struct PatrolEngine {
  uint64 tankVolumeInGal;
  uint64 fuelPricePerGalInUsdCents;
}
```

### constructor

```solidity
constructor(address _userService) public
```

Constructor to set the RentalityUserService address during deployment.

### setEType

```solidity
function setEType(uint8 _eType) public
```

Sets the engine type. Only callable by an admin.

#### Parameters

| Name    | Type  | Description                    |
| ------- | ----- | ------------------------------ |
| \_eType | uint8 | The new engine type to be set. |

### addCar

```solidity
function addCar(uint256 carId, uint64[] params) public
```

Adds a new patrol car to the system with specified tank volume and fuel price.

#### Parameters

| Name   | Type     | Description                                                            |
| ------ | -------- | ---------------------------------------------------------------------- |
| carId  | uint256  | The unique identifier of the patrol car.                               |
| params | uint64[] | An array of two uint64 values representing tank volume and fuel price. |

### updateCar

```solidity
function updateCar(uint256 carId, uint64[] params) public
```

Updates the fuel price for an existing patrol car in the system.

#### Parameters

| Name   | Type     | Description                              |
| ------ | -------- | ---------------------------------------- |
| carId  | uint256  | The unique identifier of the patrol car. |
| params | uint64[] | An array containing the new fuel price.  |

### burnCar

```solidity
function burnCar(uint256 carId) public
```

Removes a patrol car from the system.

#### Parameters

| Name  | Type    | Description                                            |
| ----- | ------- | ------------------------------------------------------ |
| carId | uint256 | The unique identifier of the patrol car to be removed. |

### extraCosts

```solidity
function extraCosts(uint64[] params) public pure returns (uint64)
```

Returns zero extra costs for patrol cars.

#### Parameters

| Name   | Type     | Description                                                                      |
| ------ | -------- | -------------------------------------------------------------------------------- |
| params | uint64[] | An array of uint64 values representing parameters (not used for patrol engines). |

### getEngineData

```solidity
function getEngineData(uint256 carId) public view returns (struct RentalityPatrolEngine.PatrolEngine)
```

Retrieves patrol engine details for a specific patrol car.

#### Parameters

| Name  | Type    | Description                              |
| ----- | ------- | ---------------------------------------- |
| carId | uint256 | The unique identifier of the patrol car. |

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(uint64[] fuelPrices, uint64[] startParams, uint64[] endParams, uint256 carId, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays) public view returns (uint64, uint64)
```

Calculates the resolve amount in USD cents for a patrol car rental.

#### Parameters

| Name                  | Type     | Description                                                                       |
| --------------------- | -------- | --------------------------------------------------------------------------------- |
| fuelPrices            | uint64[] | An array of uint64 values representing fuel prices (not used for patrol engines). |
| startParams           | uint64[] | An array of uint64 values representing the initial parameters of the rental.      |
| endParams             | uint64[] | An array of uint64 values representing the final parameters of the rental.        |
| carId                 | uint256  | The unique identifier of the patrol car.                                          |
| milesIncludedPerDay   | uint64   | The number of miles included per day in the rental.                               |
| pricePerDayInUsdCents | uint64   | The rental price per day in USD cents.                                            |
| tripDays              | uint64   | The total number of days in the rental trip.                                      |

#### Return Values

| Name | Type   | Description                                                                 |
| ---- | ------ | --------------------------------------------------------------------------- |
| [0]  | uint64 | The total resolve amount and the fuel-specific resolve amount in USD cents. |
| [1]  | uint64 |                                                                             |

### getFuelResolveAmountInUsdCents

```solidity
function getFuelResolveAmountInUsdCents(uint64 endFuelLevelInPercents, uint64 startFuelLevelInPercents, uint64 tankVolume, uint64 fuelPricePerGalInUsdCents) public pure returns (uint64)
```

Calculates the resolve amount in USD cents based on fuel consumption for a patrol car.

#### Parameters

| Name                      | Type   | Description                                              |
| ------------------------- | ------ | -------------------------------------------------------- |
| endFuelLevelInPercents    | uint64 | The final fuel level of the patrol car in percentages.   |
| startFuelLevelInPercents  | uint64 | The initial fuel level of the patrol car in percentages. |
| tankVolume                | uint64 | The tank volume of the patrol car in gallons.            |
| fuelPricePerGalInUsdCents | uint64 | The fuel price per gallon in USD cents.                  |

#### Return Values

| Name | Type   | Description                                    |
| ---- | ------ | ---------------------------------------------- |
| [0]  | uint64 | The fuel-specific resolve amount in USD cents. |
