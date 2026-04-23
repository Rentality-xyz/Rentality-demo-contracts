// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../upgradeable/UUPSOwnable.sol';

interface IRentalityCurrencyTypeAccess {
  function isAdmin(address user) external view returns (bool);
}

abstract contract ARentalityUpgradableCurrencyType is UUPSOwnable {
  IRentalityCurrencyTypeAccess public userAccess;
  int256 internal currentToUsdRate;
  uint8 internal currentToUsdDecimals;
  uint256 public updateRateInterval;
  uint256 public lastUpdateRateTimeStamp;
  AggregatorV3Interface internal rateFeed;
  IERC20Metadata public tokenAddress;

  error OnlyAdmin();
  error InvalidRate();

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress, address token, address rateFeedAddress) public virtual initializer {
    __Ownable_init();
    userAccess = IRentalityCurrencyTypeAccess(userAccessAddress);
    tokenAddress = IERC20Metadata(token);
    updateRateInterval = 1 hours;

    if (rateFeedAddress != address(0)) {
      rateFeed = AggregatorV3Interface(rateFeedAddress);
      (currentToUsdRate, currentToUsdDecimals) = getRate();
    } else {
      currentToUsdRate = 100_000_000;
      currentToUsdDecimals = 8;
    }
  }

  function getFromUsdCents(uint256 amountInUsdCent, int256 rate) public view virtual returns (uint256) {
    if (rate <= 0) {
      revert InvalidRate();
    }
    return (amountInUsdCent * (10 ** (tokenDecimals() + rateTokenDecimals() - 2))) / uint256(rate);
  }

  function getUsdCents(uint256 value, int256 rate) public view virtual returns (uint256) {
    if (rate <= 0) {
      revert InvalidRate();
    }
    return (value * uint256(rate)) / (10 ** (tokenDecimals() + rateTokenDecimals() - 2));
  }

  function getTokenAddress() public view virtual returns (address) {
    return address(tokenAddress);
  }

  function rateTokenDecimals() public view returns (uint8) {
    if (address(rateFeed) == address(0)) {
      return 8;
    }
    return rateFeed.decimals();
  }

  function tokenDecimals() public view virtual returns (uint8) {
    return tokenAddress.decimals();
  }

  function getLatest() public view returns (int256) {
    if (address(rateFeed) == address(0)) {
      return 100_000_000;
    }
    (, int256 rate,,,) = rateFeed.latestRoundData();
    return rate;
  }

  function getRate() public view virtual returns (int256, uint8) {
    return (getLatest(), rateTokenDecimals());
  }

  function getFromUsdCentsLatest(uint256 amount) public view returns (uint256, int256, uint8) {
    (int256 rate, uint8 decimals) = getRate();
    return (getFromUsdCents(amount, rate), rate, decimals);
  }

  function getUsdFromLatest(uint256 amount) public view returns (uint256, int256, uint8) {
    (int256 rate, uint8 decimals) = getRate();
    return (getUsdCents(amount, rate), rate, decimals);
  }

  function getRateWithCache() public returns (int256, uint8) {
    if ((block.timestamp - lastUpdateRateTimeStamp) > updateRateInterval) {
      lastUpdateRateTimeStamp = block.timestamp;
      currentToUsdRate = getLatest();
      currentToUsdDecimals = rateTokenDecimals();
    }
    return (currentToUsdRate, currentToUsdDecimals);
  }

  function getFromUsdCentsWithCache(uint256 valueInUsdCents) public returns (uint256) {
    (int256 rate,) = getRateWithCache();
    return getFromUsdCents(valueInUsdCents, rate);
  }

  function getUsdWithCache(uint256 valueInThis) public returns (uint256) {
    (int256 rate,) = getRateWithCache();
    return getUsdCents(valueInThis, rate);
  }

  function getCurrentRate() public view returns (int256, uint8) {
    return (currentToUsdRate, currentToUsdDecimals);
  }

  function setRateFeed(address rateFeedAddress) public {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }
    rateFeed = AggregatorV3Interface(rateFeedAddress);
    (currentToUsdRate, currentToUsdDecimals) = getRate();
  }
}
