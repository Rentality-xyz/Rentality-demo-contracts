// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/services/geo/IRentalityGeoService.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../car/CarTypes.sol';
import '../common/CommonTypes.sol';
import '../profile/UserProfileTypes.sol';
import './PricingTypes.sol';

interface IPricingMainFacet1Access {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IPricingMainFacet1CarTaxLookup {
  function getGeoServiceAddress() external view returns (address);
  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfo memory);
}

contract PricingMainFacet1 is UUPSOwnable {
  IPricingMainFacet1Access public userAccess;

  mapping(address => PricingBaseDiscount) private userAddressToBaseDiscount;
  PricingBaseDiscount public defaultDiscount;

  mapping(uint256 => PricingTaxValue[]) private tripIdToTaxes;
  mapping(uint256 => PricingTaxValue[]) private taxIdToTaxes;
  mapping(bytes32 => uint256) private taxesLocationHashToTaxId;
  mapping(uint256 => PricingTaxesLocationType) private taxIdToLocationType;
  mapping(uint256 => string) private taxIdToLocation;
  uint256 public taxesId;
  uint256 public defaultTax;

  error OnlyAdmin();
  error OnlyPlatform();
  error IncorrectDiscount();
  error LengthMismatch();
  error TaxIdMismatch();

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = IPricingMainFacet1Access(userAccessAddress);
    defaultDiscount = PricingBaseDiscount(20_000, 100_000, 150_000, false);
    taxesId = 0;
    defaultTax = 1;
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IPricingMainFacet1Access(userAccessAddress);
  }

  function getBaseDiscount(address userAddress) public view returns (PricingBaseDiscount memory) {
    if (userAddress == address(0)) {
      return defaultDiscount;
    }

    PricingBaseDiscount memory discount = userAddressToBaseDiscount[userAddress];
    return discount.initialized ? discount : defaultDiscount;
  }

  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 price) public view returns (uint64) {
    PricingBaseDiscount memory discount = getBaseDiscount(user);
    uint32 discountPercent;

    if (daysOfTrip >= 3 && daysOfTrip < 7) {
      discountPercent = discount.threeDaysDiscount;
    } else if (daysOfTrip >= 7 && daysOfTrip < 30) {
      discountPercent = discount.sevenDaysDiscount;
    } else if (daysOfTrip >= 30) {
      discountPercent = discount.thirtyDaysDiscount;
    } else {
      return price * daysOfTrip;
    }

    return (price * daysOfTrip * (1_000_000 - discountPercent)) / 1_000_000;
  }

  function setDefaultDiscount(PricingBaseDiscount memory newDiscountData) public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }

    _verifyDiscountValidity(newDiscountData);
    defaultDiscount = newDiscountData;
  }

  function addBaseDiscount(address user, PricingBaseDiscount memory newDiscountData) public {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    _verifyDiscountValidity(newDiscountData);
    userAddressToBaseDiscount[user] = newDiscountData;
  }

  function setDefaultDiscountToFalse() public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }
    defaultDiscount.initialized = false;
  }

  function addTaxes(
    string memory location,
    PricingTaxesLocationType locationType,
    PricingTaxValue[] memory taxes
  ) public returns (uint256) {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }

    taxesId += 1;
    uint256 taxId = taxesId;
    bytes32 hash = keccak256(abi.encode(location));
    taxesLocationHashToTaxId[hash] = taxId;
    taxIdToTaxes[taxId] = taxes;
    taxIdToLocationType[taxId] = locationType;
    taxIdToLocation[taxId] = location;
    return taxId;
  }

  function setDefaultTax(uint256 taxId) external {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }
    defaultTax = taxId;
  }

  function defineTaxesType(address carServiceAddress, uint256 carId) public view returns (uint256) {
    IPricingMainFacet1CarTaxLookup gateway = IPricingMainFacet1CarTaxLookup(carServiceAddress);
    IRentalityGeoService geoService = IRentalityGeoService(gateway.getGeoServiceAddress());
    bytes32 carLocationHash = gateway.getCarInfoById(carId).locationHash;

    bytes32 cityHash = keccak256(abi.encode(geoService.getCarCity(carLocationHash)));
    bytes32 stateHash = keccak256(abi.encode(geoService.getCarState(carLocationHash)));
    bytes32 countryHash = keccak256(abi.encode(geoService.getCarCountry(carLocationHash)));

    (uint256 taxId, PricingTaxesLocationType locationType) = getTaxesIdByHash(countryHash);
    if (taxId > 0 && locationType == PricingTaxesLocationType.Country) {
      return taxId;
    }

    (taxId, locationType) = getTaxesIdByHash(stateHash);
    if (taxId > 0 && locationType == PricingTaxesLocationType.State) {
      return taxId;
    }

    (taxId, locationType) = getTaxesIdByHash(cityHash);
    if (taxId > 0 && locationType == PricingTaxesLocationType.City) {
      return taxId;
    }

    return defaultTax;
  }

  function calculateAndSaveTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost, uint256 tripId)
    public
    returns (uint64)
  {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    PricingTaxValue[] memory values = taxIdToTaxes[taxId];
    PricingTaxValue[] memory tripTaxes = new PricingTaxValue[](values.length);
    uint64 totalTax = 0;

    for (uint256 i = 0; i < values.length; i++) {
      uint64 currentTax = _calculateTax(values[i], tripDays, totalCost);
      totalTax += currentTax;
      tripTaxes[i] = PricingTaxValue(values[i].name, uint32(currentTax), PricingTaxesType.InUsdCents);
    }

    tripIdToTaxes[tripId] = tripTaxes;
    return totalTax;
  }

  function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) public view returns (uint64 totalTax) {
    PricingTaxValue[] memory values = taxIdToTaxes[taxId];
    for (uint256 i = 0; i < values.length; i++) {
      totalTax += _calculateTax(values[i], tripDays, totalCost);
    }
  }

  function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
    public
    view
    returns (uint64 totalTax, PricingTaxValue[] memory taxes)
  {
    PricingTaxValue[] memory values = taxIdToTaxes[taxId];
    taxes = new PricingTaxValue[](values.length);

    for (uint256 i = 0; i < values.length; i++) {
      uint64 currentTax = _calculateTax(values[i], tripDays, totalCost);
      totalTax += currentTax;
      taxes[i] = PricingTaxValue(values[i].name, uint32(currentTax), PricingTaxesType.InUsdCents);
    }
  }

  function getTripTaxesDTO(uint256 tripId) public view returns (PricingTaxValue[] memory) {
    return tripIdToTaxes[tripId];
  }

  function getTotalTripTax(uint256 tripId) public view returns (uint64 totalTax) {
    PricingTaxValue[] memory values = tripIdToTaxes[tripId];
    for (uint256 i = 0; i < values.length; i++) {
      totalTax += values[i].value;
    }
  }

  function getTaxesInfoById(uint256 taxId) public view returns (PricingTaxesInfo memory) {
    return PricingTaxesInfo(taxIdToLocation[taxId], taxIdToLocationType[taxId], taxIdToTaxes[taxId]);
  }

  function taxExist(LocationInfo memory locationInfo) public view returns (uint256) {
    bytes32 cityHash = keccak256(abi.encode(locationInfo.city));
    bytes32 stateHash = keccak256(abi.encode(locationInfo.state));
    bytes32 countryHash = keccak256(abi.encode(locationInfo.country));

    (uint256 taxId, PricingTaxesLocationType locationType) = getTaxesIdByHash(countryHash);
    if (taxId > 0 && locationType == PricingTaxesLocationType.Country) {
      return taxId;
    }

    (taxId, locationType) = getTaxesIdByHash(stateHash);
    if (taxId > 0 && locationType == PricingTaxesLocationType.State) {
      return taxId;
    }

    (taxId, locationType) = getTaxesIdByHash(cityHash);
    if (taxId > 0 && locationType == PricingTaxesLocationType.City) {
      return taxId;
    }

    return 0;
  }

  function getTaxesIdByHash(bytes32 hash) public view returns (uint256, PricingTaxesLocationType) {
    uint256 taxId = taxesLocationHashToTaxId[hash];
    return (taxId, taxIdToLocationType[taxId]);
  }

  function setTaxLocations(uint256[] memory taxes, string[] memory locations) public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }
    if (taxes.length != locations.length) {
      revert LengthMismatch();
    }

    for (uint256 i = 0; i < taxes.length; i++) {
      bytes32 hash = keccak256(abi.encode(locations[i]));
      if (taxesLocationHashToTaxId[hash] != taxes[i]) {
        revert TaxIdMismatch();
      }
      taxIdToLocation[taxes[i]] = locations[i];
    }
  }

  function setTaxesLocations(uint256[] memory taxIds, string[] memory locations) public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }
    if (taxIds.length != locations.length) {
      revert LengthMismatch();
    }

    for (uint256 i = 0; i < taxIds.length; i++) {
      taxIdToLocation[taxIds[i]] = locations[i];
    }
  }

  function _verifyDiscountValidity(PricingBaseDiscount memory discount) private pure {
    _verifyPercentageValidity(discount.threeDaysDiscount);
    _verifyPercentageValidity(discount.sevenDaysDiscount);
    _verifyPercentageValidity(discount.thirtyDaysDiscount);
  }

  function _verifyPercentageValidity(uint32 value) private pure {
    if (value > 1_000_000) {
      revert IncorrectDiscount();
    }
  }

  function _calculateTax(PricingTaxValue memory tax, uint64 tripDays, uint64 totalCost) private pure returns (uint64) {
    if (tax.tType == PricingTaxesType.PPM) {
      return (totalCost * tax.value) / 1_000_000;
    }
    if (tax.tType == PricingTaxesType.InUsdCents) {
      return tax.value;
    }
    return tripDays * tax.value;
  }
}
