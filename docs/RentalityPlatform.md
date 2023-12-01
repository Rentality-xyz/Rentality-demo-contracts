# Solidity API

## RentalityPlatform

This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.

_It allows updating service contracts, creating and managing trips, handling payments, and more._

### constructor

```solidity
constructor(address carServiceAddress, address currencyConverterServiceAddress, address tripServiceAddress, address userServiceAddress, address paymentServiceAddress) public
```

Constructor to initialize the RentalityPlatform with service contract addresses.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| carServiceAddress | address | The address of the RentalityCarToken contract. |
| currencyConverterServiceAddress | address | The address of the RentalityCurrencyConverter contract. |
| tripServiceAddress | address | The address of the RentalityTripService contract. |
| userServiceAddress | address | The address of the RentalityUserService contract. |
| paymentServiceAddress | address | The address of the RentalityPaymentService contract. |

### onlyAdmin

```solidity
modifier onlyAdmin()
```

_Modifier to restrict access to admin users only._

### getCarServiceAddress

```solidity
function getCarServiceAddress() public view returns (address)
```

Get the address of the Car service on the Rentality platform.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the Car service. |

### updateCarService

```solidity
function updateCarService(address contractAddress) public
```

Update the address of the Car service on the Rentality platform.

_This function can only be called by the platform admin._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the Car service. |

### getCurrencyConverterServiceAddress

```solidity
function getCurrencyConverterServiceAddress() public view returns (address)
```

Get the address of the currency converter service on the Rentality platform.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the currency converter service. |

### updateCurrencyConverterService

```solidity
function updateCurrencyConverterService(address contractAddress) public
```

Update the address of the currency converter service on the Rentality platform.

_This function can only be called by the platform admin._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the currency converter service. |

### getTripServiceAddress

```solidity
function getTripServiceAddress() public view returns (address)
```

### updateTripService

```solidity
function updateTripService(address contractAddress) public
```

Update the RentalityTripService service contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the RentalityTripService contract. |

### getUserServiceAddress

```solidity
function getUserServiceAddress() public view returns (address)
```

Get the address of the RentalityUserService service contract.

### updateUserService

```solidity
function updateUserService(address contractAddress) public
```

Update the RentalityUserService service contract address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The new address of the RentalityUserService contract. |

### withdrawFromPlatform

```solidity
function withdrawFromPlatform(uint256 amount) public
```

Withdraw a specific amount of funds from the contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to withdraw from the contract. |

### withdrawAllFromPlatform

```solidity
function withdrawAllFromPlatform() public
```

### createTripRequest

```solidity
function createTripRequest(struct IRentalityGateway.CreateTripRequest request) public payable
```

Create a new trip request on the Rentality platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| request | struct IRentalityGateway.CreateTripRequest | The details of the trip request as specified in IRentalityGateway.CreateTripRequest. |

### approveTripRequest

```solidity
function approveTripRequest(uint256 tripId) public
```

Approve a trip request on the Rentality platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to approve. |

### rejectTripRequest

```solidity
function rejectTripRequest(uint256 tripId) public
```

Reject a trip request on the Rentality platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to reject. |

### finishTrip

```solidity
function finishTrip(uint256 tripId) public
```

Finish a trip on the Rentality platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to finish. |

### getTripContactInfo

```solidity
function getTripContactInfo(uint256 tripId) public view returns (string guestPhoneNumber, string hostPhoneNumber)
```

Get contact information for a specific trip on the Rentality platform.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tripId | uint256 | The ID of the trip to retrieve contact information for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| guestPhoneNumber | string | The phone number of the guest on the trip. |
| hostPhoneNumber | string | The phone number of the host on the trip. |

### getMyKYCInfo

```solidity
function getMyKYCInfo() external view returns (struct RentalityUserService.KYCInfo kycInfo)
```

Get KYC (Know Your Customer) information for the caller on the Rentality platform.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| kycInfo | struct RentalityUserService.KYCInfo | The KYC information for the caller. |

### getChatInfoForHost

```solidity
function getChatInfoForHost() public view returns (struct IRentalityGateway.ChatInfo[])
```

Get chat information for trips hosted by the caller on the Rentality platform.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct IRentalityGateway.ChatInfo[] | chatInfo An array of chat information for trips hosted by the caller. |

### getChatInfoForGuest

```solidity
function getChatInfoForGuest() public view returns (struct IRentalityGateway.ChatInfo[])
```

Get chat information for trips attended by the caller on the Rentality platform.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct IRentalityGateway.ChatInfo[] | chatInfo An array of chat information for trips attended by the caller. |

