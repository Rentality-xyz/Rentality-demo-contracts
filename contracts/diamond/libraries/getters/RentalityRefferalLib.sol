// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {RefferalServiceStorage} from "../RefferalServiceStorage.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Schemas} from "../../../Schemas.sol";
import {CarTokenStorage} from "../CarTokenStorage.sol";



library RentalityRefferalLib {
   
function finishTrip(int points, bytes memory data) public pure returns (int) {
    (uint64 startDateTime, uint64 endDateTime) = abi.decode(data, (uint64, uint64));
    uint64 duration = endDateTime - startDateTime;
    return points * int(Math.ceilDiv(duration, 1 days));
  }

  function updateCar(int points, bytes memory data) public pure returns (int) {
    (bool wasListed, bool toBeListed) = abi.decode(data, (bool, bool));
    if (!wasListed) return 0;
    if (!toBeListed) return points;

    return 0;
  }
  function calculateListedCarsPoints(
    int points,
    address user
  ) internal view returns (uint, uint[] memory) {
    CarTokenStorage.CarTokenFaucetStorage storage carServiceStorage = CarTokenStorage.accessStorage();
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    uint totalPoints = 0;
    uint counter = 0;
    uint carTotalSupply = carServiceStorage.totalSupply();
    if (carServiceStorage._balances[user] == 0) return (0, new uint[](0));
    for (uint i = 1; i <= carTotalSupply; i++) {
      if (CarTokenStorage.ownerOf(i) == user) {
        uint listingMoment = carServiceStorage.carIdToListingMoment[i];
        if (listingMoment != 0) {
          uint updateTime = RefferalServiceStorage.carIdToDailyClaimed[i];
          if (updateTime > listingMoment) listingMoment = updateTime;

          uint duration = block.timestamp - listingMoment;
          uint pointsToGet = duration == 0 ? 0 : uint(points) * (duration / 1 days);
          if (pointsToGet > 0) {
            totalPoints += pointsToGet;
            counter += 1;
          }
        }
      }
    }
    uint[] memory carIds = new uint[](counter);
    uint index = 0;
    for (uint i = 1; i <= carTotalSupply; i++) {
      if (CarTokenStorage.ownerOf(i) == user) {
        uint listingMoment = carServiceStorage.carIdToListingMoment[i];
        if (listingMoment != 0) {
          uint updateTime = RefferalServiceStorage.carIdToDailyClaimed[i];
          if (updateTime > listingMoment) listingMoment = updateTime;
          uint duration = block.timestamp - listingMoment;
          uint pointsToGet = duration == 0 ? 0 : uint(points) * (duration / 1 days);
          if (pointsToGet > 0) {
            carIds[index] = i;
            index += 1;
          }
        }
      }
    }
    return (totalPoints, carIds);
  }

  function formatReadyToClaim(
    Schemas.ReadyToClaimDTO memory toClaim
  ) public view returns (Schemas.ReadyToClaimDTO memory) {
    Schemas.ReadyToClaim[] memory claim = getReadyToClaim();
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



  function getReadyToClaim(address user) public view returns (Schemas.ReadyToClaimDTO memory readyToClaimDTO) {
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    Schemas.ReadyToClaim[] memory availableToClaim = RefferalServiceStorage.addressToReadyToClaim[user];
    uint len = availableToClaim.length;
    uint daily = _checkDaily(user);
    uint toNextDaily = 0;
    if (daily > 0) {
      len += 1;
    }
    (uint dailiListingPoints, ) = calculateListedCarsPoints(
      RefferalServiceStorage.permanentSelectorToPoints[Schemas.RefferalProgram.DailyListing].points,
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
    } else toNextDaily = block.timestamp + 1 days - RefferalServiceStorage.addressToLastDailyClaim[user];

    if (dailiListingPoints > 0) {
      counter += dailiListingPoints;
      result[index] = Schemas.ReadyToClaim(dailiListingPoints, Schemas.RefferalProgram.DailyListing, false);
    }

    return formatReadyToClaim(Schemas.ReadyToClaimDTO(result, counter, toNextDaily), this);
  }

    function _checkDaily(address user) internal view returns (uint) {
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    uint result = 0;
    uint last = RefferalServiceStorage.addressToLastDailyClaim[user];
    uint current = block.timestamp;
    if (current >= last + 1 days) {
      result = uint(RefferalServiceStorage.permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }

    function getAllTearsInfo() public view returns (Schemas.TearDTO[] memory) {
    RefferalServiceStorage.RefferalFaucetStorage storage RefferalServiceStorage = RefferalServiceStorage.accessStorage();
    Schemas.TearDTO[] memory tears = new Schemas.TearDTO[](uint(type(Schemas.Tear).max) + 1);
    for (uint i = 0; i <= uint(type(Schemas.Tear).max); i++) {
      Schemas.Tear tear = Schemas.Tear(i);
      tears[i] = Schemas.TearDTO(RefferalServiceStorage.tearTypeToTearPoints[tear], tear);
    }
    return tears;
  }

}