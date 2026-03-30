// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Asset {
    uint256 id;
    address owner;
    string name;
    string metadataURI;
    uint64 createdAt;
}

struct CreateAssetRequest {
    string name;
    string metadataURI;
}

struct UpdateAssetRequest {
    string name;
    string metadataURI;
}
