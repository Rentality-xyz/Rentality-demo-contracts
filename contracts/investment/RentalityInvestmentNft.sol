// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RentalityInvestmentNft is ERC721, Ownable {
    uint public tokenId;
    uint immutable public investId;
    mapping(uint => uint) public tokenIdToPriceInEth;

    string private _tokenUri;

    constructor(string memory name_, string memory symbol_, uint investId_, string memory tokenUri_) ERC721(name_, symbol_) {
        tokenId = 0;
        investId = investId_;
        _tokenUri = tokenUri_;
    }
    function mint(uint priceInEth) public  onlyOwner() {
        tokenId += 1;
        _mint(tx.origin, tokenId);
        tokenIdToPriceInEth[tokenId] = priceInEth;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        _requireMinted(id);
        return _tokenUri;
    }

    function getAllMyTokensWithTotalPrice() public view returns (uint[] memory, uint) {
        uint[] memory result = new uint[](balanceOf(tx.origin));
        uint counter = 0;
        uint totalPrice = 0;
        for (uint i = 1; i <= result.length; i++)
            if (_ownerOf(i) == tx.origin) {
                result[counter] = i;
                counter += 1;
                totalPrice += tokenIdToPriceInEth[i];
            }
        return (result, totalPrice);
    }

    function getMyTokens() public view returns (uint[] memory) {
        uint[] memory result = new uint[](balanceOf(tx.origin));
        uint counter = 0;
        for (uint i = 1; i <= tokenId; i++)
            if (_ownerOf(i) == tx.origin) {
                result[counter] = i;
                counter++;
            }
        return result;
    }



}