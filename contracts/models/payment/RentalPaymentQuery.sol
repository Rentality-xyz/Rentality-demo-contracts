// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './RentalPaymentMain.sol';

contract RentalPaymentQuery {
    RentalPaymentMain public paymentMain;

    constructor(address paymentMainAddress) {
        paymentMain = RentalPaymentMain(paymentMainAddress);
    }

    function getTreasuryBalance(address currencyType) external view returns (uint256) {
        return paymentMain.getTreasuryBalance(currencyType);
    }

    function getProfileMainAddress() external view returns (address) {
        return address(paymentMain.profileMain());
    }

    function getInvestmentServiceAddress() external view returns (address) {
        return address(paymentMain.investmentService());
    }

    function getInsuranceServiceAddress() external view returns (address) {
        return address(paymentMain.insuranceService());
    }

    function getSwapsAddress() external view returns (address) {
        return address(paymentMain.rentalitySwaps());
    }
}

