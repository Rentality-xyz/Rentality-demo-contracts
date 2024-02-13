// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function decimals() external pure returns (uint8);

    function balanceOf(address) external returns (uint);

    function transfer(address, uint) external returns (bool);

    function allowance(address, address) external returns (uint);

    function approve(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);

}
