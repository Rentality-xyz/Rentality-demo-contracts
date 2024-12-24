// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ARentalityRefferalHasher} from './ARentalityRefferalHasher.sol';
import {ARentalityRefferalPointsSetter} from './ARentalityRefferalPointsSetter.sol';
import {ARentalityRefferalDiscountProvider} from './ARentalityRefferalDiscountProvider.sol';
import '../../Schemas.sol';
import '../../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {RentalityCarToken} from '../../RentalityCarToken.sol';
import {RentalityTripService} from '../../RentalityTripService.sol';
import {RentalityUserService} from '../../RentalityUserService.sol';
import {RentalityRefferalLib} from '../../libs/RentalityRefferalLib.sol';
import {ARentalityRefferalTear} from './ARentalityRefferalTear.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';
import '../../Schemas.sol';

struct TripDiscounts {
  uint host;
  uint guest;
}

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityReferralProgram is
  ARentalityRefferalPointsSetter,
  ARentalityRefferalHasher,
  ARentalityRefferalDiscountProvider,
  ARentalityRefferalTear,
  Initializable,
  UUPSAccess
{
  mapping(address => uint) public addressToPoints;
  mapping(uint => TripDiscounts) private tripIdToDisctount;
  mapping(address => Schemas.ReadyToClaim[]) private addressToReadyToClaim;
  mapping(uint => uint) private carIdToDailyClaimed;
  RentalityCarToken private carService;
  mapping(address => Schemas.ProgramHistory[]) private userProgramHistory;

  
  mapping(address => Schemas.ReadyToClaimFromHash[]) private userToReadyToClaimFromHash;


  function getCarDailyClaimedTime(uint carId) public view returns (uint) {
    return carIdToDailyClaimed[carId];
  }
  function getMyStartDiscount(address user) public view returns (uint) {
    Schemas.Tear tear = getTearTypeByPoints(addressToPoints[user]);
    return selectorToDiscountsPercentsToConstInPoints[Schemas.RefferalProgram.CreateTrip][tear].percents;
  }

  function passReferralProgram(
    Schemas.RefferalProgram selector,
    bytes32 hash,
    bytes memory callbackArgs,
    address user
  ) public {
    require(userService.isManager(msg.sender), 'only Manager');
    (address owner, uint hashPoints) = _getHashProgramInfoIfExists(selector, hash);

    (int points, bool isOneTime) = _setPassedIfExists(selector, callbackArgs, owner != address(0), user);
    if (points > 0) {
      if (isOneTime && hashPoints > 0) {
        userToReadyToClaimFromHash[owner].push(
          Schemas.ReadyToClaimFromHash(uint(hashPoints), selector, isOneTime, false, user)
        );
      }

      addressToReadyToClaim[user].push(Schemas.ReadyToClaim(uint(points), selector, isOneTime));
    } else if (points < 0) {
      uint pointsToReduce = uint(-points);
      if (addressToPoints[user] < pointsToReduce) addressToPoints[user] = 0;
      else addressToPoints[user] -= pointsToReduce;
         userProgramHistory[user].push(Schemas.ProgramHistory(points, block.timestamp, selector, isOneTime));
    }
  }

  function useDiscount(Schemas.RefferalProgram selector, bool host, uint tripId) public returns (uint) {
    require(userService.isManager(msg.sender), 'only Manager');
    uint userPoints = addressToPoints[tx.origin];
    Schemas.Tear tear = getTearTypeByPoints(userPoints);
    uint percents = 0;
    if (Schemas.Tear.Tear1 != tear) {
      (uint possibleDiscount, uint points) = getDiscount(selector, tear);
      require(points > 0 && userPoints >= points, 'Not enough tokens');
      addressToPoints[tx.origin] -= points;
      percents = possibleDiscount;
    }
    if (percents > 0) {
      TripDiscounts storage discounts = tripIdToDisctount[tripId];
      if (host) discounts.host = percents;
      else discounts.guest = percents;
    }

    return percents;
  }
  function getUserService() public view override(ARentalityRefferal) returns (IRentalityAccessControl) {
    return userService;
  }

  function claimPoints(address user) public {
    Schemas.ReadyToClaim[] memory toClaim = addressToReadyToClaim[user];
    if (toClaim.length > 0) {
      addressToReadyToClaim[user] = new Schemas.ReadyToClaim[](0);
      uint total = 0;
      for (uint i = 0; i < toClaim.length; i++) {
        total += toClaim[i].points;
        userProgramHistory[user].push(Schemas.ProgramHistory(int(toClaim[i].points), block.timestamp, toClaim[i].refType, toClaim[i].oneTime));
      }
      total += updateDaily();
      (uint dailiListingPoints, uint[] memory cars) = RentalityRefferalLib.calculateListedCarsPoints(
        permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
        user,
        carService,
        this
      );
      if (dailiListingPoints > 0) {
        uint time = block.timestamp;
        for (uint i = 0; i < cars.length; i++) {
          carIdToDailyClaimed[i] = time;
        }
      }

      addressToPoints[user] = total;
    }
  }

  function getReadyToClaim(address user) public view returns (Schemas.ReadyToClaimDTO memory) {
    Schemas.ReadyToClaim[] memory availableToClaim = addressToReadyToClaim[user];
    uint len = availableToClaim.length;
    uint daily = _checkDaily(user);
    uint toNextDaily = 0;
    if (daily > 0) {
      len += 1;
    }
    (uint dailiListingPoints, ) = RentalityRefferalLib.calculateListedCarsPoints(
      permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
      user,
      carService,
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
    } else toNextDaily = block.timestamp + 1 days - addressToLastDailyClaim[user];

    if (dailiListingPoints > 0) {
      result[index] = Schemas.ReadyToClaim(dailiListingPoints, Schemas.RefferalProgram.DailyListing, false);
    }

    return RentalityRefferalLib.formatReadyToClaim(Schemas.ReadyToClaimDTO(result, counter, toNextDaily), this);
  }

  function getReadyToClaimFromRefferalHash(address user) public view returns (Schemas.RefferalHashDTO memory) {
    Schemas.ReadyToClaimFromHash[] memory availableToClaim = userToReadyToClaimFromHash[user];
    uint counter = 0;
    for (uint i = 0; i < availableToClaim.length; i++) {
      if (!availableToClaim[i].claimed) counter += availableToClaim[i].points;
    }
    bytes32 hash = referralHash[user];
    return Schemas.RefferalHashDTO(availableToClaim, counter, hash);
  }

  function claimRefferalPoints(address user) public {
    Schemas.ReadyToClaimFromHash[] memory availableToClaim = userToReadyToClaimFromHash[user];
    if (availableToClaim.length > 0) {
      uint total = 0;
      for (uint i = 0; i < availableToClaim.length; i++) {
        if (!availableToClaim[i].claimed) {
          total += availableToClaim[i].points;
          userToReadyToClaimFromHash[user][i].claimed = true;
        }
      }
      addressToPoints[user] += total;
    }
  }

  function getRefferalPointsInfo() public view returns (Schemas.AllRefferalInfoDTO memory) {
    uint pointsCounter = 0;
    uint hashCounter = 0;
    uint discountCounter = 0;

    for (uint i = 0; i <= uint(type(Schemas.RefferalProgram).max); i++) {
      Schemas.RefferalProgram program = Schemas.RefferalProgram(i);
      if (selectorToPoints[program].points != 0) pointsCounter += 1;
      if (permanentSelectorToPoints[program].points != 0) pointsCounter += 1;
      if (selectorHashToPoints[program] != 0) hashCounter += 1;
      if (selectorToDiscountsPercentsToConstInPoints[program][Schemas.Tear.Tear2].percents != 0) discountCounter += 3;
    }
    Schemas.RefferalProgramInfoDTO[] memory refferalPoints = new Schemas.RefferalProgramInfoDTO[](pointsCounter);
    Schemas.HashPointsDTO[] memory hashPoints = new Schemas.HashPointsDTO[](hashCounter);
    Schemas.RefferalDiscountsDTO[] memory discounts = new Schemas.RefferalDiscountsDTO[](discountCounter);

    pointsCounter = 0;
    hashCounter = 0;
    discountCounter = 0;
    for (uint i = 0; i <= uint(type(Schemas.RefferalProgram).max); i++) {
      Schemas.RefferalProgram program = Schemas.RefferalProgram(i);
      int oneTimePoints = selectorToPoints[program].points;
      if (oneTimePoints != 0) {
        refferalPoints[pointsCounter] = Schemas.RefferalProgramInfoDTO(
          Schemas.RefferalAccrualType.OneTime,
          program,
          oneTimePoints
        );
        pointsCounter += 1;
      }
      int permanentPoints = permanentSelectorToPoints[program].points;
      if (permanentPoints != 0) {
        refferalPoints[pointsCounter] = Schemas.RefferalProgramInfoDTO(
          Schemas.RefferalAccrualType.Permanent,
          program,
          permanentPoints
        );
        pointsCounter += 1;
      }
      uint refHashPoints = selectorHashToPoints[program];
      if (refHashPoints != 0) {
        hashPoints[hashCounter] = Schemas.HashPointsDTO(program, refHashPoints);
        hashCounter += 1;
      }
      if (selectorToDiscountsPercentsToConstInPoints[program][Schemas.Tear.Tear2].percents != 0)
        for (uint j = 1; j <= uint(type(Schemas.Tear).max); j++) {
          Schemas.Tear tear = Schemas.Tear(j);
          discounts[discountCounter] = Schemas.RefferalDiscountsDTO(
            program,
            tear,
            (selectorToDiscountsPercentsToConstInPoints[program][tear])
          );
          discountCounter += 1;
        }
    }
    return Schemas.AllRefferalInfoDTO(refferalPoints, hashPoints, discounts, getAllTearsInfo());
  }
  function getPointsHistory() public view returns(Schemas.ProgramHistory [] memory) {
    return userProgramHistory[msg.sender];
  }

  function initialize(
    address _userService,
    address _refferalLib,
    address carServiceAddress
  ) public virtual initializer {
    userService = IRentalityAccessControl(_userService);
    refferalLib = _refferalLib;
    carService = RentalityCarToken(carServiceAddress);

    addOneTimeProgram(Schemas.RefferalProgram.SetKYC, 100, 125, bytes4(''));
    addOneTimeProgram(Schemas.RefferalProgram.PassCivic, 500, 625, bytes4(''));
    addOneTimeProgram(Schemas.RefferalProgram.AddCar, 1000, 2000, bytes4(''));
    addOneTimeProgram(Schemas.RefferalProgram.FinishTripAsGuest, 1000, 1250, bytes4(''));

    addPermanentProgram(Schemas.RefferalProgram.AddCar, 500, bytes4(''));
    addPermanentProgram(Schemas.RefferalProgram.FinishTripAsGuest, 50, RentalityRefferalLib.finishTrip.selector);
    addPermanentProgram(Schemas.RefferalProgram.UnlistedCar, -500, RentalityRefferalLib.updateCar.selector);
    addPermanentProgram(Schemas.RefferalProgram.Daily, 20, RentalityRefferalLib.updateDaily.selector);
    addPermanentProgram(Schemas.RefferalProgram.DailyListing, 10, bytes4(''));

    manageRefHashesProgram(Schemas.RefferalProgram.SetKYC, 10);
    manageRefHashesProgram(Schemas.RefferalProgram.PassCivic, 50);
    manageRefHashesProgram(Schemas.RefferalProgram.AddCar, 250);
    manageRefHashesProgram(Schemas.RefferalProgram.FinishTripAsGuest, 1000);

    manageRefferalDiscount(Schemas.RefferalProgram.CreateTrip, Schemas.Tear.Tear2, 100, 2);
    manageRefferalDiscount(Schemas.RefferalProgram.CreateTrip, Schemas.Tear.Tear3, 150, 3);
    manageRefferalDiscount(Schemas.RefferalProgram.CreateTrip, Schemas.Tear.Tear4, 250, 5);


    manageRefferalDiscount(Schemas.RefferalProgram.FinishTripAsGuest, Schemas.Tear.Tear2, 100, 10);
    manageRefferalDiscount(Schemas.RefferalProgram.FinishTripAsGuest, Schemas.Tear.Tear3, 150, 15);
    manageRefferalDiscount(Schemas.RefferalProgram.FinishTripAsGuest, Schemas.Tear.Tear4, 250, 25);

    manageTearInfo(Schemas.Tear.Tear1, 0, 999);
    manageTearInfo(Schemas.Tear.Tear2, 1000, 4999);
    manageTearInfo(Schemas.Tear.Tear3, 5000, 9999);
    manageTearInfo(Schemas.Tear.Tear4, 10000, type(uint).max);
  }
}
