// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RentalityChatHelper {
    struct ChatKeyPair {
        string privateKey;
        string publicKey;
    }

    struct AddressPublicKey {
        address userAddress;
        string publicKey;
    }


    mapping(address => ChatKeyPair) private addressToChatKeyPair;

    function setMyChatPublicKey(string memory chatPrivateKey, string memory chatPublicKey) public {
        addressToChatKeyPair[tx.origin] = ChatKeyPair(chatPrivateKey, chatPublicKey);
    }

    function getMyChatKeys() public view returns (string memory, string memory) {
        return (addressToChatKeyPair[tx.origin].privateKey, addressToChatKeyPair[tx.origin].publicKey);
    }

    function getChatPublicKeys(address[] memory addresses) public view returns (AddressPublicKey[] memory) {
        AddressPublicKey[] memory result = new AddressPublicKey[](addresses.length);

        for (uint i = 0; i < addresses.length; i++) {
            result[i] = AddressPublicKey(addresses[i], addressToChatKeyPair[addresses[i]].publicKey);
        }

        return result;
    }
}
