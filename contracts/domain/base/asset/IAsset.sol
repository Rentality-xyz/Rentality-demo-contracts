// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AssetTypes.sol";

interface IAsset {
    function createAsset(CreateAssetRequest calldata request) external returns (uint256);

    function updateAsset(uint256 id, UpdateAssetRequest calldata request) external;

    function getAsset(uint256 id) external view returns (Asset memory);

    function exists(uint256 id) external view returns (bool);

    function getOwner(uint256 id) external view returns (address);
}
