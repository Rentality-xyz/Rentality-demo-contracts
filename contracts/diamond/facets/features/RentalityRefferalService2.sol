// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Schemas} from "../../../Schemas.sol";
import {RefferalServiceStorage, Points} from "../../libraries/RefferalServiceStorage.sol";
import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {RentalityRefferalLibDiamond} from "../../libraries/getters/RentalityRefferalLibDiamond.sol";

contract RentalityRefferalServiceFacet2 {
    function addressToPoints(address user) public view returns (uint points) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return s.addressToPoints[user];
  }

  function referralHash(address user) public view returns (bytes4 hash) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return s.referralHash[user];
  }

  function getRefferalPointsInfo() public view returns (Schemas.AllRefferalInfoDTO memory allRefferalInfoDTO) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    uint pointsCounter = 0;
    uint hashCounter = 0;
    uint discountCounter = 0;

    for (uint i = 0; i <= uint(type(Schemas.RefferalProgram).max); i++) {
      Schemas.RefferalProgram program = Schemas.RefferalProgram(i);
      if (s.selectorToPoints[program].points != 0) pointsCounter += 1;
      if (s.permanentSelectorToPoints[program].points != 0) pointsCounter += 1;
      if (s.selectorHashToPoints[program] != 0) hashCounter += 1;
      if (s.selectorToDiscountsPercentsToConstInPoints[program][Schemas.Tear.Tear2].percents != 0) discountCounter += 3;
    }
    Schemas.RefferalProgramInfoDTO[] memory refferalPoints = new Schemas.RefferalProgramInfoDTO[](pointsCounter);
    Schemas.HashPointsDTO[] memory hashPoints = new Schemas.HashPointsDTO[](hashCounter);
    Schemas.RefferalDiscountsDTO[] memory discounts = new Schemas.RefferalDiscountsDTO[](discountCounter);

    pointsCounter = 0;
    hashCounter = 0;
    discountCounter = 0;
    for (uint i = 0; i <= uint(type(Schemas.RefferalProgram).max); i++) {
      Schemas.RefferalProgram program = Schemas.RefferalProgram(i);
      int oneTimePoints = s.selectorToPoints[program].points;
      if (oneTimePoints != 0) {
        refferalPoints[pointsCounter] = Schemas.RefferalProgramInfoDTO(
          Schemas.RefferalAccrualType.OneTime,
          program,
          oneTimePoints
        );
        pointsCounter += 1;
      }
      int permanentPoints = s.permanentSelectorToPoints[program].points;
      if (permanentPoints != 0) {
        refferalPoints[pointsCounter] = Schemas.RefferalProgramInfoDTO(
          Schemas.RefferalAccrualType.Permanent,
          program,
          permanentPoints
        );
        pointsCounter += 1;
      }
      uint refHashPoints = s.selectorHashToPoints[program];
      if (refHashPoints != 0) {
        hashPoints[hashCounter] = Schemas.HashPointsDTO(program, refHashPoints);
        hashCounter += 1;
      }
      if (s.selectorToDiscountsPercentsToConstInPoints[program][Schemas.Tear.Tear2].percents != 0)
        for (uint j = 1; j <= uint(type(Schemas.Tear).max); j++) {
          Schemas.Tear tear = Schemas.Tear(j);
          discounts[discountCounter] = Schemas.RefferalDiscountsDTO(
            program,
            tear,
            (s.selectorToDiscountsPercentsToConstInPoints[program][tear])
          );
          discountCounter += 1;
        }
    }
    return Schemas.AllRefferalInfoDTO(refferalPoints, hashPoints, discounts, getAllTearsInfo());
  }

     function getAllTearsInfo() private view returns (Schemas.TearDTO[] memory) {
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    Schemas.TearDTO[] memory tears = new Schemas.TearDTO[](uint(type(Schemas.Tear).max) + 1);
    for (uint i = 0; i <= uint(type(Schemas.Tear).max); i++) {
      Schemas.Tear tear = Schemas.Tear(i);
      tears[i] = Schemas.TearDTO(RefferalServiceStorage.tearTypeToTearPoints[tear], tear);
    }
    return tears;
  }

}