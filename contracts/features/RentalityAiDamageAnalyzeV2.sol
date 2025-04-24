// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import {RentalityUserService} from '../RentalityUserService.sol';
import '../Schemas.sol';

struct CaseTokenInfo {
  uint caseId;
  uint updateDate;
  string url;
}

enum CaseType {
  PreTrip,
  PostTrip
}

struct CaseInfo {
  uint caseId;
  uint tripId;
  string caseToken;
  uint createDate;
  CaseType caseType;
}

struct AiDamageAnalyzeCaseDTO {
  uint caseId;
  CaseType caseType;
  string caseToken;
  string url;
}

/// @title Rentality AiDamageAnalyze integration service
contract RentalityAiDamageAnalyzeV2 is UUPSAccess, EIP712Upgradeable {
  // caseId - id of case in blockchain
  // caseToken - id(token) genereted by Ai Damage Analyze API
  uint private caseIdCounter;

  mapping(uint => CaseInfo) private caseIdToCaseInfo;
  mapping(bytes32 => CaseTokenInfo) private caseTokenToCaseTokenInfo;
  mapping(uint => CaseInfo[]) private tripIdsToCaseInfos;

  function getLatestCaseId() public view returns (uint latestCaseId) {
    return caseIdCounter;
  }

  function getReportUrl(string memory caseToken) public view returns (string memory url) {
    return caseTokenToCaseTokenInfo[keccak256(abi.encodePacked(caseToken))].url;
  }

  function isCaseTokenExists(string memory caseToken) public view returns (bool isExist) {
    return caseTokenToCaseTokenInfo[keccak256(abi.encodePacked(caseToken))].caseId > 0;
  }

  // TripId отримати всі кейси з URL
  //

  function getCasesByTripId(uint tripId) public view returns (AiDamageAnalyzeCaseDTO[] memory aiDamageAnalyzeCases) {
    uint insuranceCasesByTrip = 0;
    Schemas.TripInsuranceCases memory tripInsurances = tripIdsToTripCases[tripId];
    if (tripInsurances.pre > 0) insuranceCasesByTrip += 1;
    if (tripInsurances.post > 0) insuranceCasesByTrip += 1;

    Schemas.InsuranceCaseDTO[] memory cases = new Schemas.InsuranceCaseDTO[](insuranceCasesByTrip);

    uint withUrlCounter = 0;
    if (tripInsurances.pre > 0) {
      Schemas.InsuranceCase memory insuranceCase = caseCounterToCase[tripInsurances.pre];
      cases[withUrlCounter] = Schemas.InsuranceCaseDTO(
        insuranceCase,
        insuranceCaseToUrl[keccak256(abi.encodePacked(insuranceCase.iCase))]
      );
      withUrlCounter += 1;
    }
    if (tripInsurances.post > 0) {
      Schemas.InsuranceCase memory insuranceCase = caseCounterToCase[tripInsurances.post];
      cases[withUrlCounter] = Schemas.InsuranceCaseDTO(
        insuranceCase,
        insuranceCaseToUrl[keccak256(abi.encodePacked(insuranceCase.iCase))]
      );
      withUrlCounter += 1;
    }

    return cases;
  }

  function saveInsuranceCaseUrl(string memory iCase, string memory url) public {
    // require(RentalityUserService(address(userService)).isSignatureManager(tx.origin),"only platform Manager");
    bytes32 hash = keccak256(abi.encodePacked(iCase));
    require(caseExists[hash], 'case not exists');
    insuranceCaseToUrl[hash] = url;
  }

  function saveInsuranceCase(string memory iCase, uint tripId, bool pre) public {
    //   require(userService.isRentalityPlatform(msg.sender), "only Rentality platform");
    bytes32 hash = keccak256(abi.encodePacked(iCase));
    caseExists[hash] = true;

    caseCounter += 1;
    caseCounterToCase[caseCounter] = Schemas.InsuranceCase(iCase, pre);
    caseCounterToTripId[caseCounter] = tripId;
    if (pre) tripIdsToTripCases[tripId].pre = caseCounter;
    else tripIdsToTripCases[tripId].post = caseCounter;
  }

  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    __EIP712_init('RentalityAiDamageAnalyze', '1');
  }
}
