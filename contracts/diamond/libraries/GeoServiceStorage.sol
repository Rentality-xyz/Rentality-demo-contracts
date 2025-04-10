// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";

library GeoServiceStorage { 
    struct GeoServiceFaucetStorage {

    }

    function accessStorage() internal pure returns (GeoServiceFaucetStorage storage ds) {
        bytes32 position = LibDiamond.GEO_SERVICE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
}