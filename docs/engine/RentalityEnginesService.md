# Solidity API

## RentalityEnginesService

This contract allows the addition, update, and interaction with various Rentality engines.

### Overflow

```solidity
error Overflow()
```

### constructor

```solidity
constructor(address _userService, address[] engineServices) public
```

Constructor to initialize the RentalityEnginesService contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _userService | address | The address of the RentalityUserService contract. |
| engineServices | address[] | An array of addresses representing existing engine contracts. |

### onlyAdmin

```solidity
modifier onlyAdmin()
```

Modifier to restrict access to only administrators.

### onlyManager

```solidity
modifier onlyManager()
```

Modifier to restrict access to only managers.

### addEngineService

```solidity
function addEngineService(address engineService) public
```

Adds a new engine service contract to the system.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| engineService | address | The address of the new engine service contract. |

### updateEngineService

```solidity
function updateEngineService(address engineService, uint8 eType) public
```

Updates an existing engine service contract in the system.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| engineService | address | The address of the updated engine service contract. |
| eType | uint8 | The engine type associated with the contract. |

### getEngineAddressById

```solidity
function getEngineAddressById(uint8 eType) public view returns (address)
```

Retrieves the address of an engine contract based on its engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eType | uint8 | The engine type for which to retrieve the address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the specified engine contract. |

### addCar

```solidity
function addCar(uint256 carId, uint8 eType, uint64[] params) public
```

Adds a new car to the system using a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the car. |
| eType | uint8 | The engine type associated with the car. |
| params | uint64[] | An array of parameters required for adding the car. |

### updateCar

```solidity
function updateCar(uint256 carId, uint8 eType, uint64[] params) public
```

Updates an existing car in the system using a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the car. |
| eType | uint8 | The engine type associated with the car. |
| params | uint64[] | An array of parameters required for updating the car. |

### burnCar

```solidity
function burnCar(uint256 carId, uint8 eType) public
```

Removes a car from the system using a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The unique identifier of the car. |
| eType | uint8 | The engine type associated with the car. |

### verifyResourcePrice

```solidity
function verifyResourcePrice(uint64[] prices, uint8 eType) public view
```

Verifies resource prices for a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| prices | uint64[] | An array of uint64 values representing resource prices. |
| eType | uint8 | The engine type for which to verify the resource prices. |

### verifyStartParams

```solidity
function verifyStartParams(uint64[] params, uint8 eType) public
```

Verifies the start parameters for a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | uint64[] | An array of uint64 values representing start parameters. |
| eType | uint8 | The engine type for which to verify the start parameters. |

### verifyEndParams

```solidity
function verifyEndParams(uint64[] startParams, uint64[] endParams, uint8 eType) public
```

Verifies the end parameters for a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startParams | uint64[] | An array of uint64 values representing start parameters. |
| endParams | uint64[] | An array of uint64 values representing end parameters. |
| eType | uint8 | The engine type for which to verify the end parameters. |

### compareParams

```solidity
function compareParams(uint64[] startParams, uint64[] endParams, uint8 eType) public view
```

Compares parameters for a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startParams | uint64[] | An array of uint64 values representing start parameters. |
| endParams | uint64[] | An array of uint64 values representing end parameters. |
| eType | uint8 | The engine type for which to compare the parameters. |

### getPanelParamsAmount

```solidity
function getPanelParamsAmount(uint8 eType) public returns (uint256)
```

Retrieves the number of parameters expected by the panel for a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eType | uint8 | The engine type for which to get the panel parameters amount. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of parameters expected by the panel. |

### extraCosts

```solidity
function extraCosts(uint8 eType, uint64[] params) public returns (uint64)
```

Computes extra costs for a specific engine type.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eType | uint8 | The engine type for which to compute extra costs. |
| params | uint64[] | An array of uint64 values representing parameters. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | The computed extra costs in USD cents. |

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(uint8 engineType, uint64[] fuelPrices, uint64[] startParams, uint64[] endParams, uint256 carId, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays) public returns (uint64, uint64)
```

Computes the resolve amount in USD cents for a specific engine type and car rental.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| engineType | uint8 | The engine type associated with the car. |
| fuelPrices | uint64[] | An array of uint64 values representing fuel prices. |
| startParams | uint64[] | An array of uint64 values representing the initial parameters of the rental. |
| endParams | uint64[] | An array of uint64 values representing the final parameters of the rental. |
| carId | uint256 | The unique identifier of the car. |
| milesIncludedPerDay | uint64 | The number of miles included per day in the rental. |
| pricePerDayInUsdCents | uint64 | The rental price per day in USD cents. |
| tripDays | uint64 | The total number of days in the rental trip. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint64 | The total resolve amount and the fuel-specific resolve amount in USD cents. |
| [1] | uint64 |  |

