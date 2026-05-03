// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../infrastructure/services/ai-damage/AiDamageTypes.sol';
import '../infrastructure/upgradeable/UUPSOwnable.sol';

contract RentalityAiDamageAnalyzeV2 is UUPSOwnable {
  address public userAccess;
  uint256 private latestCaseId;
  mapping(bytes32 => uint256) private caseTokenToCaseId;
  mapping(string => string) private caseTokenToUrl;
  mapping(uint256 => mapping(CaseType => string)) private tripCaseTokens;
  mapping(uint256 => AiDamageAnalyzeCaseDTO[]) private tripCases;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = userAccessAddress;
  }

  function getLatestCaseId() external view returns (uint256) {
    return latestCaseId;
  }

  function getCaseTokenForTrip(uint256 tripId, CaseType caseType) external view returns (string memory caseToken) {
    return tripCaseTokens[tripId][caseType];
  }

  function getCasesByTripId(uint256 tripId) external view returns (AiDamageAnalyzeCaseDTO[] memory) {
    return tripCases[tripId];
  }

  function getReportUrl(string memory caseToken) external view returns (string memory url) {
    return caseTokenToUrl[caseToken];
  }

  function isCaseTokenExists(string memory caseToken) external view returns (bool isExist) {
    return caseTokenToCaseId[keccak256(bytes(caseToken))] != 0;
  }

  function saveInsuranceCase(string memory caseToken, uint256 tripId, CaseType caseType) external {
    bytes32 key = keccak256(bytes(caseToken));
    uint256 caseId = caseTokenToCaseId[key];

    if (caseId == 0) {
      latestCaseId += 1;
      caseId = latestCaseId;
      caseTokenToCaseId[key] = caseId;
    }

    tripCaseTokens[tripId][caseType] = caseToken;
    tripCases[tripId].push(AiDamageAnalyzeCaseDTO(caseId, caseType, caseToken, caseTokenToUrl[caseToken]));
  }

  function saveInsuranceCaseUrl(string memory caseToken, string memory url) external {
    caseTokenToUrl[caseToken] = url;
    bytes32 key = keccak256(bytes(caseToken));
    uint256 caseId = caseTokenToCaseId[key];

    if (caseId == 0) {
      latestCaseId += 1;
      caseId = latestCaseId;
      caseTokenToCaseId[key] = caseId;
    }
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = userAccessAddress;
  }
}
