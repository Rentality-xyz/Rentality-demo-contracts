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

  function getPromoCodes() public view returns (string[] memory) {
    require(userService.isAdmin(msg.sender), 'only admin');
    return promoCodes;
  }

  function random(uint min, uint max, uint nonce) internal view returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % max;
    randomnumber = randomnumber + min;
    return randomnumber;
  }

  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    promoPrefixes.push(string(ONE_HUNDRED_PERCENTS));
    promoPrefixToDisctount[string(ONE_HUNDRED_PERCENTS)] = 100;

    promoPrefixes.push(string(NINETY_PERCENTS));
    promoPrefixToDisctount[string(NINETY_PERCENTS)] = 90;

    promoPrefixes.push(string(TWENTY_PERCENTS));
    promoPrefixToDisctount[string(TWENTY_PERCENTS)] = 20;
  }
}
