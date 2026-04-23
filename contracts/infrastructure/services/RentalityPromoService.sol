// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../../models/pricing/PricingTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../upgradeable/UUPSOwnable.sol';

string constant ONE_HUNDRED_PERCENTS = 'A';
string constant NINETY_PERCENTS = 'B';
string constant TWENTY_PERCENTS = 'C';

enum RentalityPromoType {
  OneTime,
  Permanent
}

enum RentalityPromoStatus {
  Active,
  Used,
  Disabled
}

struct RentalityPromo {
  RentalityPromoType promoType;
  string code;
  uint256 startDate;
  uint256 expireDate;
  address createdBy;
  uint256 createdAt;
  RentalityPromoStatus status;
}

struct RentalityPromoUsedInfo {
  RentalityPromo promo;
  string promoCode;
  uint256 usedAt;
}

struct RentalityPromoTripData {
  string promo;
  uint256 tripEarningsInCurrency;
  uint256 tripEarnings;
}

interface IRentalityPromoAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
}

contract RentalityPromoService is UUPSOwnable {
  IRentalityPromoAccess public userAccess;
  string[] private promoPrefixes;
  mapping(string => uint256) private promoPrefixToDiscount;
  mapping(string => RentalityPromo) private promoToPromoData;
  string[] private promoCodes;
  mapping(address => RentalityPromoUsedInfo[]) private userPromo;
  mapping(uint256 => RentalityPromoTripData) private tripToPromoData;
  RentalityPromo private generalCode;
  mapping(string => uint256) private promoPrefixToReferralPoints;

  error OnlyAdmin();
  error OnlyPlatform();
  error PromoTypeNotExists();
  error PromoIsNotValid();

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = IRentalityPromoAccess(userAccessAddress);

    promoPrefixes.push(ONE_HUNDRED_PERCENTS);
    promoPrefixToDiscount[ONE_HUNDRED_PERCENTS] = 100;
    promoPrefixes.push(NINETY_PERCENTS);
    promoPrefixToDiscount[NINETY_PERCENTS] = 90;
    promoPrefixes.push('D');
    promoPrefixToDiscount['D'] = 20;
  }

  function generateGeneralCode(uint256 startDateTime, uint256 endDateTime) public {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }

    string memory generalCodeString = 'WAGMI2025';
    addPrefix('W', 20);
    addPrefix('D', 0);
    generalCode = RentalityPromo(
      RentalityPromoType.OneTime,
      generalCodeString,
      startDateTime,
      endDateTime,
      msg.sender,
      block.timestamp,
      RentalityPromoStatus.Active
    );
  }

  function addPrefix(string memory prefix, uint256 discount) public {
    if (!userAccess.isAdmin(msg.sender) && !userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }

    bool exists = false;
    for (uint256 i = 0; i < promoPrefixes.length; i++) {
      if (_eq(promoPrefixes[i], prefix)) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      promoPrefixes.push(prefix);
    }
    promoPrefixToDiscount[prefix] = discount;
  }

  function generateNumbers(
    uint256 min,
    uint256 max,
    uint256 amount,
    uint256 startDateTime,
    uint256 endDateTime,
    string memory prefix
  ) public {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }
    if (!_prefixExists(prefix)) {
      revert PromoTypeNotExists();
    }

    for (uint256 i = 0; i < amount; i++) {
      while (true) {
        uint256 time = random(min, max, i);
        string memory result = string.concat(prefix, Strings.toString(time));
        if (promoToPromoData[result].createdAt == 0) {
          promoToPromoData[result] = RentalityPromo(
            RentalityPromoType.OneTime,
            result,
            startDateTime,
            endDateTime,
            msg.sender,
            block.timestamp,
            RentalityPromoStatus.Active
          );
          promoCodes.push(result);
          break;
        }
      }
    }
  }

  function checkPromo(string memory promo, uint256 startDateTime, uint256 endDateTime)
    public
    view
    returns (PricingCheckPromoDTO memory)
  {
    RentalityPromo memory promoData = promoToPromoData[promo];
    string memory prefix = _getPrefix(promo);
    uint256 promoValue = promoPrefixToDiscount[prefix];

    if (promoData.createdAt == 0 && _eq(promo, generalCode.code)) {
      promoData = generalCode;
    }

    return PricingCheckPromoDTO(
      promoData.createdAt > 0,
      promoData.status == RentalityPromoStatus.Active
        && promoData.expireDate >= endDateTime
        && promoData.startDate <= startDateTime,
      promoValue > 0,
      promoValue > 0 ? promoValue : promoPrefixToReferralPoints[prefix]
    );
  }

  function getPromoData(string memory promo) public view returns (RentalityPromo memory) {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }
    return promoToPromoData[promo];
  }

  function getDiscountByPromo(string memory promoCode, address user) public view returns (uint256) {
    if (bytes(promoCode).length == 0) {
      return 0;
    }

    RentalityPromo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == RentalityPromoStatus.Active) {
      return promoPrefixToDiscount[_getPrefix(promoCode)];
    }

    if (_eq(promoCode, generalCode.code)) {
      RentalityPromoUsedInfo[] memory usedPromos = userPromo[user];
      for (uint256 i = 0; i < usedPromos.length; i++) {
        if (_eq(usedPromos[i].promoCode, generalCode.code)) {
          return 0;
        }
      }
      return promoPrefixToDiscount[_getPrefix(promoCode)];
    }

    return 0;
  }

  function getTripPromoData(uint256 tripId) public view returns (RentalityPromoTripData memory) {
    return tripToPromoData[tripId];
  }

  function getTripDiscount(uint256 tripId) public view returns (uint256) {
    string memory promo = getTripPromoData(tripId).promo;
    return bytes(promo).length == 0 ? 0 : promoPrefixToDiscount[_getPrefix(promo)];
  }

  function getGeneralPromoCode() public view returns (string memory) {
    return generalCode.code;
  }

  function usePromo(
    string memory promoCode,
    uint256 tripId,
    address user,
    uint256 tripEarningsInCurrency,
    uint256 tripEarnings,
    uint256 startTripDate,
    uint256 endTripDate
  ) public returns (bool) {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    RentalityPromo memory promo = promoToPromoData[promoCode];
    if (
      promo.createdAt != 0
        && promo.status == RentalityPromoStatus.Active
        && promo.expireDate >= endTripDate
        && promo.startDate <= startTripDate
    ) {
      tripToPromoData[tripId] = RentalityPromoTripData(promoCode, tripEarningsInCurrency, tripEarnings);
      userPromo[user].push(RentalityPromoUsedInfo(promo, promoCode, block.timestamp));
      promoToPromoData[promoCode].status = RentalityPromoStatus.Used;
      return true;
    }

    if (_eq(promoCode, generalCode.code) && generalCode.startDate <= startTripDate && generalCode.expireDate >= endTripDate) {
      RentalityPromoUsedInfo[] memory usedPromos = userPromo[user];
      for (uint256 i = 0; i < usedPromos.length; i++) {
        if (_eq(usedPromos[i].promoCode, generalCode.code)) {
          revert PromoIsNotValid();
        }
      }
      userPromo[user].push(RentalityPromoUsedInfo(generalCode, promoCode, block.timestamp));
      tripToPromoData[tripId] = RentalityPromoTripData(promoCode, tripEarningsInCurrency, tripEarnings);
      return true;
    }

    revert PromoIsNotValid();
  }

  function rejectDiscountByTrip(uint256 tripId, address user) public {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    string memory promoCode = tripToPromoData[tripId].promo;
    if (bytes(promoCode).length == 0) {
      return;
    }

    RentalityPromo memory promo = promoToPromoData[promoCode];
    if (promo.createdAt != 0 && promo.status == RentalityPromoStatus.Used) {
      promoToPromoData[promoCode].status = RentalityPromoStatus.Active;
    }

    delete tripToPromoData[tripId];
    _removeUserPromo(user, promoCode);
  }

  function useRefferalPromo(bytes32 promoHash, address user) public returns (uint256) {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    string memory promoCode = bytes32ToString(promoHash);
    RentalityPromo memory promo = promoToPromoData[promoCode];
    if (
      promo.status == RentalityPromoStatus.Active
        && promo.expireDate > block.timestamp
        && promo.startDate < block.timestamp
    ) {
      userPromo[user].push(RentalityPromoUsedInfo(promo, promoCode, block.timestamp));
      promoToPromoData[promoCode].status = RentalityPromoStatus.Used;
      return promoPrefixToReferralPoints[_getPrefix(promoCode)];
    }
    return 0;
  }

  function getPromoCodes() public view returns (string[] memory) {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }
    return promoCodes;
  }

  function getPromoDiscountByTrip(uint256 tripId) public view returns (uint256) {
    RentalityPromoTripData memory tripData = tripToPromoData[tripId];
    return bytes(tripData.promo).length == 0 ? 0 : promoPrefixToDiscount[_getPrefix(tripData.promo)];
  }

  function getPromoTripInfo(uint256 tripId, address user)
    public
    view
    returns (TripGatewayTypes.GatewayPromoDTO memory result)
  {
    RentalityPromoTripData memory tripData = tripToPromoData[tripId];
    if (bytes(tripData.promo).length == 0) {
      return result;
    }

    RentalityPromoUsedInfo[] memory promoInfo = userPromo[user];
    for (uint256 i = 0; i < promoInfo.length; i++) {
      if (_eq(promoInfo[i].promoCode, tripData.promo)) {
        result.promoCodeEnterDate = promoInfo[i].usedAt;
        break;
      }
    }
    result.promoCode = tripData.promo;
    result.promoCodeValueInPercents = promoPrefixToDiscount[_getPrefix(tripData.promo)];
  }

  function getUserPromoData() public view returns (RentalityPromoUsedInfo[] memory) {
    return userPromo[msg.sender];
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityPromoAccess(userAccessAddress);
  }

  function random(uint256 min, uint256 max, uint256 nonce) internal view returns (uint256) {
    return (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % max) + min;
  }

  function _getPrefix(string memory promo) public pure returns (string memory) {
    if (bytes(promo).length == 0) {
      return '';
    }
    bytes memory temp = new bytes(1);
    temp[0] = bytes(promo)[0];
    return string(temp);
  }

  function bytes32ToString(bytes32 value) internal pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && value[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && value[i] != 0; i++) {
      bytesArray[i] = value[i];
    }
    return string(bytesArray);
  }

  function _prefixExists(string memory prefix) private view returns (bool) {
    if (promoPrefixToReferralPoints[prefix] != 0) {
      return true;
    }
    for (uint256 i = 0; i < promoPrefixes.length; i++) {
      if (_eq(promoPrefixes[i], prefix)) {
        return true;
      }
    }
    return false;
  }

  function _removeUserPromo(address user, string memory promoCode) private {
    RentalityPromoUsedInfo[] storage usedPromos = userPromo[user];
    for (uint256 i = 0; i < usedPromos.length; i++) {
      if (_eq(usedPromos[i].promoCode, promoCode)) {
        usedPromos[i] = usedPromos[usedPromos.length - 1];
        usedPromos.pop();
        break;
      }
    }
  }

  function _eq(string memory left, string memory right) private pure returns (bool) {
    return keccak256(abi.encodePacked(left)) == keccak256(abi.encodePacked(right));
  }
}
