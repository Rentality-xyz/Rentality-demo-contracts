# Solidity API

## RentalityPaymentService

This contract manages platform fees and allows the adjustment of the platform fee by the manager.

_It is connected to RentalityUserService to check if the caller is an admin._

### platformFeeInPPM

```solidity
uint32 platformFeeInPPM
```

### constructor

```solidity
constructor(address _userService) public
```

Constructor to initialize the RentalityPaymentService.

#### Parameters

| Name          | Type    | Description                                       |
| ------------- | ------- | ------------------------------------------------- |
| \_userService | address | The address of the RentalityUserService contract. |

### getPlatformFeeInPPM

```solidity
function getPlatformFeeInPPM() public view returns (uint32)
```

Get the current platform fee in parts per million (PPM).

#### Return Values

| Name | Type   | Description                      |
| ---- | ------ | -------------------------------- |
| [0]  | uint32 | The current platform fee in PPM. |

### setPlatformFeeInPPM

```solidity
function setPlatformFeeInPPM(uint32 valueInPPM) public
```

Set the platform fee in parts per million (PPM).

_Only callable by an admin. The value must be positive and not exceed 1,000,000._

#### Parameters

| Name       | Type   | Description                                |
| ---------- | ------ | ------------------------------------------ |
| valueInPPM | uint32 | The new value for the platform fee in PPM. |

### getPlatformFeeFrom

```solidity
function getPlatformFeeFrom(uint64 value) public view returns (uint64)
```

Get the platform fee from a given value.

#### Parameters

| Name  | Type   | Description                                         |
| ----- | ------ | --------------------------------------------------- |
| value | uint64 | The value from which to calculate the platform fee. |

#### Return Values

| Name | Type   | Description                                       |
| ---- | ------ | ------------------------------------------------- |
| [0]  | uint64 | The platform fee calculated from the given value. |
