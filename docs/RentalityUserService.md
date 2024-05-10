# Solidity API

## RentalityUserService

### KYCInfo

```solidity
struct KYCInfo {
  string name;
  string surname;
  string mobilePhoneNumber;
  string profilePhoto;
  string licenseNumber;
  uint64 expirationDate;
  uint256 createDate;
}
```

### MANAGER_ROLE

```solidity
bytes32 MANAGER_ROLE
```

### HOST_ROLE

```solidity
bytes32 HOST_ROLE
```

### GUEST_ROLE

```solidity
bytes32 GUEST_ROLE
```

### constructor

```solidity
constructor() public
```

Constructor to initialize roles and role admin relationships.
It grants the DEFAULT_ADMIN_ROLE, MANAGER_ROLE, HOST_ROLE, and GUEST_ROLE to the deployer.
It sets the role admin for HOST_ROLE and GUEST_ROLE to MANAGER_ROLE.

### setKYCInfo

```solidity
function setKYCInfo(string name, string surname, string mobilePhoneNumber, string profilePhoto, string licenseNumber, uint64 expirationDate) public
```

Sets KYC information for the caller (host or guest).

#### Parameters

| Name              | Type   | Description                                                                                |
| ----------------- | ------ | ------------------------------------------------------------------------------------------ |
| name              | string | The user's name.                                                                           |
| surname           | string | The user's surname.                                                                        |
| mobilePhoneNumber | string | The user's mobile phone number.                                                            |
| profilePhoto      | string | The URL or identifier of the user's profile photo.                                         |
| licenseNumber     | string | The user's license number.                                                                 |
| expirationDate    | uint64 | The expiration date of the user's license. Requirements: - Caller must be a host or guest. |

### getKYCInfo

```solidity
function getKYCInfo(address user) external view returns (struct RentalityUserService.KYCInfo kycInfo)
```

Retrieves KYC information for a specified user.

#### Parameters

| Name | Type    | Description                                                   |
| ---- | ------- | ------------------------------------------------------------- |
| user | address | The address of the user for whom to retrieve KYC information. |

#### Return Values

| Name    | Type                                | Description                                                                                    |
| ------- | ----------------------------------- | ---------------------------------------------------------------------------------------------- |
| kycInfo | struct RentalityUserService.KYCInfo | KYCInfo structure containing user's KYC information. Requirements: - Caller must be a manager. |

### getMyKYCInfo

```solidity
function getMyKYCInfo() external view returns (struct RentalityUserService.KYCInfo kycInfo)
```

Retrieves KYC information for the caller.

#### Return Values

| Name    | Type                                | Description                                            |
| ------- | ----------------------------------- | ------------------------------------------------------ |
| kycInfo | struct RentalityUserService.KYCInfo | KYCInfo structure containing caller's KYC information. |

### hasValidKYC

```solidity
function hasValidKYC(address user) public view returns (bool isValid)
```

Checks if the KYC information for a specified user is valid.

#### Parameters

| Name | Type    | Description                                     |
| ---- | ------- | ----------------------------------------------- |
| user | address | The address of the user to check for valid KYC. |

#### Return Values

| Name    | Type | Description                                                      |
| ------- | ---- | ---------------------------------------------------------------- |
| isValid | bool | A boolean indicating whether the user has valid KYC information. |

### grantAdminRole

```solidity
function grantAdminRole(address user) public
```

Grants admin role to a specified user.
Requirements:

- Caller must have DEFAULT_ADMIN_ROLE.

#### Parameters

| Name | Type    | Description                                  |
| ---- | ------- | -------------------------------------------- |
| user | address | The address of the user to grant admin role. |

### revokeAdminRole

```solidity
function revokeAdminRole(address user) public
```

Revokes admin role from a specified user.
Requirements:

- Caller must have DEFAULT_ADMIN_ROLE.

#### Parameters

| Name | Type    | Description                                   |
| ---- | ------- | --------------------------------------------- |
| user | address | The address of the user to revoke admin role. |

### grantManagerRole

```solidity
function grantManagerRole(address user) public
```

Grants manager role to a specified user.
Requirements:

- Caller must have DEFAULT_ADMIN_ROLE.

#### Parameters

| Name | Type    | Description                                    |
| ---- | ------- | ---------------------------------------------- |
| user | address | The address of the user to grant manager role. |

### revokeManagerRole

```solidity
function revokeManagerRole(address user) public
```

Revokes manager role from a specified user.
Requirements:

- Caller must have DEFAULT_ADMIN_ROLE.

#### Parameters

| Name | Type    | Description                                     |
| ---- | ------- | ----------------------------------------------- |
| user | address | The address of the user to revoke manager role. |

### grantHostRole

```solidity
function grantHostRole(address user) public
```

Grants host role to a specified user.
Requirements:

- Caller must have MANAGER_ROLE.

#### Parameters

| Name | Type    | Description                                 |
| ---- | ------- | ------------------------------------------- |
| user | address | The address of the user to grant host role. |

### revokeHostRole

```solidity
function revokeHostRole(address user) public
```

Revokes host role from a specified user.
Requirements:

- Caller must have MANAGER_ROLE.

#### Parameters

| Name | Type    | Description                                  |
| ---- | ------- | -------------------------------------------- |
| user | address | The address of the user to revoke host role. |

### grantGuestRole

```solidity
function grantGuestRole(address user) public
```

Grants guest role to a specified user.
Requirements:

- Caller must have MANAGER_ROLE.

#### Parameters

| Name | Type    | Description                                  |
| ---- | ------- | -------------------------------------------- |
| user | address | The address of the user to grant guest role. |

### revokeGuestRole

```solidity
function revokeGuestRole(address user) public
```

Revokes guest role from a specified user.
Requirements:

- Caller must have MANAGER_ROLE.

#### Parameters

| Name | Type    | Description                                   |
| ---- | ------- | --------------------------------------------- |
| user | address | The address of the user to revoke guest role. |

### isAdmin

```solidity
function isAdmin(address user) public view returns (bool)
```

Checks if a user has admin role.

#### Parameters

| Name | Type    | Description                                      |
| ---- | ------- | ------------------------------------------------ |
| user | address | The address of the user to check for admin role. |

#### Return Values

| Name | Type | Description                                                   |
| ---- | ---- | ------------------------------------------------------------- |
| [0]  | bool | isAdmin A boolean indicating whether the user has admin role. |

### isManager

```solidity
function isManager(address user) public view returns (bool)
```

Checks if a user has manager role.

#### Parameters

| Name | Type    | Description                                        |
| ---- | ------- | -------------------------------------------------- |
| user | address | The address of the user to check for manager role. |

#### Return Values

| Name | Type | Description                                                       |
| ---- | ---- | ----------------------------------------------------------------- |
| [0]  | bool | isManager A boolean indicating whether the user has manager role. |

### isHost

```solidity
function isHost(address user) public view returns (bool)
```

Checks if a user has host role.

#### Parameters

| Name | Type    | Description                                     |
| ---- | ------- | ----------------------------------------------- |
| user | address | The address of the user to check for host role. |

#### Return Values

| Name | Type | Description                                                 |
| ---- | ---- | ----------------------------------------------------------- |
| [0]  | bool | isHost A boolean indicating whether the user has host role. |

### isGuest

```solidity
function isGuest(address user) public view returns (bool)
```

Checks if a user has guest role.

#### Parameters

| Name | Type    | Description                                      |
| ---- | ------- | ------------------------------------------------ |
| user | address | The address of the user to check for guest role. |

#### Return Values

| Name | Type | Description                                                   |
| ---- | ---- | ------------------------------------------------------------- |
| [0]  | bool | isGuest A boolean indicating whether the user has guest role. |

### isHostOrGuest

```solidity
function isHostOrGuest(address user) public view returns (bool)
```

Checks if a user has host or guest role.

#### Parameters

| Name | Type    | Description                                              |
| ---- | ------- | -------------------------------------------------------- |
| user | address | The address of the user to check for host or guest role. |

#### Return Values

| Name | Type | Description                                                                 |
| ---- | ---- | --------------------------------------------------------------------------- |
| [0]  | bool | isHostOrGuest A boolean indicating whether the user has host or guest role. |
