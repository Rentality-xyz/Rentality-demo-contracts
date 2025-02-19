// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import {RentalityUserService} from '../RentalityUserService.sol';



/// @title Rentality AiDamageAnalyze integration service
contract RentalityAiDamageAnalyze is UUPSAccess, EIP712Upgradeable {

    mapping(bytes32 => string) private insuranceCaseToUrl;
    mapping(bytes32 => bool) private caseExists;
    mapping(uint => string) private tripIdToInsuranceCase;
    mapping(bytes32 => uint) private caseToTripId;
    mapping (uint => string) private caseNumberToCase;
    uint private caseCounter;

    function saveInsuranceCaseUrl(string memory iCase, string memory url) public {
            // require(RentalityUserService(address(userService)).isSignatureManager(tx.origin),"only platform Manager");
            bytes32 hash = keccak256(abi.encodePacked(iCase));
            require(caseExists[hash], "case not exists");
            insuranceCaseToUrl[hash] = url;
    }

    function saveInsuranceCase(string memory iCase, uint tripId) public {
        //   require(userService.isManager(msg.sender), "only Manager");
          bytes32 hash = keccak256(abi.encodePacked(iCase));
          caseExists[hash] = true;
          tripIdToInsuranceCase[tripId] = iCase;
          caseToTripId[hash] = tripId;
          caseCounter += 1;
          caseNumberToCase[caseCounter] = iCase;
    } 
    function getInsuranceCaseUrlByTrip(uint tripId) public view returns(string memory caseUrl) {
        string memory iCase = tripIdToInsuranceCase[tripId];
        return insuranceCaseToUrl[keccak256(abi.encodePacked(iCase))];
    }
    function getInsuranceCaseByTrip(uint tripId) public view returns(string memory iCase) {
        return tripIdToInsuranceCase[tripId];
    }

    function isCaseExists(string memory iCase) public view returns(bool isExists) {
        return caseExists[keccak256(abi.encodePacked(iCase))];
    }

    function getCurrentCaseNumber() public view returns(uint currentCaseNumber) {
        return caseCounter;
    }


      function initialize(address _userService) public initializer {
        userService = IRentalityAccessControl(_userService);
     }
}

