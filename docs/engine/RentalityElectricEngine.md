# Solidity API

## RentalityElectricEngine

This contract extends ARentalityEngine and adds functionality specific to electric engines.

### ChargePriceScaleInUsdCents

```solidity
struct ChargePriceScaleInUsdCents {
  uint64 fromEmptyToTwenty;
  uint64 fromTwentyOneToFifty;
  uint64 fromFiftyOneToEighty;
  uint64 fromEightyOneToOneHundred;
}
```

### constructor

```solidity
constructor(address _userService) public
```

_Constructor to set the RentalityUserService address during deployment._

### setEType

```solidity
function setEType(uint8 _eType) public
```

_Sets the engine type. Only callable by an admin._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _eType | uint8 | The new engine type to be set. |

### addCar

```solidity
function addCar(uint256 carId, uint64[] params) public
```

_Adds a new electric car to the system with charge price scales._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the electric car. |
| params | uint64[] | An array of four uint64 values representing charge price scales. |

### updateCar

```solidity
function updateCar(uint256 carId, uint64[] params) public
```

_Updates charge price scales for an existing electric car in the system._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the electric car. |
| params | uint64[] | An array of four uint64 values representing updated charge price scales. |

### burnCar

```solidity
function burnCar(uint256 carId) public
```

_Removes an electric car from the system._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the electric car to be removed. |

### extraCosts

```solidity
function extraCosts(uint64[] params) public pure returns (uint64)
```

_Returns zero extra costs for electric cars._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | uint64[] | An array of uint64 values representing parameters (not used for electric engines). |

### getEngineData

```solidity
function getEngineData(uint256 carId) public view returns (struct RentalityElectricEngine.ChargePriceScaleInUsdCents)
```

_Retrieves charge price scales for a specific electric car._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the electric car. |

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(uint64[] _fuelPrices, uint64[] startParams, uint64[] endParams, uint256 carId, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays) public view returns (uint64, uint64)
```

_Calculates the resolve amount in USD cents for an electric car rental._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _fuelPrices | uint64[] | An array of uint64 values representing fuel prices (not used for electric engines). |
| startParams | uint64[] | An array of uint64 values representing the initial parameters of the rental. |
| endParams | uint64[] | An array of uint64 values representing the final parameters of the rental. |
| carId | uint256 | The unique identifier of the electric car. |
| milesIncludedPerDay | uint64 | The number of miles included per day in the rental. |
| pricePerDayInUsdCents | uint64 | The rental price per day in USD cents. |
| tripDays | uint64 | The total number of days in the rental trip. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | The total resolve amount and the fuel-specific resolve amount in USD cents. |
| [1] | uint64 |  |

### getFuelResolveAmountInUsdCents

```solidity
function getFuelResolveAmountInUsdCents(uint64 endFuelLevelInPercents, uint256 carId) public view returns (uint64)
```

_Calculates the resolve amount in USD cents based on the remaining charge of an electric car._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| endFuelLevelInPercents | uint64 | The final fuel level of the electric car in percentages. |
| carId | uint256 | The unique identifier of the electric car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | The fuel-specific resolve amount in USD cents. |

