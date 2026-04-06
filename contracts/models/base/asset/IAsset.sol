// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AssetTypes.sol";

interface IAsset {
    function getAsset(uint256 id) external view returns (Asset memory);

    function exists(uint256 id) external view returns (bool);

    function getOwner(uint256 id) external view returns (address);
}

