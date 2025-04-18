// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Schemas} from "../../../Schemas.sol";
import {RefferalServiceStorage} from "../../libraries/RefferalServiceStorage.sol";
import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {RentalityRefferalLib} from "../../libraries/getters/RentalityRefferalLib.sol";

contract RentalityRefferalService {

function addressToPoints(address user) public view returns (uint points) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return s.addressToPoints[user];
  }

  function referralHashV2(address user) public view returns (bytes4 hash) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return s.referralHashV2[user];
  }

function claimPoints(address user) public {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaim[] memory toClaim = RefferalFaucetStorage.addressToReadyToClaim[user];
    uint daily = updateDaily(user);
    (uint dailiListingPoints, uint[] memory cars) = RentalityRefferalLib.calculateListedCarsPoints(
      s.permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
      user,
      this
    );
    uint total = 0;
    if (dailiListingPoints > 0) {
      uint time = block.timestamp;
      for (uint i = 0; i < cars.length; i++) {
        s.carIdToDailyClaimed[cars[i]] = time;
      }
      s.userProgramHistory[user].push(
        Schemas.ProgramHistory(int(dailiListingPoints), block.timestamp, Schemas.RefferalProgram.DailyListing, false)
      );
      total += dailiListingPoints;
    }
    if (toClaim.length > 0) {
      s.addressToReadyToClaim[user] = new Schemas.ReadyToClaim[](0);
      for (uint i = 0; i < toClaim.length; i++) {
        total += toClaim[i].points;
        s.userProgramHistory[user].push(
          Schemas.ProgramHistory(int(toClaim[i].points), block.timestamp, toClaim[i].refType, toClaim[i].oneTime)
        );
      }
    }
    if (daily > 0) {
      s.userProgramHistory[user].push(
        Schemas.ProgramHistory(int(daily), block.timestamp, Schemas.RefferalProgram.Daily, false)
      );
      total += daily;
    }

    s.addressToPoints[user] += total;
  }

  function getReadyToClaim(address user) public view returns (Schemas.ReadyToClaimDTO memory readyToClaimDTO) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaim[] memory availableToClaim = s.addressToReadyToClaim[user];
    uint len = availableToClaim.length;
    uint daily = RentalityRefferalLib._checkDaily(user);
    uint toNextDaily = 0;
    if (daily > 0) {
      len += 1;
    }
    (uint dailiListingPoints, ) = RentalityRefferalLib.calculateListedCarsPoints(
      s.permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
      user,
      this
    );
    if (dailiListingPoints > 0) len += 1;

    Schemas.ReadyToClaim[] memory result = new Schemas.ReadyToClaim[](len);
    uint counter = 0;
    uint index = 0;
    for (uint i = 0; i < availableToClaim.length; i++) {
      counter += availableToClaim[i].points;
      result[index] = availableToClaim[i];
      index += 1;
    }

    if (daily > 0) {
      result[index] = Schemas.ReadyToClaim(daily, Schemas.RefferalProgram.Daily, false);
      counter += daily;
      index += 1;
    } else toNextDaily = block.timestamp + 1 days - s.addressToLastDailyClaim[user];

    if (dailiListingPoints > 0) {
      counter += dailiListingPoints;
      result[index] = Schemas.ReadyToClaim(dailiListingPoints, Schemas.RefferalProgram.DailyListing, false);
    }

    return RentalityRefferalLib.formatReadyToClaim(Schemas.ReadyToClaimDTO(result, counter, toNextDaily), this);
  }

  function getReadyToClaimFromRefferalHash(
    address user
  ) public view returns (Schemas.RefferalHashDTO memory refferalHashDTO) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaimFromHash[] memory availableToClaim = s.userToReadyToClaimFromHash[user];
    uint counter = 0;
    for (uint i = 0; i < availableToClaim.length; i++) {
      if (!availableToClaim[i].claimed) counter += availableToClaim[i].points;
    }
    bytes4 hash = referralHashV2[user];
    return Schemas.RefferalHashDTO(availableToClaim, counter, hash);
  }

  function claimRefferalPoints(address user) public {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaimFromHash[] memory availableToClaim = s.userToReadyToClaimFromHash[user];
    if (availableToClaim.length > 0) {
      uint total = 0;
      for (uint i = 0; i < availableToClaim.length; i++) {
        if (!availableToClaim[i].claimed) {
          total += availableToClaim[i].points;
          s.userToReadyToClaimFromHash[user][i].claimed = true;
        }
      }
      s.addressToPoints[user] += total;
    }
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
    return Schemas.AllRefferalInfoDTO(refferalPoints, hashPoints, discounts, RentalityRefferalLib.getAllTearsInfo());
  }
  function getPointsHistory() public view returns (Schemas.ProgramHistory[] memory programHistory) {
     RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return s.userProgramHistory[msg.sender];
  }


  function createReferralHash(address user) internal pure returns (bytes4 createdHash) {
    return bytes4(keccak256(abi.encode(this.generateReferralHash.selector, user)));
  }
  function getMyRefferalInfo() public view returns (Schemas.MyRefferalInfoDTO memory myRefferalInfoDTO) {
     RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return Schemas.MyRefferalInfoDTO(s.referralHashV2[msg.sender], s.userToSavedHash[msg.sender]);
  }
 
  
  function _getHashProgramInfoIfExists(
    Schemas.RefferalProgram programSelector,
    bytes4 hash,
    address user
  ) internal view returns (address, uint) {
    require(createReferralHash(user) != hash, 'own hash');
     RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    (address resultAddress, uint resultPoints) = (address(0), 0);
    if (s.selectorHashToPoints[programSelector] > 0) {
      (resultAddress, resultPoints) = (s.hashToOwnerV2[hash], s.selectorHashToPoints[programSelector]);
    }
    return (resultAddress, resultPoints);
  }

  function updateLib(address refLib) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    s.refferalLib = refLib;
  }
}