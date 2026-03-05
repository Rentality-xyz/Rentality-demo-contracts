// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract RentalityTestUSDT is ERC20 {
  /// @notice Deploy a new RentalityTestUSDT contract.
  constructor() ERC20('RentalityTestUSDT', 'RTUSDT') {}

  /// @notice Mint new tokens and assign them to the specified address.
  /// @dev This function can only be called by the contract owner.
  /// @param to The address to which the minted tokens will be assigned.
  /// @param amount The amount of tokens to mint.
  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }
}
