// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {UUPSAccess} from '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import {RentalityUserService} from '../RentalityUserService.sol';
import '../Schemas.sol';

/// @title Rentality AiDamageAnalyze integration service
contract RentalityAiDamageAnalyzeV2 is UUPSAccess, EIP712Upgradeable {
  uint private caseId;

  mapping(uint => Schemas.CaseInfo) private caseIdToCaseInfo;
  mapping(bytes32 => Schemas.CaseTokenInfo) private caseTokenToCaseTokenInfo;
  mapping(uint => Schemas.CaseInfo[]) private tripIdsToCaseInfos;

  function getLatestCaseId() public view returns (uint latestCaseId) {
    return caseId;
  }

  function getReportUrl(string memory caseToken) public view returns (string memory url) {
    return caseTokenToCaseTokenInfo[keccak256(abi.encodePacked(caseToken))].url;
  }

  function isCaseTokenExists(string memory caseToken) public view returns (bool isExist) {
    return caseTokenToCaseTokenInfo[keccak256(abi.encodePacked(caseToken))].caseId > 0;
  }

  function getCasesByTripId(uint tripId) public view returns (Schemas.AiDamageAnalyzeCaseDTO[] memory aiDamageAnalyzeCases) {
    Schemas.CaseInfo[] memory tripCases = tripIdsToCaseInfos[tripId];

    aiDamageAnalyzeCases = new Schemas.AiDamageAnalyzeCaseDTO[](tripCases.length);
    for (uint i = 0; i < tripCases.length; i++) {
      bytes32 hash = keccak256(abi.encodePacked(tripCases[i].caseToken));
      aiDamageAnalyzeCases[i] = Schemas.AiDamageAnalyzeCaseDTO(
        tripCases[i].caseId,
        tripCases[i].caseType,
        tripCases[i].caseToken,
        caseTokenToCaseTokenInfo[hash].url
      );
    }

    return aiDamageAnalyzeCases;
  }

  function getInsuranceCaseByTrip(uint tripId, Schemas.CaseType caseType) public view returns (string memory iCases) {
    Schemas.CaseInfo[] memory tripCases = tripIdsToCaseInfos[tripId];

    for (uint i = 0; i < tripCases.length; i++) {
      if (tripCases[i].caseType == caseType) {
        return tripCases[i].caseToken;
      }
    }
    return '';
  }

  function saveInsuranceCaseUrl(string memory iCase, string memory url) public {
    require(RentalityUserService(address(userService)).isSignatureManager(tx.origin), 'only platform Manager');
    bytes32 hash = keccak256(abi.encodePacked(iCase));
    require(isCaseTokenExists(iCase), 'case not exists');
    caseTokenToCaseTokenInfo[hash].url = url;
    caseTokenToCaseTokenInfo[hash].updateDate = block.timestamp;
  }

  function saveInsuranceCase(string memory iCase, uint tripId, Schemas.CaseType caseType) public {
    //   require(userService.isRentalityPlatform(msg.sender), "only Rentality platform");
    bytes32 hash = keccak256(abi.encodePacked(iCase));

    caseId += 1;
    Schemas.CaseInfo memory caseInfo = Schemas.CaseInfo(caseId, tripId, iCase, block.timestamp, caseType);
    tripIdsToCaseInfos[tripId].push(caseInfo);
    caseTokenToCaseTokenInfo[hash] = Schemas.CaseTokenInfo(caseId, 0, '');
  }

  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    __EIP712_init('RentalityAiDamageAnalyze', '1');
  }
}
