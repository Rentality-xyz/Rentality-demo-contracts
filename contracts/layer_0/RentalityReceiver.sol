// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {OAppReceiver, Origin} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol';
import {OAppCore} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import '../RentalityGateway.sol';
import {EndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/EndpointV2.sol";

contract RentalityReceiver is OAppReceiver {
  RentalityGateway private gateway;

  constructor(address sendTo, address _endpoint) OAppCore(_endpoint, msg.sender) Ownable() {
    gateway = RentalityGateway(payable(sendTo));
    gateway.setLayerZeroSender(address(this));
  }

  function _lzReceive(
    Origin calldata _origin,
    bytes32 _guid,
    bytes calldata payload,
    address,
    bytes calldata
  ) internal override {
    (bool ok, bytes memory res) = payable(gateway).call{value: msg.value}(payload);
    if (!ok) {
      // For correct encoding revert message
      assembly {
        revert(add(32, res), mload(res))
      }
    }
  }
  function setNewPeer(uint32 eid, address senderAddress) public {
    require(owner() == msg.sender, 'Only owner');
    super.setPeer(eid, bytes32(uint256(uint160(senderAddress))));
  }
}
