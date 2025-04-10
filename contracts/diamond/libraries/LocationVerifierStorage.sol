// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

library LocationVerifierStorage { 
   
    struct LocationVerifierFaucetStorage {
            bytes32  _cachedDomainSeparator;
            uint256  _cachedChainId;
            address  _cachedThis;

            bytes32  _hashedName;
            bytes32  _hashedVersion;

            ShortString  _name;
            ShortString  _version;
            string _nameFallback;
            string  _versionFallback;
    }

     function accessStorage() internal pure returns (LocationVerifierFaucetStorage storage ds) {
        bytes32 position = LibDiamond.LOCATION_SERVICE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }

}