// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library GatewayDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256('diamond.standard.diamond.storage');
  bytes32 constant RENTALITY_STORAGE_POSITION = keccak256('rentality.contract.diamond.storage');

  struct FacetAddressAndPosition {
    address facetAddress;
    uint16 functionSelectorPosition;
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint16 facetAddressPosition;
  }

  struct FacetCut {
    address facetAddress;
    bytes4[] functionSelectors;
    FacetCutAction action;
  }

  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }

  struct DiamondStorage {
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    address[] facetAddresses;
    mapping(bytes4 => bool) supportedInterfaces;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function diamondCut(FacetCut[] memory _diamondCut) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == FacetCutAction.Add) {
        addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == FacetCutAction.Replace) {
        replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == FacetCutAction.Remove) {
        removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else {
        revert('GatewayDiamondCut: Incorrect FacetCutAction');
      }
    }
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, 'GatewayDiamondCut: No selectors in facet to cut');
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "GatewayDiamondCut: Add facet can't be address(0)");
    uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

    if (selectorPosition == 0) {
      enforceHasContractCode(_facetAddress, 'GatewayDiamondCut: New facet has no code');
      ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
      ds.facetAddresses.push(_facetAddress);
    }

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "GatewayDiamondCut: Can't add function that already exists");
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
      ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
      ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
      selectorPosition++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, 'GatewayDiamondCut: No selectors in facet to cut');
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "GatewayDiamondCut: Add facet can't be address(0)");
    uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

    if (selectorPosition == 0) {
      enforceHasContractCode(_facetAddress, 'GatewayDiamondCut: New facet has no code');
      ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
      ds.facetAddresses.push(_facetAddress);
    }

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress != _facetAddress, "GatewayDiamondCut: Can't replace function with same function");
      removeFunction(oldFacetAddress, selector);
      ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
      ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
      selectorPosition++;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, 'GatewayDiamondCut: No selectors in facet to cut');
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress == address(0), 'GatewayDiamondCut: Remove facet address must be address(0)');

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(oldFacetAddress, selector);
    }
  }

  function removeFunction(address _facetAddress, bytes4 _selector) internal {
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "GatewayDiamondCut: Can't remove function that doesn't exist");
    require(_facetAddress != address(this), "GatewayDiamondCut: Can't remove immutable function");

    uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;

    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
    }

    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    if (lastSelectorPosition == 0) {
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      require(_calldata.length == 0, 'GatewayDiamondCut: _init is address(0) but_calldata is not empty');
    } else {
      require(_calldata.length > 0, 'GatewayDiamondCut: _calldata is empty but _init is not address(0)');
      if (_init != address(this)) {
        enforceHasContractCode(_init, 'GatewayDiamondCut: _init address has no code');
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          revert(string(error));
        } else {
          revert('GatewayDiamondCut: _init function reverted');
        }
      }
    }
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }
}
