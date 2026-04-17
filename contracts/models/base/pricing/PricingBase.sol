// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IPricing.sol';

abstract contract PricingBase is IPricing {
    uint32 internal platformFeeInPPM;

    error InvalidPlatformFeeInPPM(uint32 valueInPPM);

    function getPlatformFeeInPPM() public view virtual returns (uint32) {
        return platformFeeInPPM;
    }

    function getPlatformFeeFrom(uint256 value) public view virtual returns (uint256) {
        return (value * platformFeeInPPM) / 1_000_000;
    }

    function _setPlatformFeeInPPM(uint32 valueInPPM) internal {
        if (valueInPPM == 0 || valueInPPM > 1_000_000) {
            revert InvalidPlatformFeeInPPM(valueInPPM);
        }

        platformFeeInPPM = valueInPPM;
    }
}
