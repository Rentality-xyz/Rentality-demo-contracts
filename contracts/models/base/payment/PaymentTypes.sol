// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum PaymentAssetType {
    Native,
    ERC20
}

struct PaymentAsset {
    address currency;
    PaymentAssetType assetType;
}

struct TreasuryWithdrawal {
    address receiver;
    address currency;
    uint256 amount;
}
