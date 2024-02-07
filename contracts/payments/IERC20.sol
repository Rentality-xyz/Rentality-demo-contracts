// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address) external returns (uint);

    function transfer(address, uint) external;

    function decimals() external pure returns (uint8);

    function approve(address spender, uint amount) external;

    ffunction transferFrom(address from, address to, uint value) public;
        
    }
}
