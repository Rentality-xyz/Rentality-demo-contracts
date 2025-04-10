// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC4906.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "./ERC721.sol";
import "../../../libraries/CarTokenStorage.sol";

 bytes4 constant ERC4906_INTERFACE_ID = bytes4(0x49064906);

   event MetadataUpdate(uint256 _tokenId);

  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

abstract contract ERC721URIStorage is ERC721, IERC165 {
    using Strings for uint256;


    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == ERC4906_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
        string memory _tokenURI = s._tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {IERC4906-MetadataUpdate}.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        CarTokenStorage.CarTokenFaucetStorage storage s = CarTokenStorage.accessStorage();
        s._tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }
}