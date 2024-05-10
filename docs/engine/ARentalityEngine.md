# Solidity API

## ARentalityEngine

This contract defines the basic structure and functions required for a rental engine.

### WrongEngineArgs

```solidity
error WrongEngineArgs()
```

Emitted when incorrect arguments are passed to a function.

### EngineParamsNotMatch

```solidity
error EngineParamsNotMatch()
```

Emitted when engine parameters do not match expectations.

### userService

```solidity
contract RentalityUserService userService
```

The RentalityUserService contract used for user management.

### eType

```solidity
uint8 eType
```

The type of the engine.

### onlyManager

```solidity
modifier onlyManager()
```

Ensures that only a manager can execute the function.

### setEType

```solidity
function setEType(uint8 _eType) public virtual
```

Sets the engine type.

### addCar

```solidity
function addCar(uint256 carId, uint64[] params) public virtual
```

Adds a new car to the system.

### updateCar

```solidity
function updateCar(uint256 carId, uint64[] params) public virtual
```

Updates information about an existing car.

### burnCar

```solidity
function burnCar(uint256 carId) public virtual
```

Removes a car from the system.

### extraCosts

```solidity
function extraCosts(uint64[] params) public virtual returns (uint64)
```

Calculates and returns extra costs based on given parameters.

### getResolveAmountInUsdCents

```solidity
function getResolveAmountInUsdCents(uint64[] fuelPrices, uint64[] startParams, uint64[] endParams, uint256 carId, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays) public virtual returns (uint64, uint64)
```

Calculates the resolve amount in USD cents for a rental transaction.

### getEType

```solidity
function getEType() public view returns (uint8)
```

Retrieves the engine type.

### getDrivenMilesResolveAmountInUsdCents

```solidity
function getDrivenMilesResolveAmountInUsdCents(uint64 startOdometr, uint64 endOdometr, uint64 milesIncludedPerDay, uint64 pricePerDayInUsdCents, uint64 tripDays) public pure virtual returns (uint64)
```

Calculates the resolve amount in USD cents based on driven miles.

### verifyResourcePrice

```solidity
function verifyResourcePrice(uint64[] prices) public pure virtual
```

Verifies the correctness of resource prices.

### verifyStartParams

```solidity
function verifyStartParams(uint64[] params) public virtual
```

Verifies the correctness of start parameters.

### verifyEndParams

```solidity
function verifyEndParams(uint64[] startParams, uint64[] endParams) public virtual
```

Verifies the correctness of end parameters.

### compareParams

```solidity
function compareParams(uint64[] start, uint64[] end) public pure
```

Compares two sets of parameters to ensure they match.

### getParamsAmount

```solidity
function getParamsAmount() public virtual returns (uint256)
```

Gets the number of parameters expected for this engine.

### isCorrectArgs

```solidity
function isCorrectArgs(bool eq) internal pure
```

Reverts if the provided condition is not met, indicating incorrect arguments.

### isMatch

```solidity
function isMatch(bool eq) internal pure
```

Reverts if the provided condition is not met, indicating mismatched parameters.
