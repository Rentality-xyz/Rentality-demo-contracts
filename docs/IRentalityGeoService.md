# Solidity API

## IRentalityGeoService

This contract defines the interface for the Rentality Geo Service, which provides geo-verification for cars info in the Rentality platform.

_All functions in this interface are meant to be implemented by the Rentality Geo Service contract._

### executeRequest

```solidity
function executeRequest(string addr, string key, uint256 carId) external returns (bytes32)
```

Execute a request to verify geo-related information.

#### Parameters

| Name  | Type    | Description                                                       |
| ----- | ------- | ----------------------------------------------------------------- |
| addr  | string  | The address for the geo-related request.                          |
| key   | string  | The key for the geo-related request.                              |
| carId | uint256 | The ID of the car for which geo-related information is requested. |

#### Return Values

| Name | Type    | Description                                                            |
| ---- | ------- | ---------------------------------------------------------------------- |
| [0]  | bytes32 | A bytes32 value representing the requestId of the geo-related request. |

### getCarCoordinateValidity

```solidity
function getCarCoordinateValidity(uint256 carId) external view returns (bool)
```

Get the validity of the coordinates for a specific car.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description                                                 |
| ---- | ---- | ----------------------------------------------------------- |
| [0]  | bool | A boolean indicating the validity of the car's coordinates. |

### getCarCity

```solidity
function getCarCity(uint256 carId) external view returns (string)
```

Get the city of a specific car.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description                                             |
| ---- | ------ | ------------------------------------------------------- |
| [0]  | string | A string representing the city associated with the car. |

### getCarState

```solidity
function getCarState(uint256 carId) external view returns (string)
```

Get the state of a specific car.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description                                              |
| ---- | ------ | -------------------------------------------------------- |
| [0]  | string | A string representing the state associated with the car. |

### getCarCountry

```solidity
function getCarCountry(uint256 carId) external view returns (string)
```

Get the country of a specific car.

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description                                                |
| ---- | ------ | ---------------------------------------------------------- |
| [0]  | string | A string representing the country associated with the car. |
