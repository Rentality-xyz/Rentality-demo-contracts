// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/base/pricing/PricingBase.sol';
import '../car/CarTypes.sol';
import '../common/CommonTypes.sol';
import '../../infrastructure/geo/IRentalityGeoService.sol';
import '../profile/UserProfileTypes.sol';
import './RentalPricingTypes.sol';

interface IRentalityDiscount {
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 price) external view returns (uint64);
    function setDiscount(bytes memory newDiscounts) external;
    function addUserDiscount(address user, bytes memory newDiscounts) external;
    function getDiscount(address userAddress) external view returns (bytes memory);
}

interface IRentalPricingAccess {
    function isAdmin(address user) external view returns (bool);
    function isRentalityPlatform(address user) external view returns (bool);
    function isHost(address user) external view returns (bool);
    function manageRole(UserProfileRole newRole, address user, bool grant) external;
}

interface IRentalPricingCarTaxLookup {
    function getGeoServiceAddress() external view returns (address);
    function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfo memory);
}

interface IRentalPricingTaxes {
    function addTaxes(
        uint256 taxId,
        string memory location,
        RentalPricingTaxesLocationType locationType,
        RentalTaxValue[] memory taxes
    ) external;

    function getTaxesIdByHash(bytes32 hash) external view returns (uint256, RentalPricingTaxesLocationType);
    function calculateAndSaveTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost, uint256 tripId) external returns (uint64);
    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64);
    function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
        external
        view
        returns (uint64 totalTax, RentalTaxValue[] memory taxes);
    function getTripTaxesDTO(uint256 tripId) external view returns (RentalTaxValue[] memory);
    function getTotalTripTax(uint256 tripId) external view returns (uint64);
    function getTaxInfoById(uint256 taxId) external view returns (RentalTaxesInfo memory);
}
contract RentalPricingMain is PricingBase, UUPSOwnable {
    IRentalPricingAccess public userAccess;
    mapping(address => IRentalityDiscount) public discountAddressToDiscountContract;
    IRentalPricingTaxes public rentalityTaxes;
    address public currentDiscount;
    uint256 public taxesId;
    uint256 public defaultTax;

    error OnlyAdmin();
    error OnlyPlatform();
    error DiscountContractNotFound(address discountContract);

    event PlatformFeeUpdated(uint32 valueInPPM);
    event DiscountContractAdded(address indexed discountContract);
    event CurrentDiscountTypeChanged(address indexed discountContract);
    event DefaultDiscountUpdated();
    event TaxesContractUpdated(address indexed taxesContract);
    event DefaultTaxUpdated(uint256 indexed taxId);
    event TaxesAdded(uint256 indexed taxId, string location, RentalPricingTaxesLocationType locationType);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyAdmin() {
        if (address(userAccess) == address(0) || !(userAccess.isAdmin(msg.sender) || userAccess.isAdmin(tx.origin))) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyPlatform() {
        if (address(userAccess) == address(0) || !userAccess.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    function initialize(
        address userAccessAddress,
        address rentalityTaxesAddress,
        address baseDiscountAddress
    ) public initializer {
        __Ownable_init();

        userAccess = IRentalPricingAccess(userAccessAddress);
        rentalityTaxes = IRentalPricingTaxes(rentalityTaxesAddress);
        currentDiscount = baseDiscountAddress;
        discountAddressToDiscountContract[baseDiscountAddress] = IRentalityDiscount(baseDiscountAddress);
        taxesId = 0;
        defaultTax = 1;
        _setPlatformFeeInPPM(200_000);
    }

    function setPlatformFeeInPPM(uint32 valueInPPM) external onlyAdmin {
        _setPlatformFeeInPPM(valueInPPM);
        emit PlatformFeeUpdated(valueInPPM);
    }

    function addDiscountContract(address discountContractAddress) external onlyAdmin {
        discountAddressToDiscountContract[discountContractAddress] = IRentalityDiscount(discountContractAddress);
        emit DiscountContractAdded(discountContractAddress);
    }

    function changeCurrentDiscountType(address discountContract) external onlyAdmin {
        if (address(discountAddressToDiscountContract[discountContract]) == address(0)) {
            revert DiscountContractNotFound(discountContract);
        }

        currentDiscount = discountContract;
        emit CurrentDiscountTypeChanged(discountContract);
    }

    function setDefaultDiscount(RentalBaseDiscount memory data) external onlyAdmin {
        discountAddressToDiscountContract[currentDiscount].setDiscount(abi.encode(data));
        emit DefaultDiscountUpdated();
    }

    function addBaseDiscount(address user, RentalBaseDiscount memory data) external onlyPlatform {
        if (!userAccess.isHost(user)) {
            userAccess.manageRole(UserProfileRole.Host, user, true);
        }

        discountAddressToDiscountContract[currentDiscount].addUserDiscount(user, abi.encode(data));
    }

    function getBaseDiscount(address user) public view returns (RentalBaseDiscount memory) {
        return abi.decode(discountAddressToDiscountContract[currentDiscount].getDiscount(user), (RentalBaseDiscount));
    }

    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
        return discountAddressToDiscountContract[currentDiscount].calculateSumWithDiscount(user, daysOfTrip, value);
    }

    function addTaxesContract(address taxesContractAddress) external onlyAdmin {
        rentalityTaxes = IRentalPricingTaxes(taxesContractAddress);
        emit TaxesContractUpdated(taxesContractAddress);
    }

    function addTaxes(
        string memory location,
        RentalPricingTaxesLocationType locationType,
        RentalTaxValue[] memory taxes
    ) external onlyAdmin returns (uint256) {
        taxesId += 1;
        rentalityTaxes.addTaxes(taxesId, location, locationType, taxes);
        emit TaxesAdded(taxesId, location, locationType);
        return taxesId;
    }

    function setDefaultTax(uint256 taxId) external onlyAdmin {
        defaultTax = taxId;
        emit DefaultTaxUpdated(taxId);
    }

    function defineTaxesType(address carServiceAddress, uint256 carId) public view returns (uint256) {
        IRentalPricingCarTaxLookup gateway = IRentalPricingCarTaxLookup(carServiceAddress);
        IRentalityGeoService geoService = IRentalityGeoService(gateway.getGeoServiceAddress());
        bytes32 carLocationHash = gateway.getCarInfoById(carId).locationHash;

        bytes32 cityHash = keccak256(abi.encode(geoService.getCarCity(carLocationHash)));
        bytes32 stateHash = keccak256(abi.encode(geoService.getCarState(carLocationHash)));
        bytes32 countryHash = keccak256(abi.encode(geoService.getCarCountry(carLocationHash)));

        (uint256 taxId, RentalPricingTaxesLocationType locationType) = rentalityTaxes.getTaxesIdByHash(countryHash);
        if (taxId > 0 && locationType == RentalPricingTaxesLocationType.Country) {
            return taxId;
        }

        (taxId, locationType) = rentalityTaxes.getTaxesIdByHash(stateHash);
        if (taxId > 0 && locationType == RentalPricingTaxesLocationType.State) {
            return taxId;
        }

        (taxId, locationType) = rentalityTaxes.getTaxesIdByHash(cityHash);
        if (taxId > 0 && locationType == RentalPricingTaxesLocationType.City) {
            return taxId;
        }

        return defaultTax;
    }

    function calculateAndSaveTaxes(uint256 taxId, uint64 daysOfTrip, uint64 value, uint256 tripId)
        external
        onlyPlatform
        returns (uint64)
    {
        return rentalityTaxes.calculateAndSaveTaxes(taxId, daysOfTrip, value, tripId);
    }

    function calculateTaxes(uint256 taxId, uint64 tripDays, uint64 totalCost) external view returns (uint64) {
        return rentalityTaxes.calculateTaxes(taxId, tripDays, totalCost);
    }

    function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
        external
        view
        returns (uint64 totalTax, RentalTaxValue[] memory taxes)
    {
        return rentalityTaxes.calculateTaxesDTO(taxId, tripDays, totalCost);
    }

    function getTripTaxesDTO(uint256 tripId) external view returns (RentalTaxValue[] memory) {
        return rentalityTaxes.getTripTaxesDTO(tripId);
    }

    function getTotalTripTax(uint256 tripId) external view returns (uint64) {
        return rentalityTaxes.getTotalTripTax(tripId);
    }

    function getTaxesInfoById(uint256 taxId) external view returns (RentalTaxesInfo memory) {
        return rentalityTaxes.getTaxInfoById(taxId);
    }

    function taxExist(LocationInfo memory locationInfo) external view returns (uint256) {
        bytes32 cityHash = keccak256(abi.encode(locationInfo.city));
        bytes32 stateHash = keccak256(abi.encode(locationInfo.state));
        bytes32 countryHash = keccak256(abi.encode(locationInfo.country));

        (uint256 taxId, RentalPricingTaxesLocationType locationType) = rentalityTaxes.getTaxesIdByHash(countryHash);
        if (taxId > 0 && locationType == RentalPricingTaxesLocationType.Country) {
            return taxId;
        }

        (taxId, locationType) = rentalityTaxes.getTaxesIdByHash(stateHash);
        if (taxId > 0 && locationType == RentalPricingTaxesLocationType.State) {
            return taxId;
        }

        (taxId, locationType) = rentalityTaxes.getTaxesIdByHash(cityHash);
        if (taxId > 0 && locationType == RentalPricingTaxesLocationType.City) {
            return taxId;
        }

        return 0;
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = IRentalPricingAccess(userAccessAddress);
    }

}



