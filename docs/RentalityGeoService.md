# Solidity API

## RentalityGeoService

This contract provides geolocation services using Chainlink oracles.

_It interacts with an external geolocation API and stores the results for cars._

### requestIdToCarId

```solidity
mapping(bytes32 => uint256) requestIdToCarId
```

Mapping to store the relationship between request ID and car ID.

### carIdToGeolocationResponse

```solidity
mapping(uint256 => string) carIdToGeolocationResponse
```

Mapping to store geolocation response for each car ID.

### carIdToParsedGeolocationData

```solidity
mapping(uint256 => struct RentalityGeoService.ParsedGeolocationData) carIdToParsedGeolocationData
```

Mapping to store parsed geolocation data for each car ID.

### ParsedGeolocationData

```solidity
struct ParsedGeolocationData {
  string status;
  bool validCoordinates;
  string locationLat;
  string locationLng;
  string northeastLat;
  string northeastLng;
  string southwestLat;
  string southwestLng;
  string city;
  string state;
  string country;
}
```

### constructor

```solidity
constructor(address linkToken, address chainLinkOracle) public
```

Constructor to initialize Chainlink settings.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| linkToken | address | The address of the LINK token contract. |
| chainLinkOracle | address | The address of the Chainlink oracle. |

### executeRequest

```solidity
function executeRequest(string addr, string key, uint256 carId) public returns (bytes32 requestId)
```

Function to execute a Chainlink request for geolocation data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | string | The address for geolocation lookup. |
| key | string | The API key for accessing the geolocation service. |
| carId | uint256 | The ID of the car for which geolocation is requested. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| requestId | bytes32 | The ID of the Chainlink request. |

### fulfill

```solidity
function fulfill(bytes32 _requestId, string _response) public
```

Function called by Chainlink when the request is fulfilled.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _requestId | bytes32 | The ID of the Chainlink request. |
| _response | string | The geolocation response from the API. |

### withdrawLink

```solidity
function withdrawLink() public
```

Function to withdraw LINK tokens from the contract (onlyOwner).

### parseGeoResponse

```solidity
function parseGeoResponse(uint256 carId) public
```

Function to parse the geolocation response and store parsed data.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car for which geolocation is parsed. |

### getCarCoordinateValidity

```solidity
function getCarCoordinateValidity(uint256 carId) public view returns (bool)
```

Function to get the validity of geolocation coordinates for a car.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | validCoordinates A boolean indicating the validity of coordinates. |

### getCarCity

```solidity
function getCarCity(uint256 carId) public view returns (string)
```

Function to get the city of geolocation for a car.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | city The city name. |

### getCarState

```solidity
function getCarState(uint256 carId) public view returns (string)
```

Function to get the state of geolocation for a car.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | state The state name. |

### getCarCountry

```solidity
function getCarCountry(uint256 carId) public view returns (string)
```

Function to get the country of geolocation for a car.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carId | uint256 | The ID of the car. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | country The country name. |

