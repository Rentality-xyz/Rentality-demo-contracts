// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract RentalityInvestmentNft is ERC721 {
  uint private tokenId;
  uint private immutable investId;
  mapping(uint => uint) public tokenIdToPriceInEth;

  string private _tokenUri;

  uint private totalHolders;
  address private immutable creator;

  constructor(
    string memory name_,
    string memory symbol_,
    uint investId_,
    string memory tokenUri_,
    address creator_
  ) ERC721(name_, symbol_) {
    tokenId = 0;
    investId = investId_;
    _tokenUri = tokenUri_;

    creator = creator_;
  }
  function mint(uint priceInEth, address user) public {
    require(msg.sender == creator, 'only Owner');
    tokenId += 1;

    if (balanceOf(user) == 0) totalHolders += 1;

    _mint(user, tokenId);
    tokenIdToPriceInEth[tokenId] = priceInEth;
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    _requireMinted(id);
    return _tokenUri;
  }

  function totalSupplyWithTotalHolders() public view returns (uint, uint) {
    return (tokenId, totalHolders);
  }
}
