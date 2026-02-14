// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {Context} from '@openzeppelin/contracts/utils/Context.sol';

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IOAppCore, ILayerZeroEndpointV2} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol';

import {OAppSender, MessagingFee, MessagingReceipt, MessagingParams} from '@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol';

abstract contract ARentalitySender is IOAppCore, Context {
  ILayerZeroEndpointV2 public endpoint;
  mapping(uint32 eid => bytes32 peer) public peers;
  /**
   * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
   * @param _eid The endpoint ID.
   * @param _peer The address of the peer to be associated with the corresponding endpoint.
   *
   * @dev Only the owner/admin of the OApp can call this function.
   * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
   * @dev Set this to bytes32(0) to remove the peer address.
   * @dev Peer is a bytes32 to accommodate non-evm chains.
   */
  function setPeer(uint32 _eid, bytes32 _peer) public virtual onlyOwner {
    _setPeer(_eid, _peer);
  }

  /**
   * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
   * @param _eid The endpoint ID.
   * @param _peer The address of the peer to be associated with the corresponding endpoint.
   *
   * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
   * @dev Set this to bytes32(0) to remove the peer address.
   * @dev Peer is a bytes32 to accommodate non-evm chains.
   */
  function _setPeer(uint32 _eid, bytes32 _peer) internal virtual {
    peers[_eid] = _peer;
    emit PeerSet(_eid, _peer);
  }

  /**
   * @notice Internal function to get the peer address associated with a specific endpoint; reverts if NOT set.
   * ie. the peer is set to bytes32(0).
   * @param _eid The endpoint ID.
   * @return peer The address of the peer associated with the specified endpoint.
   */
  function _getPeerOrRevert(uint32 _eid) internal view virtual returns (bytes32) {
    bytes32 peer = peers[_eid];
    if (peer == bytes32(0)) revert NoPeer(_eid);
    return peer;
  }

  /**
   * @notice Sets the delegate address for the OApp.
   * @param _delegate The address of the delegate to be set.
   *
   * @dev Only the owner/admin of the OApp can call this function.
   * @dev Provides the ability for a delegate to set configs, on behalf of the OApp, directly on the Endpoint contract.
   */
  function setDelegate(address _delegate) public onlyOwner {
    endpoint.setDelegate(_delegate);
  }

  using SafeERC20 for IERC20;

  // Custom error messages
  error NotEnoughNative(uint256 msgValue);
  error LzTokenUnavailable();

  // @dev The version of the OAppSender implementation.
  // @dev Version is bumped when changes are made to this contract.
  uint64 internal constant SENDER_VERSION = 1;

  /**
   * @notice Retrieves the OApp version information.
   * @return senderVersion The version of the OAppSender.sol contract.
   * @return receiverVersion The version of the OAppReceiver.sol contract.
   *
   * @dev Providing 0 as the default for OAppReceiver version. Indicates that the OAppReceiver is not implemented.
   * ie. this is a SEND only OApp.
   * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions
   */
  function oAppVersion() public view virtual returns (uint64 senderVersion, uint64 receiverVersion) {
    return (SENDER_VERSION, 0);
  }

  /**
   * @dev Internal function to interact with the LayerZero EndpointV2.quote() for fee calculation.
   * @param _dstEid The destination endpoint ID.
   * @param _message The message payload.
   * @param _options Additional options for the message.
   * @param _payInLzToken Flag indicating whether to pay the fee in LZ tokens.
   * @return fee The calculated MessagingFee for the message.
   *      - nativeFee: The native fee for the message.
   *      - lzTokenFee: The LZ token fee for the message.
   */
  function _quote(
    uint32 _dstEid,
    bytes memory _message,
    bytes memory _options,
    bool _payInLzToken
  ) internal view virtual returns (MessagingFee memory fee) {
    return
      endpoint.quote(
        MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, _payInLzToken),
        address(this)
      );
  }

  /**
   * @dev Internal function to interact with the LayerZero EndpointV2.send() for sending a message.
   * @param _dstEid The destination endpoint ID.
   * @param _message The message payload.
   * @param _options Additional options for the message.
   * @param _fee The calculated LayerZero fee for the message.
   *      - nativeFee: The native fee.
   *      - lzTokenFee: The lzToken fee.
   * @param _refundAddress The address to receive any excess fee values sent to the endpoint.
   * @return receipt The receipt for the sent message.
   *      - guid: The unique identifier for the sent message.
   *      - nonce: The nonce of the sent message.
   *      - fee: The LayerZero fee incurred for the message.
   */
  function _lzSend(
    uint32 _dstEid,
    bytes memory _message,
    bytes memory _options,
    MessagingFee memory _fee,
    address _refundAddress
  ) internal virtual returns (MessagingReceipt memory receipt) {
    // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
    uint256 messageValue = _payNative(_fee.nativeFee);
    if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

    return
      // solhint-disable-next-line check-send-result
      endpoint.send{value: messageValue}(
        MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, _fee.lzTokenFee > 0),
        _refundAddress
      );
  }

  /**
   * @dev Internal function to pay the native fee associated with the message.
   * @param _nativeFee The native fee to be paid.
   * @return nativeFee The amount of native currency paid.
   *
   * @dev If the OApp needs to initiate MULTIPLE LayerZero messages in a single transaction,
   * this will need to be overridden because msg.value would contain multiple lzFees.
   * @dev Should be overridden in the event the LayerZero endpoint requires a different native currency.
   * @dev Some EVMs use an ERC20 as a method for paying transactions/gasFees.
   * @dev The endpoint is EITHER/OR, ie. it will NOT support both types of native payment at a time.
   */
  function _payNative(uint256 _nativeFee) internal virtual returns (uint256 nativeFee) {
    if (msg.value != _nativeFee) revert NotEnoughNative(msg.value);
    return _nativeFee;
  }

  /**
   * @dev Internal function to pay the LZ token fee associated with the message.
   * @param _lzTokenFee The LZ token fee to be paid.
   *
   * @dev If the caller is trying to pay in the specified lzToken, then the lzTokenFee is passed to the endpoint.
   * @dev Any excess sent, is passed back to the specified _refundAddress in the _lzSend().
   */
  function _payLzToken(uint256 _lzTokenFee) internal virtual {
    // @dev Cannot cache the token because it is not immutable in the endpoint.
    address lzToken = endpoint.lzToken();
    if (lzToken == address(0)) revert LzTokenUnavailable();

    // Pay LZ token fee by sending tokens to the endpoint.
    IERC20(lzToken).safeTransferFrom(msg.sender, address(endpoint), _lzTokenFee);
  }

  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby disabling any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}
