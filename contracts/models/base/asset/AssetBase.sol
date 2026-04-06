// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AssetTypes.sol";
import "./IAsset.sol";

abstract contract AssetBase is IAsset {
    uint256 internal nextAssetId;

    mapping(uint256 => Asset) internal assets;

    error AssetDoesNotExist(uint256 id);
    error InvalidAssetName();
    error InvalidMetadataURI();
    error NotAssetOwner(uint256 id, address caller);

    event AssetCreated(uint256 indexed id, address indexed owner, string name);
    event AssetUpdated(uint256 indexed id, string name, string metadataURI);

    modifier assetExists(uint256 id) {
        if (!exists(id)) {
            revert AssetDoesNotExist(id);
        }
        _;
    }

    function getAsset(uint256 id) external view virtual assetExists(id) returns (Asset memory) {
        return assets[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return assets[id].id != 0;
    }

    function getOwner(uint256 id) external view virtual assetExists(id) returns (address) {
        return assets[id].owner;
    }

    function _createAsset(
        address owner,
        string memory name,
        string memory metadataURI
    ) internal virtual returns (uint256) {
        _validateAssetData(name, metadataURI);

        uint256 id = ++nextAssetId;

        assets[id] = Asset({
            id: id,
            owner: owner,
            name: name,
            metadataURI: metadataURI,
            createdAt: uint64(block.timestamp)
        });

        emit AssetCreated(id, owner, name);
        return id;
    }

    function _updateAsset(uint256 id, string memory name, string memory metadataURI) internal virtual assetExists(id) {
        _validateAssetData(name, metadataURI);

        Asset storage asset = assets[id];
        asset.name = name;
        asset.metadataURI = metadataURI;

        emit AssetUpdated(id, name, metadataURI);
    }

    function _checkCanManageAsset(uint256 id, address caller) internal view virtual {
        if (assets[id].owner != caller) {
            revert NotAssetOwner(id, caller);
        }
    }

    function _validateAssetData(string memory name, string memory metadataURI) internal pure virtual {
        if (bytes(name).length == 0) {
            revert InvalidAssetName();
        }

        if (bytes(metadataURI).length == 0) {
            revert InvalidMetadataURI();
        }
    }
}

