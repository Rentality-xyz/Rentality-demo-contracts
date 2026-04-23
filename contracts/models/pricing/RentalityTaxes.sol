// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import './RentalPricingTypes.sol';

interface IRentalityTaxesAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
}

contract RentalityTaxes is UUPSOwnable {
  IRentalityTaxesAccess public userAccess;

  mapping(uint256 => RentalTaxValue[]) private tripIdToTaxes;
  mapping(uint256 => RentalTaxValue[]) private taxIdToTaxes;
  mapping(bytes32 => uint256) private taxesLocationHashToTaxId;
  mapping(uint256 => RentalPricingTaxesLocationType) private taxIdToLocationType;
  mapping(uint256 => string) private taxIdToLocation;

  error OnlyAdmin();
  error OnlyPlatform();
  error LengthMismatch();
  error TaxIdMismatch();

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = IRentalityTaxesAccess(userAccessAddress);
  }

  function calculateAndSaveTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost, uint256 tripId)
    public
    returns (uint64)
  {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }

    RentalTaxValue[] memory values = taxIdToTaxes[taxId];
    RentalTaxValue[] memory tripTaxes = new RentalTaxValue[](values.length);
    uint64 totalTax = 0;

    for (uint256 i = 0; i < values.length; i++) {
      uint64 currentTax = _calculateTax(values[i], tripDays, totalCost);
      totalTax += currentTax;
      tripTaxes[i] = RentalTaxValue(values[i].name, uint32(currentTax), RentalPricingTaxesType.InUsdCents);
    }

    tripIdToTaxes[tripId] = tripTaxes;
    return totalTax;
  }

  function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) public view returns (uint64 totalTax) {
    RentalTaxValue[] memory values = taxIdToTaxes[taxId];
    for (uint256 i = 0; i < values.length; i++) {
      totalTax += _calculateTax(values[i], tripDays, totalCost);
    }
  }

  function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
    public
    view
    returns (uint64 totalTax, RentalTaxValue[] memory taxes)
  {
    RentalTaxValue[] memory values = taxIdToTaxes[taxId];
    taxes = new RentalTaxValue[](values.length);

    for (uint256 i = 0; i < values.length; i++) {
      uint64 currentTax = _calculateTax(values[i], tripDays, totalCost);
      totalTax += currentTax;
      taxes[i] = RentalTaxValue(values[i].name, uint32(currentTax), RentalPricingTaxesType.InUsdCents);
    }
  }

  function getTripTaxesDTO(uint256 tripId) public view returns (RentalTaxValue[] memory) {
    return tripIdToTaxes[tripId];
  }

  function getTaxInfoById(uint256 taxId) public view returns (RentalTaxesInfo memory) {
    return RentalTaxesInfo(taxIdToLocation[taxId], taxIdToLocationType[taxId], taxIdToTaxes[taxId]);
  }

  function getTotalTripTax(uint256 tripId) public view returns (uint64 totalTax) {
    RentalTaxValue[] memory values = tripIdToTaxes[tripId];
    for (uint256 i = 0; i < values.length; i++) {
      totalTax += values[i].value;
    }
  }

  function getTaxesIdByHash(bytes32 hash) public view returns (uint256, RentalPricingTaxesLocationType) {
    uint256 taxId = taxesLocationHashToTaxId[hash];
    return (taxId, taxIdToLocationType[taxId]);
  }

  function addTaxes(
    uint256 taxId,
    string memory location,
    RentalPricingTaxesLocationType locationType,
    RentalTaxValue[] memory taxes
  ) public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }

    bytes32 hash = keccak256(abi.encode(location));
    taxesLocationHashToTaxId[hash] = taxId;
    taxIdToTaxes[taxId] = taxes;
    taxIdToLocationType[taxId] = locationType;
    taxIdToLocation[taxId] = location;
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

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityTaxesAccess(userAccessAddress);
  }

  function _calculateTax(RentalTaxValue memory tax, uint64 tripDays, uint64 totalCost) private pure returns (uint64) {
    if (tax.tType == RentalPricingTaxesType.PPM) {
      return (totalCost * tax.value) / 1_000_000;
    }
    if (tax.tType == RentalPricingTaxesType.InUsdCents) {
      return tax.value;
    }
    return tripDays * tax.value;
  }
}
