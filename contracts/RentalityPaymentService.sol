// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RentalityPaymentService is Ownable {
    uint32 platformFeeInPPM = 200_000;

    function getPlatformFeeInPPM() public view returns (uint32) {
        return platformFeeInPPM;
    }

    function setPlatformFeeInPPM(uint32 valueInPPM) public  {
        require(tx.origin == owner(), "Only owner can change the platform fee");
        require(valueInPPM > 0, "Make sure the value isn't negative");
        require(valueInPPM <= 1_000_000, "Value can't be more than 1000000");

        platformFeeInPPM = valueInPPM;
    }

    function getPlatformFeeFrom(uint64 value) public view returns (uint64) {
        return (value * platformFeeInPPM) / 1_000_000;
    }
}