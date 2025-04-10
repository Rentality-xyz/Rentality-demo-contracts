// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';

library RentalityUtilsDiamond {
    uint256 constant multiplier = 10 ** 7;

    function containWord(string memory where, string memory what) internal pure returns (bool found) {
    bytes memory whatBytes = bytes(what);
    bytes memory whereBytes = bytes(where);

    if (whereBytes.length < whatBytes.length) {
      return false;
    }

    found = false;
    for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
      bool flag = true;
      for (uint j = 0; j < whatBytes.length; j++)
        if (whereBytes[i + j] != whatBytes[j]) {
          flag = false;
          break;
        }
      if (flag) {
        found = true;
        break;
      }
    }
    return found;
  }


  function toLower(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

    /// @notice Parses an integer from a string.
  /// @param _a The input string to parse.
  /// @return Returns the parsed integer value.
  function parseInt(string memory _a) internal pure returns (int256) {
    bytes memory bresult = bytes(_a);
    int256 mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
        if (decimals) {
          if (i - 1 - indexOf(bresult, '.') > 6) break;
          mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
        } else {
          mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
        }
      } else if (uint8(bresult[i]) == 46) decimals = true;
    }
    if (indexOf(bresult, '-') == 0) {
      return -mint * int256(multiplier);
    }
    return mint * int256(multiplier);
  }

  /// @notice Finds the index of a substring in a given string.
  /// @param haystack The string to search within.
  /// @param needle The substring to search for.
  /// @return Returns the index of the first occurrence of the substring, or the length of the string if not found.
  function indexOf(bytes memory haystack, string memory needle) internal pure returns (uint) {
    bytes memory bneedle = bytes(needle);
    if (bneedle.length > haystack.length) {
      return haystack.length;
    }

    bool found = false;
    uint i;
    for (i = 0; i <= haystack.length - bneedle.length; i++) {
      found = true;
      for (uint j = 0; j < bneedle.length; j++) {
        if (haystack[i + j] != bneedle[j]) {
          found = false;
          break;
        }
      }
      if (found) {
        break;
      }
    }
    return i;
  }

  function getCeilDays(uint64 startDateTime, uint64 endDateTime) internal pure returns (uint64) {
    uint64 duration = endDateTime - startDateTime;
    return uint64(Math.ceilDiv(duration, 1 days));
  }

  
}