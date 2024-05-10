# Solidity API

## RentalityGeoMock

### setCarCoordinateValidity

```solidity
function setCarCoordinateValidity(uint256 carId, bool validity) external
```

Sets the validity of car coordinates for a specific car ID.

_Function: setCarCoordinateValidity_

#### Parameters

| Name     | Type    | Description                    |
| -------- | ------- | ------------------------------ |
| carId    | uint256 | The ID of the car.             |
| validity | bool    | The validity status to be set. |

### setCarCity

```solidity
function setCarCity(uint256 carId, string city) external
```

Sets the city information for a specific car ID.

_Function: setCarCity_

#### Parameters

| Name  | Type    | Description                     |
| ----- | ------- | ------------------------------- |
| carId | uint256 | The ID of the car.              |
| city  | string  | The city information to be set. |

### setCarState

```solidity
function setCarState(uint256 carId, string state) external
```

Sets the state information for a specific car ID.

_Function: setCarState_

#### Parameters

| Name  | Type    | Description                      |
| ----- | ------- | -------------------------------- |
| carId | uint256 | The ID of the car.               |
| state | string  | The state information to be set. |

### setCarCountry

```solidity
function setCarCountry(uint256 carId, string country) external
```

Sets the country information for a specific car ID.

_Function: setCarCountry_

#### Parameters

| Name    | Type    | Description                        |
| ------- | ------- | ---------------------------------- |
| carId   | uint256 | The ID of the car.                 |
| country | string  | The country information to be set. |

### executeRequest

```solidity
function executeRequest(string addr, string key, uint256 carId) external returns (bytes32)
```

Executes a mock request. Mock implementation, you can add your own logic if needed.

_Function: executeRequest_

#### Parameters

| Name  | Type    | Description                                 |
| ----- | ------- | ------------------------------------------- |
| addr  | string  | The address parameter for the mock request. |
| key   | string  | The key parameter for the mock request.     |
| carId | uint256 | The ID of the car.                          |

#### Return Values

| Name | Type    | Description                            |
| ---- | ------- | -------------------------------------- |
| [0]  | bytes32 | The car ID as bytes32 (mock response). |

### getCarCoordinateValidity

```solidity
function getCarCoordinateValidity(uint256 carId) external view returns (bool)
```

Retrieves the validity of car coordinates for a specific car ID.

_Function: getCarCoordinateValidity_

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description                             |
| ---- | ---- | --------------------------------------- |
| [0]  | bool | The validity status of car coordinates. |

### getCarCity

```solidity
function getCarCity(uint256 carId) external view returns (string)
```

Retrieves the city information for a specific car ID.

_Function: getCarCity_

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description           |
| ---- | ------ | --------------------- |
| [0]  | string | The city information. |

### getCarState

```solidity
function getCarState(uint256 carId) external view returns (string)
```

Retrieves the state information for a specific car ID.

_Function: getCarState_

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description            |
| ---- | ------ | ---------------------- |
| [0]  | string | The state information. |

### getCarCountry

```solidity
function getCarCountry(uint256 carId) external view returns (string)
```

Retrieves the country information for a specific car ID.

_Function: getCarCountry_

#### Parameters

| Name  | Type    | Description        |
| ----- | ------- | ------------------ |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type   | Description              |
| ---- | ------ | ------------------------ |
| [0]  | string | The country information. |
