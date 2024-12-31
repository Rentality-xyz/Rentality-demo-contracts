// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../RentalityCarToken.sol';
import '../Schemas.sol';

bytes1 constant ONE_HUNDRED_PERCENTS = 0x00;
bytes1 constant NINETY_PERCENTS = 0x05;
bytes1 constant TWENTY_PERCENTS = 0x03;

contract RentalityPromoService is Initializable, UUPSAccess {

  bytes1[] private promoPrefixes;
  mapping(bytes1 => uint) private promoPrefixToDisctount;

  mapping(bytes3 => Schemas.Promo) private promoToPromoData;
  bytes3[] private promoCodes;

 mapping(uint => bytes3) private tripToPromo;

 mapping(address => Schemas.PromoUsedInfo[]) private userPromo;

function addPrefix(bytes1 prefix, uint discount) public  {
    bool exists = false;
    bytes1[] memory prefixes = promoPrefixes;
    for (uint i = 0; i < prefixes.length; i++)
    {
        if(prefixes[i] == prefix) {
        break;
        }
    }
    if (exists) {
        promoPrefixToDisctount[prefix] = discount;
    }
    else {
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
    bytes1 prefix
    ) public {
        bool prefixExists = false;
    for (uint i = 0; i < promoPrefixes.length; i++) {
        if (promoPrefixes[i] == prefix) {
        prefixExists = true; 
        break;
        }
    }
    require(prefixExists, "Promo type not exists");
    bytes3 mask = 0xFFFFFF; 
    
    for (uint i = 0; i < amount; i++) {
        while (true) {
        uint time = random(min, max, i);

        bytes3 result = _toHex3WithPrefix(time, prefix); 
        // result = toUpper(result);
        if(promoToPromoData[result].createdAt == 0 && result[0] == prefix) {
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
function isActive(bytes3 promo) public view returns(bool) {
    return promoToPromoData[promo].startDate < block.timestamp &&
    promoToPromoData[promo].expireDate > block.timestamp &&
    promoToPromoData[promo].status == Schemas.PromoStatus.Active;
}
function getPromoData(bytes3 promo) public view returns(Schemas.Promo memory) {
    return promoToPromoData[promo];
}

function getPromoCodes() public view returns(bytes3[] memory) {
    return promoCodes;
}
function _toHex3WithPrefix(uint number, bytes1 prefix) private pure returns(bytes3) {
     bytes3 mask = 0xFFFFFF; 
     bytes3 temp = bytes3(uint24(number));
   
     return (temp & mask) | prefix;
}

function random(uint min, uint max, uint nonce) internal view returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % max;
    randomnumber = randomnumber + min;
    return randomnumber;
}

// function toUpper(bytes3 input) public pure returns (bytes3) {
//     bytes3 result;

//     for (uint i = 1; i < 3; i++) {
//         bytes1 char = input[i];

//         if (char >= 0x61 && char <= 0x7A) {
//             result |= bytes3(bytes1(uint8(char) - 32)) >> (i * 8);
//         } else {
//             result |= bytes3(char) >> (i * 8);
//         }
//     }

//     return result;
// }


  function initialize(address _userService) public initializer {
    userService = IRentalityAccessControl(_userService);
    promoPrefixes.push(bytes1(ONE_HUNDRED_PERCENTS));
    promoPrefixToDisctount[bytes1(ONE_HUNDRED_PERCENTS)] = 100;

    promoPrefixes.push(bytes1(NINETY_PERCENTS));
     promoPrefixToDisctount[bytes1(NINETY_PERCENTS)] = 90;

    promoPrefixes.push(bytes1(TWENTY_PERCENTS));
     promoPrefixToDisctount[bytes1(TWENTY_PERCENTS)] = 20;

  }
}
