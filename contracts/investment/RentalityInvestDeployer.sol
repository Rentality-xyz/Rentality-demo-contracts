// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {RentalityCarInvestmentPool} from './RentalityInvestmentPool.sol';
import {RentalityInvestmentNft} from './RentalityInvestmentNft.sol';

contract RentalityInvestDeployer is Initializable, UUPSAccess {
  function createNewPool(uint id, address nft, uint totalPayed, address currency) public returns (address) {
    require(userService.isRentalityPlatform(msg.sender), 'only Rentality platform');
    return address(new RentalityCarInvestmentPool(id, nft, totalPayed, address(userService), currency));
  }
  function createNewNft(
    string memory name,
    string memory sym,
    uint id,
    string memory tokenUri
  ) public returns (address) {
    require(userService.isRentalityPlatform(msg.sender), 'only Rentality platform');
    return address(new RentalityInvestmentNft(name, sym, id, tokenUri, msg.sender));
  }

  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
  }
}
