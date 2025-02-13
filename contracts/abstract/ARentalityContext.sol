// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



abstract contract ARentalityContext  { 
   
    function trustedForwarder() internal view virtual returns (address);
    /**
     * @dev Indicates whether any particular address is the trusted forwarder.
     */
    function isTrustedForwarder(address forwarder) internal view virtual returns (bool);

    /**
     * @dev Override for `msg.sender`. Defaults to the original `msg.sender` whenever
     * a call is not performed by the trusted forwarder or the calldata length is less than
     * 20 bytes (an address length).
     */
    function _msgGatewaySender() internal view virtual returns (address) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextGatewaySuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return address(bytes20(msg.data[calldataLength - contextSuffixLength:]));
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev Override for `msg.data`. Defaults to the original `msg.data` whenever
     * a call is not performed by the trusted forwarder or the calldata length is less than
     * 20 bytes (an address length).
     */
    function _msgGatewayData() internal view virtual returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextGatewaySuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return msg.data[:calldataLength - contextSuffixLength];
        } else {
            return msg.data;
        }
    }

    /**
     * @dev ERC-2771 specifies the context as being a single address (20 bytes).
     */
    function _contextGatewaySuffixLength() internal view virtual returns (uint256) {
        return 20;
}

}