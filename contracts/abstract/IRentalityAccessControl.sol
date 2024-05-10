// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRentalityAccessControl {
  /// @notice Checks if a user has admin role.
  /// @param user The address of the user to check for admin role.
  /// @return isAdmin A boolean indicating whether the user has admin role.
  function isAdmin(address user) external view returns (bool);
  /// @notice Checks if a user has manager role.
  /// @param user The address of the user to check for manager role.
  /// @return isManager A boolean indicating whether the user has manager role.
  function isManager(address user) external view returns (bool);
  /// @notice Checks if a user has host role.
  /// @param user The address of the user to check for host role.
  /// @return isHost A boolean indicating whether the user has host role.
  function isHost(address user) external view returns (bool);
  /// @notice Checks if a user has guest role.
  /// @param user The address of the user to check for guest role.
  /// @return isGuest A boolean indicating whether the user has guest role.
  function isGuest(address user) external view returns (bool);

  /// @notice Checks if a user has host or guest role.
  /// @param user The address of the user to check for host or guest role.
  /// @return isHostOrGuest A boolean indicating whether the user has host or guest role.
  function isHostOrGuest(address user) external view returns (bool);
}
