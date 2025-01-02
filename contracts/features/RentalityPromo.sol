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
  
  string private generalCode;

  function generateGeneralCode() public {
        require(userService.isAdmin(msg.sender), 'only admin');
        uint time = random(10000, 99999, type(uint).max);
        generalCode = string.concat('D', Strings.toString(time));
        
        promoPrefixes[2] = string('D');
        promoPrefixToDisctount[string('D')] = 20;

        promoPrefixToDisctount[string(TWENTY_PERCENTS)] = 0;

  }

  function addPrefix(string memory prefix, uint discount) public {
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
  function isActive(string memory promo) public view returns (bool) {
    require(userService.isAdmin(msg.sender), 'only admin');
    return
      promoToPromoData[promo].startDate < block.timestamp &&
      promoToPromoData[promo].expireDate > block.timestamp &&
      promoToPromoData[promo].status == Schemas.PromoStatus.Active;
  }
  function getPromoData(string memory promo) public view returns (Schemas.Promo memory) {
    require(userService.isAdmin(msg.sender), 'only admin');
    return promoToPromoData[promo];
  }

  function getDiscountByPromo(string memory promoCode, address user) public view returns(uint) {
    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == Schemas.PromoStatus.Active) {
             return promoPrefixToDisctount[_getPrefix(promoCode)];
    
    return 0;
  }
      else if(keccak256(abi.encode(promoCode)) == keccak256(abi.encode(generalCode))) {
        Schemas.PromoUsedInfo[] memory usedPromos = userPromo[user];
        bool used = false;
        for(uint i = 0; i < usedPromos.length; i++) {
        if(keccak256(abi.encode(usedPromos[i].promoCode)) == keccak256(abi.encode(generalCode))) {
            return 0;
        }
        }
        return promoPrefixToDisctount[_getPrefix(promoCode)];
    }
  }

  function getTripPromoData(uint tripId) public view returns(Schemas.PromoTripData memory) {
    return tripToPromoData[tripId];
  }  
    function usePromo(string memory promoCode, uint tripId, address user, uint tripEarningsInCurrency, uint tripEarnings) public returns(bool) {
    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == Schemas.PromoStatus.Active) {
        tripToPromoData[tripId] = Schemas.PromoTripData(
            promoCode,
            tripEarningsInCurrency,
            tripEarnings
        );
        userPromo[user].push(Schemas.PromoUsedInfo(
            promo,
            promoCode,
            block.timestamp
    ));
        promoToPromoData[promoCode].status == Schemas.PromoStatus.Used;
        return true;
    }
    else if(keccak256(abi.encode(promoCode)) == keccak256(abi.encode(generalCode))) {
        Schemas.PromoUsedInfo[] memory usedPromos = userPromo[user];
        bool used = false;
        for(uint i = 0; i < usedPromos.length; i++) {
        if(keccak256(abi.encode(usedPromos[i].promoCode)) == keccak256(abi.encode(generalCode))) {
            used = true;
        }
        }
        if(!used) {
         userPromo[user].push(Schemas.PromoUsedInfo(
            promo,
            promoCode,
            block.timestamp
    ));
    return true;
        }
    }
    return false;

  }
  function rejectDiscountByTrip(uint tripId, address user) public {
    string memory promoCode = tripToPromoData[tripId].promo;
    Schemas.Promo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == Schemas.PromoStatus.Used) {
        promoToPromoData[promoCode].status = Schemas.PromoStatus.Active;
        delete tripToPromoData[tripId];
        Schemas.PromoUsedInfo[] memory userUsedPromo = userPromo[user];
        for(uint i = 0; i < userUsedPromo.length; i++) {
            if(keccak256(abi.encode(promoCode)) == keccak256(abi.encode(userUsedPromo[i].promo.code))) {
                if(i == userUsedPromo.length - 1)
                userPromo[user].pop();

            else {
                for(uint j = i; j < userUsedPromo.length - 1; j++)
                userUsedPromo[j] = userUsedPromo[j + 1];
                userPromo[user] = userUsedPromo;
            }
            break;
            }
        }
    }
  }

  function getPromoCodes() public view returns (string[] memory) {
    require(userService.isAdmin(msg.sender), 'only admin');
    return promoCodes;
  }

  function random(uint min, uint max, uint nonce) internal view returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % max;
    randomnumber = randomnumber + min;
    return randomnumber;
  }
  function _getPrefix(string memory promo) public pure returns(string memory) {
    bytes memory temp = new bytes(1);
    temp[0] = bytes(promo)[0];
    return string(temp);
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
