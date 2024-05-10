# Solidity API

## RentalityTestUSDT

### constructor

```solidity
constructor() public
```

Deploy a new RentalityTestUSDT contract.

### mint

```solidity
function mint(address to, uint256 amount) public
```

Mint new tokens and assign them to the specified address.

_This function can only be called by the contract owner._

#### Parameters

| Name   | Type    | Description                                              |
| ------ | ------- | -------------------------------------------------------- |
| to     | address | The address to which the minted tokens will be assigned. |
| amount | uint256 | The amount of tokens to mint.                            |
