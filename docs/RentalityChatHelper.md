# Solidity API

## RentalityChatHelper

A contract to manage chat key pairs for users

_Users can set and retrieve their chat key pairs, and get public keys of specified addresses._

### ChatKeyPair

```solidity
struct ChatKeyPair {
  string privateKey;
  string publicKey;
}
```

### AddressPublicKey

```solidity
struct AddressPublicKey {
  address userAddress;
  string publicKey;
}
```

### setMyChatPublicKey

```solidity
function setMyChatPublicKey(string chatPrivateKey, string chatPublicKey) public
```

Set the chat key pair for the calling user

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chatPrivateKey | string | The private chat key of the user |
| chatPublicKey | string | The public chat key of the user |

### getMyChatKeys

```solidity
function getMyChatKeys() public view returns (string, string)
```

Get the chat key pair of the calling user

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | The private and public chat keys of the calling user |
| [1] | string |  |

### getChatPublicKeys

```solidity
function getChatPublicKeys(address[] addresses) public view returns (struct RentalityChatHelper.AddressPublicKey[])
```

Get the public chat keys associated with specified addresses

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addresses | address[] | An array of Ethereum addresses |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct RentalityChatHelper.AddressPublicKey[] | An array of AddressPublicKey structs containing user addresses and their public chat keys |

