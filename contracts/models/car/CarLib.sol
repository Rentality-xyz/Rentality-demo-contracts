// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CarLib {
    error InvalidCarPrice();
    error InvalidMilesIncluded();

    function validatePricing(uint64 pricePerDayInUsdCents, uint64 milesIncludedPerDay) internal pure {
        if (pricePerDayInUsdCents == 0) {
            revert InvalidCarPrice();
        }

        if (milesIncludedPerDay == 0) {
            revert InvalidMilesIncluded();
        }
    }

    function hashVin(string memory carVinNumber) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(carVinNumber));
    }

    function buildName(
        string memory requestedName,
        string memory brand,
        string memory model
    ) internal pure returns (string memory) {
        return bytes(requestedName).length > 0 ? requestedName : string.concat(brand, " ", model);
    }

    function updateListingMoment(
        mapping(uint256 => uint256) storage listingMomentById,
        uint256 id,
        bool wasListed,
        bool isListedNow
    ) internal {
        if (!wasListed && isListedNow) {
            listingMomentById[id] = block.timestamp;
        }

        if (wasListed && !isListedNow) {
            listingMomentById[id] = 0;
        }
    }
}

