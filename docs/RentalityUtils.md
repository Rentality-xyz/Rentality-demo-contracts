# Solidity API

## RentalityUtils

### multiplier

```solidity
uint256 multiplier
```

### checkCoordinates

```solidity
function checkCoordinates(string locationLat, string locationLng, string northeastLat, string northeastLng, string southwestLat, string southwestLng) external pure returns (bool)
```

Checks if a set of coordinates falls within a specified bounding box.

#### Parameters

| Name         | Type   | Description                                            |
| ------------ | ------ | ------------------------------------------------------ |
| locationLat  | string | Latitude of the location to check.                     |
| locationLng  | string | Longitude of the location to check.                    |
| northeastLat | string | Latitude of the northeast corner of the bounding box.  |
| northeastLng | string | Longitude of the northeast corner of the bounding box. |
| southwestLat | string | Latitude of the southwest corner of the bounding box.  |
| southwestLng | string | Longitude of the southwest corner of the bounding box. |

#### Return Values

| Name | Type | Description                                                                   |
| ---- | ---- | ----------------------------------------------------------------------------- |
| [0]  | bool | Returns true if the coordinates are within the bounding box, false otherwise. |

### parseInt

```solidity
function parseInt(string _a) internal pure returns (int256)
```

Parses an integer from a string.

#### Parameters

| Name | Type   | Description                |
| ---- | ------ | -------------------------- |
| \_a  | string | The input string to parse. |

#### Return Values

| Name | Type   | Description                       |
| ---- | ------ | --------------------------------- |
| [0]  | int256 | Returns the parsed integer value. |

### indexOf

```solidity
function indexOf(bytes haystack, string needle) internal pure returns (uint256)
```

Finds the index of a substring in a given string.

#### Parameters

| Name     | Type   | Description                  |
| -------- | ------ | ---------------------------- |
| haystack | bytes  | The string to search within. |
| needle   | string | The substring to search for. |

#### Return Values

| Name | Type    | Description                                                                                           |
| ---- | ------- | ----------------------------------------------------------------------------------------------------- |
| [0]  | uint256 | Returns the index of the first occurrence of the substring, or the length of the string if not found. |

### toLower

```solidity
function toLower(string str) internal pure returns (string)
```

Converts a string to lowercase.

#### Parameters

| Name | Type   | Description                  |
| ---- | ------ | ---------------------------- |
| str  | string | The input string to convert. |

#### Return Values

| Name | Type   | Description                                        |
| ---- | ------ | -------------------------------------------------- |
| [0]  | string | Returns the lowercase version of the input string. |

### containWord

```solidity
function containWord(string where, string what) internal pure returns (bool found)
```

Checks if a string contains a specific word.

#### Parameters

| Name  | Type   | Description                  |
| ----- | ------ | ---------------------------- |
| where | string | The string to search within. |
| what  | string | The word to search for.      |

#### Return Values

| Name  | Type | Description                                         |
| ----- | ---- | --------------------------------------------------- |
| found | bool | Returns true if the word is found, false otherwise. |

### getHashFromString

```solidity
function getHashFromString(string str) internal pure returns (bytes32)
```

Generates a hash from a string.

#### Parameters

| Name | Type   | Description               |
| ---- | ------ | ------------------------- |
| str  | string | The input string to hash. |

#### Return Values

| Name | Type    | Description                                     |
| ---- | ------- | ----------------------------------------------- |
| [0]  | bytes32 | Returns the keccak256 hash of the input string. |

### getCeilDays

```solidity
function getCeilDays(uint64 startDateTime, uint64 endDateTime) public pure returns (uint64)
```

Calculates the ceiling of the division of two numbers.

#### Parameters

| Name          | Type   | Description                      |
| ------------- | ------ | -------------------------------- |
| startDateTime | uint64 | The numerator of the division.   |
| endDateTime   | uint64 | The denominator of the division. |

#### Return Values

| Name | Type   | Description                                                                |
| ---- | ------ | -------------------------------------------------------------------------- |
| [0]  | uint64 | Returns the result of the division rounded up to the nearest whole number. |

### populateChatInfo

```solidity
function populateChatInfo(struct RentalityTripService.Trip[] trips, contract RentalityUserService userService, contract RentalityCarToken carService) public view returns (struct IRentalityGateway.ChatInfo[])
```

Populates an array of chat information using data from trips, user service, and car service.

#### Parameters

| Name        | Type                               | Description                                    |
| ----------- | ---------------------------------- | ---------------------------------------------- |
| trips       | struct RentalityTripService.Trip[] | Array of RentalityTripService.Trip structures. |
| userService | contract RentalityUserService      | RentalityUserService contract instance.        |
| carService  | contract RentalityCarToken         | RentalityCarToken contract instance.           |

#### Return Values

| Name | Type                                | Description                                                  |
| ---- | ----------------------------------- | ------------------------------------------------------------ |
| [0]  | struct IRentalityGateway.ChatInfo[] | chatInfoList Array of IRentalityGateway.ChatInfo structures. |

### parseResponse

```solidity
function parseResponse(string response) public pure returns (struct RentalityGeoService.ParsedGeolocationData)
```

Parses a response string containing geolocation data.

#### Parameters

| Name     | Type   | Description                   |
| -------- | ------ | ----------------------------- |
| response | string | The response string to parse. |

#### Return Values

| Name | Type                                             | Description                                                                            |
| ---- | ------------------------------------------------ | -------------------------------------------------------------------------------------- |
| [0]  | struct RentalityGeoService.ParsedGeolocationData | result Parsed geolocation data in RentalityGeoService.ParsedGeolocationData structure. |

### splitString

```solidity
function splitString(string input) internal pure returns (string[])
```

Splits a string into an array of substrings based on a delimiter.

#### Parameters

| Name  | Type   | Description                |
| ----- | ------ | -------------------------- |
| input | string | The input string to split. |

#### Return Values

| Name | Type     | Description                |
| ---- | -------- | -------------------------- |
| [0]  | string[] | parts Array of substrings. |

### splitKeyValue

```solidity
function splitKeyValue(string input) internal pure returns (string[])
```

Splits a key-value pair string into an array of key and value.

#### Parameters

| Name  | Type   | Description                |
| ----- | ------ | -------------------------- |
| input | string | The input string to split. |

#### Return Values

| Name | Type     | Description                           |
| ---- | -------- | ------------------------------------- |
| [0]  | string[] | parts Array containing key and value. |

### compareStrings

```solidity
function compareStrings(string a, string b) internal pure returns (bool)
```

Compares two strings for equality.

#### Parameters

| Name | Type   | Description        |
| ---- | ------ | ------------------ |
| a    | string | The first string.  |
| b    | string | The second string. |

#### Return Values

| Name | Type | Description                                             |
| ---- | ---- | ------------------------------------------------------- |
| [0]  | bool | Returns true if the strings are equal, false otherwise. |

### urlEncode

```solidity
function urlEncode(string input) internal pure returns (string)
```

URL encodes a string.

#### Parameters

| Name  | Type   | Description                 |
| ----- | ------ | --------------------------- |
| input | string | The input string to encode. |

#### Return Values

| Name | Type   | Description                    |
| ---- | ------ | ------------------------------ |
| [0]  | string | output The URL-encoded string. |

### toBytes

```solidity
function toBytes(bytes32 _data) public pure returns (bytes)
```

_Converts a bytes32 data to a bytes array._

#### Parameters

| Name   | Type    | Description                        |
| ------ | ------- | ---------------------------------- |
| \_data | bytes32 | The input bytes32 data to convert. |

#### Return Values

| Name | Type  | Description                                                           |
| ---- | ----- | --------------------------------------------------------------------- |
| [0]  | bytes | Returns the packed representation of the input data as a bytes array. |

### isTripThatIntersect

```solidity
function isTripThatIntersect(contract RentalityTripService tripService, uint256 tripId, uint64 startDateTime, uint64 endDateTime) internal view returns (bool)
```

#### Parameters

| Name          | Type                          | Description                                |
| ------------- | ----------------------------- | ------------------------------------------ |
| tripService   | contract RentalityTripService |                                            |
| tripId        | uint256                       | The ID of the trip to check.               |
| startDateTime | uint64                        | The start date and time of the time range. |
| endDateTime   | uint64                        | The end date and time of the time range.   |

#### Return Values

| Name | Type | Description                                                                                                        |
| ---- | ---- | ------------------------------------------------------------------------------------------------------------------ |
| [0]  | bool | hasIntersectingTrips A boolean indicating whether the trip has intersecting trips within the specified time range. |

### getTripsThatIntersect

```solidity
function getTripsThatIntersect(contract RentalityTripService tripService, uint64 startDateTime, uint64 endDateTime) public view returns (struct RentalityTripService.Trip[])
```

#### Parameters

| Name          | Type                          | Description                                |
| ------------- | ----------------------------- | ------------------------------------------ |
| tripService   | contract RentalityTripService |                                            |
| startDateTime | uint64                        | The start date and time of the time range. |
| endDateTime   | uint64                        | The end date and time of the time range.   |

#### Return Values

| Name | Type                               | Description                                                                       |
| ---- | ---------------------------------- | --------------------------------------------------------------------------------- |
| [0]  | struct RentalityTripService.Trip[] | intersectingTrips An array of trips that intersect with the specified time range. |

### getTripsForCarThatIntersect

```solidity
function getTripsForCarThatIntersect(contract RentalityTripService tripService, uint256 carId, uint64 startDateTime, uint64 endDateTime) public view returns (struct RentalityTripService.Trip[])
```

@param carId The ID of the car to check.
@param startDateTime The start date and time of the time range.
@param endDateTime The end date and time of the time range.
@return trips An array of intersecting trips for the specified car within the specified time range.

### getTripsByGuest

```solidity
function getTripsByGuest(contract RentalityTripService tripService, address guest) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips associated with a specific guest address._

#### Parameters

| Name        | Type                          | Description               |
| ----------- | ----------------------------- | ------------------------- |
| tripService | contract RentalityTripService |                           |
| guest       | address                       | The address of the guest. |

#### Return Values

| Name | Type                               | Description                                                  |
| ---- | ---------------------------------- | ------------------------------------------------------------ |
| [0]  | struct RentalityTripService.Trip[] | trips An array of trips associated with the specified guest. |

### getTripsByHost

```solidity
function getTripsByHost(contract RentalityTripService tripService, address host) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips associated with a specific host address._

#### Parameters

| Name        | Type                          | Description              |
| ----------- | ----------------------------- | ------------------------ |
| tripService | contract RentalityTripService |                          |
| host        | address                       | The address of the host. |

#### Return Values

| Name | Type                               | Description                                                 |
| ---- | ---------------------------------- | ----------------------------------------------------------- |
| [0]  | struct RentalityTripService.Trip[] | trips An array of trips associated with the specified host. |

### getTripsByCar

```solidity
function getTripsByCar(contract RentalityTripService tripService, uint256 carId) public view returns (struct RentalityTripService.Trip[])
```

_Retrieves an array of trips associated with a specific car ID._

#### Parameters

| Name        | Type                          | Description        |
| ----------- | ----------------------------- | ------------------ |
| tripService | contract RentalityTripService |                    |
| carId       | uint256                       | The ID of the car. |

#### Return Values

| Name | Type                               | Description                                                   |
| ---- | ---------------------------------- | ------------------------------------------------------------- |
| [0]  | struct RentalityTripService.Trip[] | trips An array of trips associated with the specified car ID. |

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(uint8 eType, struct RentalityTripService.Trip tripInfo, contract RentalityEnginesService engineService) public returns (uint64, uint64)
```

@dev Calculates the resolved amount in USD cents for a trip.
@param tripInfo The information about the trip.

#### Return Values

| Name | Type   | Description                                                              |
| ---- | ------ | ------------------------------------------------------------------------ |
| [0]  | uint64 | Returns the resolved amounts for miles and fuel in USD cents as a tuple. |
| [1]  | uint64 |                                                                          |
