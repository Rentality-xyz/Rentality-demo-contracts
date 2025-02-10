// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RentalityInvestmentNft is ERC721, Ownable {
  uint private tokenId;
  uint private immutable investId;
  mapping(uint => uint) public tokenIdToPriceInEth;

  string private _tokenUri;
  
  uint private totalHolders;

  constructor(
    string memory name_,
    string memory symbol_,
    uint investId_,
    string memory tokenUri_
  ) ERC721(name_, symbol_) {
    tokenId = 0;
    investId = investId_;
    _tokenUri = tokenUri_;
    
   _transferOwnership(msg.sender);
  }
  function mint(uint priceInEth, address user) public onlyOwner {
    tokenId += 1;
      
      if(balanceOf(user) == 0)
      totalHolders += 1;

    _mint(user, tokenId);
    tokenIdToPriceInEth[tokenId] = priceInEth;
 
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    _requireMinted(id);
    return _tokenUri;
  }

  function totalSupplyWithTotalHolders() public view returns(uint, uint) {
    return (tokenId,totalHolders);
  }

}