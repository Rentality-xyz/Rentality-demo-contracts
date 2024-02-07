// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address) external returns (uint);

    function transfer(address, uint) external returns(bool);

    function decimals() external pure returns (uint8);

    function approve(address, uint) external;

    function transferFrom(address, address, uint) external returns(bool);
        

}
