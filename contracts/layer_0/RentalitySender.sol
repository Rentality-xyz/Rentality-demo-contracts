// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IOAppCore, ILayerZeroEndpointV2} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol';
import {OAppSender, MessagingFee, MessagingReceipt, MessagingParams} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol';
import {OAppCore} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol';
import '../RentalityUserService.sol';
import '../abstract/IRentalitySender.sol';
import './ARentalitySender.sol';

contract RentalitySender is ARentalitySender, UUPSUpgradeable {
  bool private initialized;
  uint32 private distEid;
  uint32 private eid;
  uint128 private gasLimit;
  using OptionsBuilder for bytes;
  mapping(address => uint128) private values;
  uint private nonce;
  RentalityUserService private userService;

  fallback(bytes calldata data) external payable returns (bytes memory) {
    bytes memory _data = abi.encode(data, msg.sender, bytes32(uint(eid)));

    if (msg.value == 0) {
      uint value = 0;
      if (
        bytes4(bytes32(data[0:4])) == IRentalitySender.quotePayClaim.selector ||
        bytes4(bytes32(data[0:4])) == IRentalitySender.quoteCreateTripRequestWithDelivery.selector
      ) {
        value = uint(bytes32(data[4:36]));
      }
      return abi.encode(quote(uint128(value), _data));
    }

    MessagingFee memory fee = quote(0, _data);
    bytes memory options = buildOptions(0);

    if (fee.nativeFee < msg.value) {
      uint value = uint(bytes32(data[4:36]));
      options = buildOptions(uint128(value));
      fee = quotFromOptions(options, _data);
    }
    __lzSend(_data, options, fee, payable(msg.sender));
    return bytes('');
  }

  function __lzSend(
    bytes memory _message,
    bytes memory _options,
    MessagingFee memory _fee,
    address _refundAddress
  ) internal returns (MessagingReceipt memory receipt) {
    uint256 messageValue = _payNative(_fee.nativeFee);

    return
      // solhint-disable-next-line check-send-result
      endpoint.send{value: messageValue}(
        MessagingParams(distEid, _getPeerOrRevert(distEid), _message, _options, _fee.lzTokenFee > 0),
        _refundAddress
      );
  }

  function quote(uint128 value, bytes memory _message) public view returns (MessagingFee memory fee) {
    bytes memory options = buildOptions(value);
    fee = _quote(distEid, _message, options, false);
  }

  function quotFromOptions(bytes memory options, bytes memory _message) public view returns (MessagingFee memory fee) {
    fee = _quote(distEid, _message, options, false);
  }

  function setPeer(address recAddress) public {
    require(owner() == msg.sender, 'only Owner');
    _setPeer(distEid, bytes32(uint256(uint160(recAddress))));
  }

  function buildOptions(uint128 value) public view returns (bytes memory) {
    return OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, value);
  }

  function setGasLimit(uint128 gas) public {
    require(owner() == msg.sender, 'only Owner');
    gasLimit = gas;
  }

  function initialize(address _endpoint, address _delegate, uint32 _distEid, uint32 _eid, uint128 _gasLimit) public {
    require(!initialized, 'Already initialized');
    endpoint = ILayerZeroEndpointV2(_endpoint);

    if (_delegate == address(0)) revert InvalidDelegate();
    endpoint.setDelegate(_delegate);
    eid = _eid;
    distEid = _distEid;
    gasLimit = _gasLimit;
    _transferOwnership(Ownable(msg.sender).owner());
  }
  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(owner() == msg.sender, 'Only for Admin.');
  }
}
