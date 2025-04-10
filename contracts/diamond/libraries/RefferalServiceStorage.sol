// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "./LibDiamond.sol";
import { Schemas } from "../../Schemas.sol";

struct Points {
  bytes4 callback;
  int points;
  int pointsWithRefferalCode;
}
struct TripDiscounts {
  uint host;
  uint guest;
}

library RefferalServiceStorage {
struct RefferalFaucetStorage {
      mapping(address => bytes4) referralHash;
      mapping(bytes4 => address) hashToOwner;
      mapping(Schemas.RefferalProgram => mapping(Schemas.Tear => Schemas.RefferalDiscount))
      selectorToDiscountsPercentsToConstInPoints;
      mapping(Schemas.RefferalProgram => uint) selectorHashToPoints;
      address refferalLib;
      mapping(Schemas.RefferalProgram => mapping(address => bool)) selectorToPassedAddress;
      mapping(Schemas.RefferalProgram => Points) selectorToPoints;
      mapping(Schemas.RefferalProgram => Points) permanentSelectorToPoints;
      mapping(address => uint) addressToLastDailyClaim;
      mapping(uint => uint) carIdToListedClaimTime;
      mapping(Schemas.Tear => Schemas.TearPoints) tearTypeToTearPoints;
      mapping(address => uint) addressToPoints;
      mapping(uint => TripDiscounts) tripIdToDisctount;
      mapping(address => Schemas.ReadyToClaim[]) addressToReadyToClaim;
      mapping(uint => uint) carIdToDailyClaimed;
      mapping(address => Schemas.ProgramHistory[]) userProgramHistory;

      mapping(address => Schemas.ReadyToClaimFromHash[]) userToReadyToClaimFromHash;

     mapping(address => bytes4) userToSavedHash;
}

 function createReferralHash(address user) internal pure returns (bytes4 createdHash) {
    return bytes4(keccak256(abi.encode(bytes4(0x006c166a), user)));
  }
  function generateReferralHash(address user) internal {
    RefferalFaucetStorage storage s = accessStorage();
    
    bytes4 hash = createReferralHash(user);
    s.hashToOwner[hash] = user;
    s.referralHash[user] = hash;
  }


  function passReferralProgram(
    Schemas.RefferalProgram selector,
    bytes memory callbackArgs,
    address user
  ) internal {
    RefferalFaucetStorage storage s = accessStorage();
    bytes4 hash = s.userToSavedHash[user];

    (address owner, uint hashPoints) = _getHashProgramInfoIfExists(s, selector, hash, user);

    (int points, bool isOneTime) = _setPassedIfExists(s, selector, callbackArgs, owner != address(0), user);
    if (points > 0) {
      if (isOneTime && hashPoints > 0) {
        s.userToReadyToClaimFromHash[owner].push(
          Schemas.ReadyToClaimFromHash(uint(hashPoints), selector, isOneTime, false, user)
        );
      }
    //   try promoService.useRefferalPromo(hash, user) returns (uint refPoints) {
    //     if (refPoints > 0) points = int(refPoints);
    //   } catch {}

      s.addressToReadyToClaim[user].push(Schemas.ReadyToClaim(uint(points), selector, isOneTime));
    } else if (points < 0) {
      uint pointsToReduce = uint(-points);
      if (s.addressToPoints[user] < pointsToReduce) s.addressToPoints[user] = 0;
      else s.addressToPoints[user] -= pointsToReduce;
      s.userProgramHistory[user].push(Schemas.ProgramHistory(points, block.timestamp, selector, isOneTime));
    }
  }

    function saveRefferalHash(bytes4 hash, bool isGuest, address sender) internal {
    RefferalFaucetStorage storage s = accessStorage();
    address user = s.hashToOwner[hash];
    if (!isGuest && hash != bytes4('') && user != address(0) && user != sender) {
      s.userToSavedHash[sender] = hash;
    }
  }

  function _getHashProgramInfoIfExists(
    RefferalFaucetStorage storage s,
    Schemas.RefferalProgram programSelector,
    bytes4 hash,
    address user
  ) private view returns (address, uint) {
    require(createReferralHash(user) != hash, 'own hash');
    (address resultAddress, uint resultPoints) = (address(0), 0);
    if (s.selectorHashToPoints[programSelector] > 0) {
      (resultAddress, resultPoints) = (s.hashToOwner[hash], s.selectorHashToPoints[programSelector]);
    }
    return (resultAddress, resultPoints);
  }

    function _setPassedIfExists(
    RefferalFaucetStorage storage s,
    Schemas.RefferalProgram selector,
    bytes memory callbackArgs,
    bool hasRefferalCode,
    address user
  ) private returns (int, bool) {
    Points memory points = s.selectorToPoints[selector];

    bool isOneTime = true;
    if (points.points != 0) {
      bool passed = s.selectorToPassedAddress[selector][user];
      if (passed) {
        points = s.permanentSelectorToPoints[selector];
        isOneTime = false;
      } else {
        s.selectorToPassedAddress[selector][user] = true;
        if (hasRefferalCode) points.points = points.pointsWithRefferalCode;
      }
    } else {
      points = s.permanentSelectorToPoints[selector];
      isOneTime = false;
    }
    if (points.callback != bytes4('')) {
      (bool ok, bytes memory callbackResult) = s.refferalLib.staticcall(
        abi.encodeWithSelector(points.callback, points.points, callbackArgs)
      );
      require(ok, 'Fail to calculate points');
      points.points = abi.decode(callbackResult, (int));
    }
    return (points.points, isOneTime);
  }

  function addOneTimeProgram(Schemas.RefferalProgram selector, int points, int refPoints, bytes4 calback) internal {
    RefferalFaucetStorage storage s = accessStorage();
    Points storage oldPoints = s.selectorToPoints[selector];

    oldPoints.callback = calback;
    oldPoints.points = points;
    oldPoints.pointsWithRefferalCode = refPoints;
  }

    function addPermanentProgram(Schemas.RefferalProgram selector, int points, bytes4 calback) internal {
    RefferalFaucetStorage storage s = accessStorage();

    Points storage oldPoints = s.permanentSelectorToPoints[selector];

    oldPoints.callback = calback;
    oldPoints.points = points;
  }

   function manageRefHashesProgram(Schemas.RefferalProgram selector, uint points) internal {
    RefferalFaucetStorage storage s = accessStorage();
    s.selectorHashToPoints[selector] = points;
  }

    function manageRefferalDiscount(
    Schemas.RefferalProgram selector,
    Schemas.Tear tear,
    uint points,
    uint percents
  ) internal {
    RefferalFaucetStorage storage s = accessStorage();
    s.selectorToDiscountsPercentsToConstInPoints[selector][tear] = Schemas.RefferalDiscount(points, percents);
  }

    function manageTearInfo(Schemas.Tear tear, uint from, uint to) internal {
    RefferalFaucetStorage storage s = accessStorage();
    s.tearTypeToTearPoints[tear] = Schemas.TearPoints(from, to);
  }

   function accessStorage() internal pure returns (RefferalFaucetStorage storage ds) {
        bytes32 position = LibDiamond.REFFERAL_STORAGE_POSSITION;
        assembly { ds.slot := position }
    }


}