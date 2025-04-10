// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Schemas} from "../../../Schemas.sol";
import {RefferalServiceStorage, Points} from "../../libraries/RefferalServiceStorage.sol";
import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {RentalityRefferalLibDiamond} from "../../libraries/getters/RentalityRefferalLibDiamond.sol";

contract RentalityRefferalServiceFacet {

function claimPoints(address user) public {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaim[] memory toClaim = s.addressToReadyToClaim[user];
    uint daily = updateDaily(user);
    (uint dailiListingPoints, uint[] memory cars) = RentalityRefferalLibDiamond.calculateListedCarsPoints(
      s.permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
      user
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

  function updateDaily(address user) private returns (uint) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    uint result = 0;
    uint last = s.addressToLastDailyClaim[user];
    uint current = block.timestamp;
    if (current >= last + 1 days) {
      s.addressToLastDailyClaim[user] = block.timestamp;
      result = uint(s.permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }

  function getReadyToClaim(address user) public view returns (Schemas.ReadyToClaimDTO memory readyToClaimDTO) {
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaim[] memory availableToClaim = s.addressToReadyToClaim[user];
    uint len = availableToClaim.length;
    uint daily = RentalityRefferalLibDiamond._checkDaily(user);
    uint toNextDaily = 0;
    if (daily > 0) {
      len += 1;
    }
    (uint dailiListingPoints, ) = RentalityRefferalLibDiamond.calculateListedCarsPoints(
      s.permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
      user
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

    return formatReadyToClaim(Schemas.ReadyToClaimDTO(result, counter, toNextDaily));
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
    bytes4 hash = s.referralHash[user];
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

  function getPointsHistory() public view returns (Schemas.ProgramHistory[] memory programHistory) {
     RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return s.userProgramHistory[msg.sender];
  }


  function createReferralHash(address user) internal pure returns (bytes4 createdHash) {
    return bytes4(keccak256(abi.encode("generateReferralHash(address)", user)));
  }
  function getMyRefferalInfo() public view returns (Schemas.MyRefferalInfoDTO memory myRefferalInfoDTO) {
     RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    return Schemas.MyRefferalInfoDTO(s.referralHash[msg.sender], s.userToSavedHash[msg.sender]);
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
      (resultAddress, resultPoints) = (s.hashToOwner[hash], s.selectorHashToPoints[programSelector]);
    }
    return (resultAddress, resultPoints);
  }

  function updateLib(address refLib) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    s.refferalLib = refLib;
  }

  function addOneTimeProgram(Schemas.RefferalProgram selector, int points, int refPoints, bytes4 calback) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.addOneTimeProgram(selector, points, refPoints, calback);
  }

    function addPermanentProgram(Schemas.RefferalProgram selector, int points, bytes4 calback) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.addPermanentProgram(selector, points, calback);
  }

   function manageRefHashesProgram(Schemas.RefferalProgram selector, uint points) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.manageRefHashesProgram(selector, points);
  }

    function manageRefferalDiscount(
    Schemas.RefferalProgram selector,
    Schemas.Tear tear,
    uint points,
    uint percents
  ) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.manageRefferalDiscount(
      selector,
      tear,
      points,
      percents
    );
    }

    function manageTearInfo(Schemas.Tear tear, uint from, uint to) public {
    require(UserServiceStorage.isAdmin(msg.sender), 'only Admin');
    RefferalServiceStorage.manageTearInfo(tear, from, to);
  }

    function formatReadyToClaim(
    Schemas.ReadyToClaimDTO memory toClaim
  ) private view returns (Schemas.ReadyToClaimDTO memory) {
    Schemas.ReadyToClaim[] memory claim = getEmptyToClaim();
    // for (uint i = 0; i < uint(type(Schemas.RefferalProgram).max); i++) {
    //   claim[i].refType = Schemas.RefferalProgram(i);
    // }
    for (uint i = 0; i < claim.length; i++) {
      for (uint j = 0; j < toClaim.toClaim.length; j++)
        if (claim[i].refType == toClaim.toClaim[j].refType && claim[i].oneTime == toClaim.toClaim[j].oneTime) {
          claim[i].points += toClaim.toClaim[j].points;
        }
    }

    toClaim.toClaim = claim;
    return toClaim;
  }

  function getEmptyToClaim() private view returns (Schemas.ReadyToClaim[] memory) {
   RefferalServiceStorage.RefferalFaucetStorage storage s = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaim[] memory programs;
    uint counter = 0;
    uint max = uint(type(Schemas.RefferalProgram).max) + 1;
    for (uint i = 0; i < max; i++) {
      Schemas.RefferalProgram program = Schemas.RefferalProgram(i);

      if (s.selectorToPoints[program].points != 0) counter += 1;

      if (s.permanentSelectorToPoints[program].points != 0) counter += 1;
    }
    programs = new Schemas.ReadyToClaim[](counter);
    uint index = 0;
    for (uint i = 0; i < max; i++) {
      if (s.permanentSelectorToPoints[Schemas.RefferalProgram(i)].points != 0) {
        programs[index].refType = Schemas.RefferalProgram(i);
        programs[index].oneTime = false;
        index += 1;
      }
    }
    for (uint i = 0; i < max; i++) {
      if (s.selectorToPoints[Schemas.RefferalProgram(i)].points != 0) {
        programs[index].refType = Schemas.RefferalProgram(i);
        programs[index].oneTime = true;
        index += 1;
      }
    }
    return programs;
  }

}