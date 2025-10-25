// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../abstract/IRentalityAccessControl.sol';
import '../../proxy/UUPSAccess.sol';
import '../RentalityCurrencyConverter.sol';
import './RentalityAggregator.sol';
import '../../Schemas.sol';

contract RentalityBatchPriceUpdater is UUPSAccess, Initializable {

    function updatePrices(Schemas.OracleUpdate[] memory oracleUpdate) public {
            require(userService.isOracleManager(msg.sender), "only Rentality oracle manager");
            for(uint i = 0; i < oracleUpdate.length; i++) {
            require(RentalityAggregator(oracleUpdate[i].feed).isRentalityAggregator(),"is not a Rentality aggregator");
            RentalityAggregator(oracleUpdate[i].feed).updateAnswer(oracleUpdate[i].answer);
        }
    }

     function initialize(
        IRentalityAccessControl _userService
        ) public initializer {
        userService = _userService;
        }


}