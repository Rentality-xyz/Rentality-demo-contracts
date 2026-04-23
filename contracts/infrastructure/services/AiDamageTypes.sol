// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct CaseTokenInfo {
  uint256 caseId;
  uint256 updateDate;
  string url;
}

enum CaseType {
  PreTrip,
  PostTrip
}

struct CaseInfo {
  uint256 caseId;
  uint256 tripId;
  string caseToken;
  uint256 createDate;
  CaseType caseType;
}

struct AiDamageAnalyzeCaseDTO {
  uint256 caseId;
  CaseType caseType;
  string caseToken;
  string url;
}

struct AiDamageAnalyzeCaseRequestDTO {
  uint256 lastCaseId;
  string email;
  string name;
  string caseToken;
  string vin;
}

struct InsuranceCase {
  string iCase;
  bool pre;
}

struct InsuranceCaseDTO {
  InsuranceCase iCase;
  string url;
}

struct TripInsuranceCases {
  uint256 pre;
  uint256 post;
}
