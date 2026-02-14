// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import '@openzeppelin/contracts/utils/Strings.sol';
library RentalityUtils2 {


       function createSumbol(uint tokenId) public view returns (string memory) {
    (uint month, uint year) = _getMonthAndYear();
    string memory monthResult;

    if (month < 10) monthResult = string.concat('0', Strings.toString(month));
    else monthResult = Strings.toString(month);

    return
      string.concat(
        string.concat(string.concat('RENTALITY', '-00000'), Strings.toString(tokenId)),
        string.concat('-', string.concat(string.concat(monthResult, Strings.toString(year % 100))))
      );
  }
    function _getMonthAndYear() private view returns (uint month, uint year) {
    uint timestamp = block.timestamp;
    int256 z = int256(timestamp / 86400 + 719468);

    int256 era = (z >= 0 ? z : z - 146096) / 146097;

    int256 doe = z - era * 146097;

    int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;

    year = uint256(yoe) + uint256(era) * 400;

    int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);

    int256 mp = (5 * doy + 2) / 153;

    month = uint256(mp + 3);

    if (month > 12) {
      month -= 12;

      year += 1;
    }
  }
}