// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/investment/RentalInvestmentMain.sol';
import '../../models/investment/RentalInvestmentQuery.sol';
import '../../models/investment/RentalInvestmentTypes.sol';
import '../../models/profile/UserProfileMain.sol';
import '../ARentalityContext.sol';
import './IInvestmentGatewayFacet.sol';

contract InvestmentGatewayFacet is UUPSOwnable, ARentalityContext, IInvestmentGatewayFacet {
    RentalInvestmentMain public rentalInvestmentMain;
    RentalInvestmentQuery public rentalInvestmentQuery;
    UserProfileMain public userProfileMain;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address rentalInvestmentMainAddress, address rentalInvestmentQueryAddress, address userProfileMainAddress)
        public
        initializer
    {
        __Ownable_init();
        _setServiceAddresses(rentalInvestmentMainAddress, rentalInvestmentQueryAddress, userProfileMainAddress);
    }

    function updateServiceAddresses(
        address rentalInvestmentMainAddress,
        address rentalInvestmentQueryAddress,
        address userProfileMainAddress
    ) external onlyOwner {
        _setServiceAddresses(rentalInvestmentMainAddress, rentalInvestmentQueryAddress, userProfileMainAddress);
    }

    function invest(uint256 investId, uint256 amount) external payable {
        rentalInvestmentMain.invest{value: msg.value}(investId, amount, _msgGatewaySender());
    }

    function claimAllMy(uint256 investId) external {
        rentalInvestmentMain.claimAllMy(investId, _msgGatewaySender());
    }

    function getPaymentsInfo(uint256 carId) external view returns (uint256 percents, address pool, address currency) {
        return rentalInvestmentQuery.getPaymentsInfo(carId);
    }

    function getAllInvestments() external view returns (RentalInvestmentDTO[] memory investments) {
        return rentalInvestmentQuery.getAllInvestments(_msgGatewaySender(), userProfileMain.isInvestorManager(_msgGatewaySender()));
    }

    function createCarInvestment(RentalCarInvestment memory car, string memory name_, address currency) external {
        rentalInvestmentMain.createCarInvestment(
            car,
            name_,
            currency,
            _msgGatewaySender()
        );
    }

    function claimAndCreatePool(uint256 investId, RentalInvestmentCarRequest memory createCarRequest) external {
        rentalInvestmentMain.claimAndCreatePool(
            investId,
            createCarRequest,
            _msgGatewaySender()
        );
    }

    function changeListingStatus(uint256 investId) external {
        rentalInvestmentMain.changeListingStatus(investId, _msgGatewaySender());
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
    }

    function _setServiceAddresses(
        address rentalInvestmentMainAddress,
        address rentalInvestmentQueryAddress,
        address userProfileMainAddress
    ) internal {
        rentalInvestmentMain = RentalInvestmentMain(payable(rentalInvestmentMainAddress));
        rentalInvestmentQuery = RentalInvestmentQuery(rentalInvestmentQueryAddress);
        userProfileMain = UserProfileMain(payable(userProfileMainAddress));
    }
}

