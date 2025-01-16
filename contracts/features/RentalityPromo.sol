// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../RentalityCarToken.sol';
import '../Schemas.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

string constant ONE_HUNDRED_PERCENTS = 'A';
string constant NINETY_PERCENTS = 'B';
string constant TWENTY_PERCENTS = 'C';

contract RentalityPromoService is Initializable, UUPSAccess {
  string[] private promoPrefixes;
  mapping(string => uint) private promoPrefixToDisctount;

  mapping(string => Schemas.Promo) private promoToPromoData;
  string[] private promoCodes;

  mapping(uint => string) private tripToPromo;

  mapping(address => Schemas.PromoUsedInfo[]) private userPromo;
  mapping(uint => Schemas.PromoTripData) private tripToPromoData;

  Schemas.Promo private generalCode;

  mapping(string => uint) private promoPrefixToRefferalPoints;

  function generateGeneralCode(uint startDateTime, uint endDateTime) public {
    require(userService.isAdmin(msg.sender), 'only admin');
    string memory generalCodeString = string("WAGMI2025");
    promoPrefixes[2] = string('W');
    promoPrefixToDisctount[string('W')] = 20;
    promoPrefixToDisctount[string('D')] = 0;

    generalCode = Schemas.Promo(
      Schemas.PromoType.OneTime,
      generalCodeString,
      startDateTime,
      endDateTime,
      msg.sender,
      block.timestamp,
      Schemas.PromoStatus.Active
    );
  }

  function addPrefix(string memory prefix, uint discount) public {
    require(userService.isAdmin(msg.sender), 'Only for Admin.');
    bool exists = false;
    string[] memory prefixes = promoPrefixes;
    for (uint i = 0; i < prefixes.length; i++) {
      if (keccak256(abi.encodePacked(prefixes[i])) == keccak256(abi.encodePacked((prefix)))) {
        exists = true;
        break;
      }
    }
    if (exists) {
      promoPrefixToDisctount[prefix] = discount;
    } else {
      promoPrefixes.push(prefix);
      promoPrefixToDisctount[prefix] = discount;
    }
  }

  function generateNumbers(
    uint min,
    uint max,
    uint amount,
    uint startDateTime,
    uint endDateTime,
    string memory prefix
  ) public {
    require(userService.isAdmin(msg.sender), 'only admin');
    bool prefixExists = false;
    for (uint i = 0; i < promoPrefixes.length; i++) {
      if (keccak256(abi.encodePacked(promoPrefixes[i])) == keccak256(abi.encodePacked(prefix))) {
        prefixExists = true;
        break;
      } else if (promoPrefixToRefferalPoints[prefix] != 0) {
        prefixExists = true;
        break;
      }
    }
    require(prefixExists, 'Promo type not exists');

    for (uint i = 0; i < amount; i++) {
      while (true) {
        uint time = random(min, max, i);
        string memory result = string.concat(prefix, Strings.toString(time));

        if (promoToPromoData[result].createdAt == 0) {
          promoToPromoData[result] = Schemas.Promo(
            Schemas.PromoType.OneTime,
            result,
            startDateTime,
            endDateTime,
            msg.sender,
            block.timestamp,
            Schemas.PromoStatus.Active
          );
          promoCodes.push(result);
          break;
        }
      }
    }
  }
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime) public view returns (Schemas.CheckPromoDTO memory) {
    Schemas.Promo memory promoData = promoToPromoData[promo];
    string memory prefix = _getPrefix(promo);
    uint promoValue = promoPrefixToDisctount[prefix];
    if (promoData.createdAt == 0 && keccak256(abi.encodePacked(promo)) == keccak256(abi.encodePacked(generalCode.code))) {
        promoData = generalCode;
    } 
    return
      Schemas.CheckPromoDTO(
        promoData.createdAt > 0,
        promoData.status == Schemas.PromoStatus.Active &&
          promoData.expireDate >= endDateTime &&
          promoData.startDate <= startDateTime,
        promoValue > 0,
        promoValue > 0 ? promoValue : promoPrefixToRefferalPoints[prefix]
      );
  }
  function getPromoData(string memory promo) public view returns (Schemas.Promo memory) {
    require(userService.isAdmin(msg.sender), 'only admin');
    return promoToPromoData[promo];
  }

  function getDiscountByPromo(string memory promoCode, address user) public view returns (uint) {
    if(bytes(promoCode).length == 0)
        return 0;
    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == Schemas.PromoStatus.Active) {
      return promoPrefixToDisctount[_getPrefix(promoCode)];
    } else if (keccak256(abi.encode(promoCode)) == keccak256(abi.encode(generalCode.code))) {
      Schemas.PromoUsedInfo[] memory usedPromos = userPromo[user];
      for (uint i = 0; i < usedPromos.length; i++) {
        if (keccak256(abi.encode(usedPromos[i].promoCode)) == keccak256(abi.encode(generalCode.code))) {
          return 0;
        }
      }
      return promoPrefixToDisctount[_getPrefix(promoCode)];
    }
    return 0;
  }

  function getTripPromoData(uint tripId) public view returns (Schemas.PromoTripData memory) {
    return tripToPromoData[tripId];
  }

   function getTripDiscount(uint tripId) public view returns (uint) {
   string memory promo = getTripPromoData(tripId).promo;
   if(bytes(promo).length == 0)
    return 0;
    
    return promoPrefixToDisctount[_getPrefix(promo)];
  }
  function getGeneralPromoCode() public view returns (string memory) {
    return generalCode.code;
  }
  function usePromo(
    string memory promoCode,
    uint tripId,
    address user,
    uint tripEarningsInCurrency,
    uint tripEarnings,
    uint startTripDate,
    uint endTripData
  ) public returns (bool) {
    require(userService.isManager(msg.sender), 'Only for Manager.');
    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (
      promo.createdAt != 0 &&
      promo.status == Schemas.PromoStatus.Active &&
      promo.expireDate >= endTripData &&
      promo.startDate <= startTripDate
    ) {
      tripToPromoData[tripId] = Schemas.PromoTripData(promoCode, tripEarningsInCurrency, tripEarnings);
      userPromo[user].push(Schemas.PromoUsedInfo(promo, promoCode, block.timestamp));
      promoToPromoData[promoCode].status = Schemas.PromoStatus.Used;
      return true;
    } else if (keccak256(abi.encode(promoCode)) == keccak256(abi.encode(generalCode.code)) &&
     generalCode.startDate <= startTripDate &&
      generalCode.expireDate >= endTripData) {
      Schemas.PromoUsedInfo[] memory usedPromos = userPromo[user];
      bool used = false;
      for (uint i = 0; i < usedPromos.length; i++) {
        if (keccak256(abi.encode(usedPromos[i].promoCode)) == keccak256(abi.encode(generalCode.code))) {
          used = true;
        }
      }
      if (!used) {
        userPromo[user].push(Schemas.PromoUsedInfo(generalCode, promoCode, block.timestamp));
        tripToPromoData[tripId] = Schemas.PromoTripData(promoCode, tripEarningsInCurrency, tripEarnings);
        return true;
      }
    }
     revert("Promo is not valid for the date range");
  }
  function rejectDiscountByTrip(uint tripId, address user) public {
    require(userService.isManager(msg.sender), 'Only for Manager.');
    string memory promoCode = tripToPromoData[tripId].promo;
    if(bytes(promoCode).length == 0)
    return;

    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == Schemas.PromoStatus.Used) {
      promoToPromoData[promoCode].status = Schemas.PromoStatus.Active;
    }    
      delete tripToPromoData[tripId];
      Schemas.PromoUsedInfo[] memory userUsedPromo = userPromo[user];
      for (uint i = 0; i < userUsedPromo.length; i++) {
        if (keccak256(abi.encode(promoCode)) == keccak256(abi.encode(userUsedPromo[i].promoCode))) {
          if (i == userUsedPromo.length - 1) userPromo[user].pop();
          else {
            for (uint j = i; j < userUsedPromo.length - 1; j++) 
             userUsedPromo[j] = userUsedPromo[j + 1];

            userPromo[user] = userUsedPromo;
            userPromo[user].pop();
            }
          break;
        }
    }
  }

  function useRefferalPromo(bytes32 promoHash, address user) public returns (uint) {
    require(userService.isManager(msg.sender), 'Only for Manager.');
    string memory promoCode = bytes32ToString(promoHash);
    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (
      promo.status == Schemas.PromoStatus.Active &&
      promo.expireDate > block.timestamp &&
      promo.startDate < block.timestamp
    ) {
      userPromo[user].push(Schemas.PromoUsedInfo(promo, promoCode, block.timestamp));

      promoToPromoData[promoCode].status = Schemas.PromoStatus.Used;
      return promoPrefixToRefferalPoints[_getPrefix(promoCode)];
    }
    return 0;
  }

  function getPromoCodes() public view returns (string[] memory) {
    require(userService.isAdmin(msg.sender), 'only admin');
    return promoCodes;
  }
  function getPromoDiscountByTrip(uint tripId) public view returns (uint) {
   Schemas.PromoTripData memory tripData = tripToPromoData[tripId];
   if(bytes(tripData.promo).length == 0) {
     return 0;
   }
   else {
     return promoPrefixToDisctount[_getPrefix(tripData.promo)];
   }
  }

  function random(uint min, uint max, uint nonce) internal view returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % max;
    randomnumber = randomnumber + min;
    return randomnumber;
  }

function getPromoTripInfo(uint tripId, address user) public view returns (Schemas.PromoDTO memory result) {
    Schemas.PromoTripData memory tripData = tripToPromoData[tripId];
    if(bytes(tripData.promo).length == 0) {
      return result;
    }
  Schemas.PromoUsedInfo[] memory promoInfo = userPromo[user];
  for (uint i = 0; i < promoInfo.length; i++) {
    if (keccak256(abi.encode(promoInfo[i].promoCode)) == keccak256(abi.encode(tripData.promo))) {
      result.promoCodeEnterDate = promoInfo[i].usedAt;
      break;
    }
  }
    result.promoCode = tripData.promo;
    result.promoCodeValueInPercents = promoPrefixToDisctount[_getPrefix(tripData.promo)];
}

function getUserPromoData() public view returns (Schemas.PromoUsedInfo[] memory) {
    return userPromo[msg.sender];
  }

  function _getPrefix(string memory promo) public pure returns (string memory) {
    bytes memory temp = new bytes(1);
    temp[0] = bytes(promo)[0];
    return string(temp);
  }

  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    promoPrefixes.push(string(ONE_HUNDRED_PERCENTS));
    promoPrefixToDisctount[string(ONE_HUNDRED_PERCENTS)] = 100;

    promoPrefixes.push(string(NINETY_PERCENTS));
    promoPrefixToDisctount[string(NINETY_PERCENTS)] = 90;

    promoPrefixes.push(string('D'));
    promoPrefixToDisctount[string('D')] = 20;

  }
}