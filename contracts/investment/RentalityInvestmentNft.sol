// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import './IRentalityGeoParser.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract RentalityInvestmentNft is ERC721 {
    uint private tokenId;
    mapping(uint => string) private tokenIdToUri;

    constructor(string memory name_, string memory symbol_) super(name_, symbol_) {
        tokenId = 0;
    }
    function mint(string memory tokenUri) public {
        tokenId += 1;
        _mint(tx.origin, tokenId);
        tokenIdToUri[tokenId] = tokenIdToUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return tokenIdToUri[tokenId];
    }

}