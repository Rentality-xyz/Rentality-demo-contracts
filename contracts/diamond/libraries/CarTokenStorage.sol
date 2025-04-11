// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";
import { RentalityEnginesService } from "../../engine/RentalityEnginesService.sol";

library CarTokenStorage {

    struct CarTokenFaucetStorage {
    
    mapping(uint256 tokenId => string) _tokenURIs;
    string  _name;

    string _symbol;

    mapping(uint256 tokenId => address) _owners;

    mapping(address owner => uint256) _balances;

    mapping(uint256 tokenId => address) _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) _operatorApprovals;


   uint _carIdCounter;
    
   mapping(uint256 => Schemas.CarInfo) idToCarInfo;

   mapping(uint => uint) carIdToListingMoment;
   RentalityEnginesService enginesService;

}

     function accessStorage() internal pure returns (CarTokenFaucetStorage storage ds) {
        bytes32 position = LibDiamond.CAR_TOKEN_STORAGE_POSSITION;
        assembly { ds.slot := position }
    }
}