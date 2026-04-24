// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/investment/InvestmentMain.sol';
import '../../models/investment/InvestmentQuery.sol';
import '../../models/investment/InvestmentTypes.sol';
import '../../models/profile/UserProfileMain.sol';
import '../GatewayContext.sol';
import './IInvestmentGatewayFacet.sol';

contract InvestmentGatewayFacet is UUPSOwnable, GatewayContext, IInvestmentGatewayFacet {
    InvestmentMain public investmentMain;
    InvestmentQuery public investmentQuery;
    UserProfileMain public userProfileMain;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address investmentMainAddress, address investmentQueryAddress, address userProfileMainAddress)
        public
        initializer
    {
        __Ownable_init();
        _setServiceAddresses(investmentMainAddress, investmentQueryAddress, userProfileMainAddress);
    }

    function updateServiceAddresses(
        address investmentMainAddress,
        address investmentQueryAddress,
        address userProfileMainAddress
    ) external onlyOwner {
        _setServiceAddresses(investmentMainAddress, investmentQueryAddress, userProfileMainAddress);
    }

    function invest(uint256 investId, uint256 amount) external payable {
        investmentMain.invest{value: msg.value}(investId, amount, _msgGatewaySender());
    }

    function claimAllMy(uint256 investId) external {
        investmentMain.claimAllMy(investId, _msgGatewaySender());
    }

    function getPaymentsInfo(uint256 carId) external view returns (uint256 percents, address pool, address currency) {
        return investmentQuery.getPaymentsInfo(carId);
    }

    function getAllInvestments() external view returns (InvestmentDTO[] memory investments) {
        return investmentQuery.getAllInvestments(_msgGatewaySender(), userProfileMain.isInvestorManager(_msgGatewaySender()));
    }

    function createCarInvestment(CarInvestment memory car, string memory name_, address currency) external {
        investmentMain.createCarInvestment(
            car,
            name_,
            currency,
            _msgGatewaySender()
        );
    }

    function claimAndCreatePool(uint256 investId, InvestmentCarRequest memory createCarRequest) external {
        investmentMain.claimAndCreatePool(
            investId,
            createCarRequest,
            _msgGatewaySender()
        );
    }

    function changeListingStatus(uint256 investId) external {
        investmentMain.changeListingStatus(investId, _msgGatewaySender());
    }

    function isTrustedForwarder(address forwarder) internal view override returns (bool) {
        return address(userProfileMain) != address(0) && userProfileMain.isRentalityPlatform(forwarder);
    }

    function _setServiceAddresses(
        address investmentMainAddress,
        address investmentQueryAddress,
        address userProfileMainAddress
    ) internal {
        investmentMain = InvestmentMain(payable(investmentMainAddress));
        investmentQuery = InvestmentQuery(investmentQueryAddress);
        userProfileMain = UserProfileMain(payable(userProfileMainAddress));
    }
}

