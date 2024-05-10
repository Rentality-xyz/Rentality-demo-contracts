# Solidity API

## RentalityMockPriceFeed

This contract represents a mock Chainlink price feed for testing purposes.

_It extends the MockV3Aggregator and allows configuring the number of decimals and initial answer._

### constructor

```solidity
constructor(uint8 _decimals, int256 _initialAnswer) public
```

Constructor to initialize the mock price feed.

#### Parameters

| Name            | Type   | Description                                    |
| --------------- | ------ | ---------------------------------------------- |
| \_decimals      | uint8  | The number of decimals for the price feed.     |
| \_initialAnswer | int256 | The initial answer (price) for the price feed. |
