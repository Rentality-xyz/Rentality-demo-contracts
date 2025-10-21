// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../abstract/IRentalityAccessControl.sol';
import '../../proxy/UUPSAccess.sol';
import '../../Schemas.sol';
contract RentalityAggregator is AggregatorV3Interface, Initializable, UUPSAccess {

    uint80 private currentRoundId;
    uint8 private _decimals;
    string private _description;
    uint private _version;
    mapping(uint80 => Schemas.Round) private roundIdToData;

      function decimals() external view returns (uint8) {
        return _decimals;
      }

  function description() external view returns (string memory) {
    return _description;
  }

  function version() external view returns (uint256) {
    return _version;
  }
  function updateAnswer(int256 _answer) public {
    require(userService.isOracleManager(tx.origin), "only Rentality oracle manager");
    currentRoundId++;
    roundIdToData[currentRoundId] = Schemas.Round(_answer, block.timestamp, block.timestamp);
  }

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
    Schemas.Round memory data = roundIdToData[_roundId];
    return (currentRoundId, data.answer, data.startedAt, data.updatedAt, _roundId);
  }

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
         Schemas.Round memory data = roundIdToData[currentRoundId];
             return (currentRoundId, data.answer, data.startedAt, data.updatedAt, currentRoundId);
    }

    function isRentalityAggregator() external pure returns (bool) {
        return true;
    }

    function initialize(
        IRentalityAccessControl _userService, 
        uint8 dec,
        string memory descr,
        int256 answer
        ) public initializer {
        userService = _userService;
        currentRoundId = 1;
        _decimals = dec;
        _description = descr;
        _version = 1;
        roundIdToData[currentRoundId] = Schemas.Round(answer, block.timestamp, block.timestamp);
    }

}