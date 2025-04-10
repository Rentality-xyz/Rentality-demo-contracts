// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../mainLogic/standarts/EIP712.sol"; 

contract LocationVerifier is EIP712 {
 constructor () EIP712("RentalityLocationVerifier", "1") {}   
}