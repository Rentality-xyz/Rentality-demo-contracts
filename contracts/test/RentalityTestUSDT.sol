// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RentalityTestUSDT is ERC20, ERC20Burnable, Ownable {
  /// @notice Deploy a new RentalityTestUSDT contract.
  constructor() ERC20('RentalityTestUSDT', 'RTUSDT') {}

  /// @notice Mint new tokens and assign them to the specified address.
  /// @dev This function can only be called by the contract owner.
  /// @param to The address to which the minted tokens will be assigned.
  /// @param amount The amount of tokens to mint.
  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}