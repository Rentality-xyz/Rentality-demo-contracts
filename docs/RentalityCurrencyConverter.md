# Solidity API

## RentalityCurrencyConverter

A contract for converting between Ether (ETH) and United States Dollar (USD) using Chainlink price feeds

_Users can retrieve the latest ETH to USD price, convert between ETH and USD, and cache the price for efficiency._

### ethToUsdPriceFeed

```solidity
contract AggregatorV3Interface ethToUsdPriceFeed
```

### updatePriceInterval

```solidity
uint256 updatePriceInterval
```

### lastUpdatePriceTimeStamp

```solidity
uint256 lastUpdatePriceTimeStamp
```

### constructor

```solidity
constructor(address ethToUsdPriceFeedAddress) public
```

#### Parameters

| Name                     | Type    | Description                                        |
| ------------------------ | ------- | -------------------------------------------------- |
| ethToUsdPriceFeedAddress | address | The address of the Chainlink ETH to USD price feed |

### getEthToUsdPrice

```solidity
function getEthToUsdPrice() public view returns (int256, uint8)
```

Get the current ETH to USD price and decimals

#### Return Values

| Name | Type   | Description                               |
| ---- | ------ | ----------------------------------------- |
| [0]  | int256 | The current ETH to USD price and decimals |
| [1]  | uint8  |                                           |

### getEthFromUsdLatest

```solidity
function getEthFromUsdLatest(uint256 valueInUsdCents) public view returns (uint256, int256, uint8)
```

Get the amount of ETH equivalent to a specified value in USD cents

#### Parameters

| Name            | Type    | Description                              |
| --------------- | ------- | ---------------------------------------- |
| valueInUsdCents | uint256 | The value in USD cents to convert to ETH |

#### Return Values

| Name | Type    | Description                                                             |
| ---- | ------- | ----------------------------------------------------------------------- |
| [0]  | uint256 | The equivalent amount of ETH, ETH to USD price, and ETH to USD decimals |
| [1]  | int256  |                                                                         |
| [2]  | uint8   |                                                                         |

### getUsdFromEthLatest

```solidity
function getUsdFromEthLatest(uint256 valueInEth) public view returns (uint256, int256, uint8)
```

Get the amount of USD cents equivalent to a specified amount of ETH

#### Parameters

| Name       | Type    | Description                               |
| ---------- | ------- | ----------------------------------------- |
| valueInEth | uint256 | The amount of ETH to convert to USD cents |

#### Return Values

| Name | Type    | Description                                                                   |
| ---- | ------- | ----------------------------------------------------------------------------- |
| [0]  | uint256 | The equivalent amount in USD cents, ETH to USD price, and ETH to USD decimals |
| [1]  | int256  |                                                                               |
| [2]  | uint8   |                                                                               |

### getEthFromUsd

```solidity
function getEthFromUsd(uint256 valueInUsdCents, int256 ethToUsdPrice, uint8 ethToUsdDecimals) public pure returns (uint256)
```

Get the amount of ETH equivalent to a specified value in USD cents

#### Parameters

| Name             | Type    | Description                                            |
| ---------------- | ------- | ------------------------------------------------------ |
| valueInUsdCents  | uint256 | The value in USD cents to convert to ETH               |
| ethToUsdPrice    | int256  | The specific ETH to USD price to use for conversion    |
| ethToUsdDecimals | uint8   | The specific ETH to USD decimals to use for conversion |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | The equivalent amount of ETH |

### getUsdFromEth

```solidity
function getUsdFromEth(uint256 valueInEth, int256 ethToUsdPrice, uint8 ethToUsdDecimals) public pure returns (uint256)
```

Get the amount of USD cents equivalent to a specified amount of ETH

#### Parameters

| Name             | Type    | Description                                            |
| ---------------- | ------- | ------------------------------------------------------ |
| valueInEth       | uint256 | The amount of ETH to convert to USD cents              |
| ethToUsdPrice    | int256  | The specific ETH to USD price to use for conversion    |
| ethToUsdDecimals | uint8   | The specific ETH to USD decimals to use for conversion |

#### Return Values

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| [0]  | uint256 | The equivalent amount in USD cents |

### getEthToUsdPriceWithCache

```solidity
function getEthToUsdPriceWithCache() public returns (int256, uint8)
```

Get the ETH to USD price and decimals with caching

#### Return Values

| Name | Type   | Description                               |
| ---- | ------ | ----------------------------------------- |
| [0]  | int256 | The current ETH to USD price and decimals |
| [1]  | uint8  |                                           |

### getEthFromUsdWithCache

```solidity
function getEthFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256)
```

Get the amount of ETH equivalent to a specified value in USD cents with caching

#### Parameters

| Name            | Type    | Description                              |
| --------------- | ------- | ---------------------------------------- |
| valueInUsdCents | uint256 | The value in USD cents to convert to ETH |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | The equivalent amount of ETH |

### getUsdFromEthWithCache

```solidity
function getUsdFromEthWithCache(uint256 valueInEth) public returns (uint256)
```

Get the amount of USD cents equivalent to a specified amount of ETH with caching

#### Parameters

| Name       | Type    | Description                               |
| ---------- | ------- | ----------------------------------------- |
| valueInEth | uint256 | The amount of ETH to convert to USD cents |

#### Return Values

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| [0]  | uint256 | The equivalent amount in USD cents |
