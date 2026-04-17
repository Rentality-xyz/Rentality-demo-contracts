// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IPayment.sol';

abstract contract PaymentBase is IPayment {
    error EmptyTreasury(address currencyType);
    error InsufficientTreasuryBalance(address currencyType, uint256 balance, uint256 requiredAmount);
    error NativeAmountMismatch(uint256 expected, uint256 actual);
    error ZeroReceiver();
    error TransferFailed(address currencyType, address receiver, uint256 amount);

    function getTreasuryBalance(address currencyType) public view virtual returns (uint256) {
        if (currencyType == address(0)) {
            return address(this).balance;
        }

        return IERC20(currencyType).balanceOf(address(this));
    }

    function withdrawFromTreasury(uint256 amount, address currencyType, address receiver) public virtual {
        _withdrawFromTreasury(amount, currencyType, receiver);
    }

    function _withdrawFromTreasury(uint256 amount, address currencyType, address receiver) internal {
        if (receiver == address(0)) {
            revert ZeroReceiver();
        }

        uint256 balance = getTreasuryBalance(currencyType);
        if (balance == 0) {
            revert EmptyTreasury(currencyType);
        }
        if (balance < amount) {
            revert InsufficientTreasuryBalance(currencyType, balance, amount);
        }

        bool success = _transferCurrency(currencyType, receiver, amount);
        if (!success) {
            revert TransferFailed(currencyType, receiver, amount);
        }
    }

    function _transferCurrency(address currencyType, address receiver, uint256 amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (currencyType == address(0)) {
            (bool success, ) = payable(receiver).call{value: amount}("");
            return success;
        }

        return IERC20(currencyType).transfer(receiver, amount);
    }

    function _pullCurrencyFrom(address currencyType, address from, uint256 amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        return IERC20(currencyType).transferFrom(from, address(this), amount);
    }

    function _checkNativeAmount(uint256 expectedAmount) internal view {
        uint256 actualAmount = msg.value;
        uint256 diff = actualAmount > expectedAmount ? actualAmount - expectedAmount : expectedAmount - actualAmount;
        if (diff > expectedAmount / 100) {
            revert NativeAmountMismatch(expectedAmount, actualAmount);
        }
    }
}
