library RentalityUtils {
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


  function toLower(string memory str) public pure returns (string memory) {
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
}