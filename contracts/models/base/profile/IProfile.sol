// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ProfileTypes.sol";

interface IProfile {
    function exists(address user) external view returns (bool);

    function getProfileAccount(address user) external view returns (ProfileAccount memory);

    function getProfileContact(address user) external view returns (ProfileContactInfo memory);

    function getProfileConsent(address user) external view returns (ProfileConsent memory);
}
