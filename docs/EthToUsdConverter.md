# Solidity API

## EthToUsdConverter

_A contract for converting Ethereum to USD using Chainlink price feeds._

### ethToUsdPriceFeed

```solidity
contract AggregatorV3Interface ethToUsdPriceFeed
```

### constructor

```solidity
constructor(address ethToUsdPriceFeedAddress) public
```

_Constructor function to initialize the contract with the specified Chainlink ETH/USD price feed address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ethToUsdPriceFeedAddress | address | The address of the Chainlink ETH/USD price feed. |

### getLatestEthToUsdPrice

```solidity
function getLatestEthToUsdPrice() public view returns (int256)
```

_Get the latest ETH to USD price from the Chainlink price feed._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | int256 | int256 The latest ETH to USD price |

### getPriceFeedDecimals

```solidity
function getPriceFeedDecimals() public view returns (uint8)
```

_Get the decimals of the price feed._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | uint8 The decimals of the price feed. |

### getEthFromUsd

```solidity
function getEthFromUsd(uint256 valueInUsdCents) public view returns (uint256)
```

_Convert a given USD value to ETH._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| valueInUsdCents | uint256 | The value in USD cents to convert to ETH. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The equivalent amount in ETH. |

### getUsdFromEth

```solidity
function getUsdFromEth(uint256 valueInEth) public view returns (uint256)
```

_Convert a given ETH value to USD._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| valueInEth | uint256 | to convert to USD. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The equivalent amount in USD. |

