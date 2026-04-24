// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../infrastructure/upgradeable/UUPSOwnable.sol';
import '../models/common/CommonTypes.sol';
import {GatewayDiamond} from './GatewayDiamond.sol';

interface IAppGatewayNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

/// @title AppGateway
/// @notice Single external Rentality entrypoint that routes selectors to gateway facets.
contract AppGateway is UUPSOwnable, ReentrancyGuardUpgradeable {
  address private l0Sender;
  IAppGatewayNotificationService private notificationService;

  fallback(bytes calldata data) external payable nonReentrant returns (bytes memory) {
    bytes memory dataToSend;
    GatewayDiamond.DiamondStorage storage ds;
    bytes32 position = GatewayDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }

    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    bool isCrossChain = msg.sender == l0Sender;
    address sender = msg.sender;

    if (isCrossChain) {
      (bytes memory crossChainData, address user, ) = abi.decode(data, (bytes, address, bytes32));
      sender = user;
      bytes4 selector;
      assembly {
        selector := mload(add(crossChainData, 32))
      }
      facet = ds.selectorToFacetAndPosition[selector].facetAddress;
      dataToSend = _forward(crossChainData, user);
    } else {
      dataToSend = _forward(data, msg.sender);
    }

    if (address(facet) == address(0)) {
      revert('Function does not exist');
    }

    (bool ok, bytes memory res) = address(facet).call{value: msg.value}(dataToSend);
    if (isCrossChain) {
      CrassChainMessageStatus status = CrassChainMessageStatus.Success;
      if (!ok && msg.value > 0) {
        status = CrassChainMessageStatus.PayableFail;
      } else if (!ok) {
        status = CrassChainMessageStatus.Fail;
      }

      notificationService.emitEvent(EventType.CrassChainMessage, 0, uint8(status), sender, sender);
    }
    return _parseResult(ok, res);
  }

  function _parseResult(bool flag, bytes memory result) internal pure returns (bytes memory) {
    if (!flag) {
      assembly ('memory-safe') {
        revert(add(32, result), mload(result))
      }
    }
    return result;
  }

  function _forward(bytes memory data, address user) private pure returns (bytes memory result) {
    result = abi.encodePacked(data, user);
  }

  function setLayerZeroSender(address _layer0Sender) public onlyOwner {
    l0Sender = _layer0Sender;
  }

  function setNotificationService(address notificationServiceAddress) public onlyOwner {
    notificationService = IAppGatewayNotificationService(notificationServiceAddress);
  }

  function diamondCut(GatewayDiamond.FacetCut[] memory _diamondCut) public onlyOwner {
    GatewayDiamond.diamondCut(_diamondCut);
  }

  function initialize(GatewayDiamond.FacetCut[] memory _diamondCut) public initializer {
    GatewayDiamond.diamondCut(_diamondCut);
    __Ownable_init();
    __ReentrancyGuard_init();
  }
}
