// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import {RentalityUserService} from '../RentalityUserService.sol';
import '../Schemas.sol';



/// @title Rentality AiDamageAnalyze integration service
contract RentalityAiDamageAnalyze is UUPSAccess, EIP712Upgradeable {

    mapping(bytes32 => string) private insuranceCaseToUrl;
    mapping(bytes32 => bool) private caseExists;
    mapping(bytes32 => uint) private caseToCaseCounter;
    mapping (uint => Schemas.InsuranceCase) private caseCounterToCase;
    mapping(uint => uint) private caseCounterToTripId;
    mapping(uint => Schemas.TripInsuranceCases) private tripIdsToTripCases;
    uint private caseCounter;
function getInsuranceCaseUrl(string memory iCase) public view returns(string memory url) {

return insuranceCaseToUrl[keccak256(abi.encodePacked(iCase))];
}
    function saveInsuranceCaseUrl(string memory iCase, string memory url) public {
            // require(RentalityUserService(address(userService)).isSignatureManager(tx.origin),"only platform Manager");
            bytes32 hash = keccak256(abi.encodePacked(iCase));
            require(caseExists[hash], "case not exists");
            insuranceCaseToUrl[hash] = url;
    }

    function saveInsuranceCase(string memory iCase, uint tripId, bool pre) public {
        //   require(userService.isRentalityPlatform(msg.sender), "only Rentality platform");
          bytes32 hash = keccak256(abi.encodePacked(iCase));
          caseExists[hash] = true;
        
          caseCounter += 1;
          caseCounterToCase[caseCounter] = Schemas.InsuranceCase(iCase, pre);
          caseCounterToTripId[caseCounter] = tripId;
          if(pre)
          tripIdsToTripCases[tripId].pre = caseCounter;
          else 
          tripIdsToTripCases[tripId].post = caseCounter;
    }
    function getInsuranceCasesUrlByTrip(uint tripId) public view returns(Schemas.InsuranceCaseDTO[] memory caseUrls) {
        uint insuranceCasesByTrip = 0;
        Schemas.TripInsuranceCases memory tripInsurances = tripIdsToTripCases[tripId];
        if(tripInsurances.pre > 0)
        insuranceCasesByTrip += 1;
        if(tripInsurances.post > 0)
         insuranceCasesByTrip += 1;

        Schemas.InsuranceCaseDTO[] memory cases = new Schemas.InsuranceCaseDTO[](insuranceCasesByTrip);

        uint withUrlCounter = 0;
           if(tripInsurances.pre > 0)
       {
        Schemas.InsuranceCase memory insuranceCase = caseCounterToCase[tripInsurances.pre];
                cases[withUrlCounter] = Schemas.InsuranceCaseDTO(
                  insuranceCase,
                  insuranceCaseToUrl[keccak256(abi.encodePacked(insuranceCase.iCase))]
                  );
                withUrlCounter += 1;
       }
        if(tripInsurances.post > 0)
      {
        Schemas.InsuranceCase memory insuranceCase = caseCounterToCase[tripInsurances.post];
                cases[withUrlCounter] = Schemas.InsuranceCaseDTO(
                  insuranceCase,
                  insuranceCaseToUrl[keccak256(abi.encodePacked(insuranceCase.iCase))]
                  );
                withUrlCounter += 1;
       }

        return cases;
    }
    function getInsuranceCaseByTrip(uint tripId, bool pre) public view returns(string memory iCases) {
     Schemas.TripInsuranceCases memory tripInsurances = tripIdsToTripCases[tripId];
     return pre ? caseCounterToCase[tripInsurances.pre].iCase :
                 caseCounterToCase[tripInsurances.post].iCase;
    
    }

    function isCaseExists(string memory iCase) public view returns(bool isExists) {
        return caseExists[keccak256(abi.encodePacked(iCase))];
    }

    function getCurrentCaseNumber() public view returns(uint currentCaseNumber) {
        return caseCounter;
    }


      function initialize(address _userService) public initializer {
        userService = IRentalityAccessControl(_userService);
        __EIP712_init('RentalityAiDamageAnalyze', '1');
     }
}

