// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPricing {
    function getPlatformFeeInPPM() external view returns (uint32);
    function getPlatformFeeFrom(uint256 value) external view returns (uint256);
}
