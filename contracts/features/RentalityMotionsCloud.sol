// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import {RentalityUserService} from '../RentalityUserService.sol';



/// @title Rentality MotionsCloud integration service
contract RentalityMotionsCloud is UUPSAccess, EIP712Upgradeable {

    mapping(bytes32 => string) private insuranceCaseToUrl;
    mapping(bytes32 => bool) private caseExists;
    mapping(uint => bytes32) private tripIdToInsuranceCase;
    mapping(bytes32 => uint) private caseToTripId;

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
          tripIdToInsuranceCase[tripId] = hash;
          caseToTripId[hash] = tripId;
    } 
    function getInsuranceCaseUrlByTrip(uint tripId) public view returns(string memory insuranceCaseUrl) {
        return insuranceCaseToUrl[tripIdToInsuranceCase[tripId]];
    }

    function isCaseExists(string memory iCase) public view returns(bool isExists) {
        return caseExists[keccak256(abi.encodePacked(iCase))];
    }


      function initialize(address _userService) public initializer {
        userService = IRentalityAccessControl(_userService);
     }
}

