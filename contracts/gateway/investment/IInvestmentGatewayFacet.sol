// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/investment/RentalInvestmentTypes.sol';

interface IInvestmentGatewayFacet {
    function invest(uint256 investId, uint256 amount) external payable;
    function claimAllMy(uint256 investId) external;
    function getPaymentsInfo(uint256 carId) external view returns (uint256 percents, address pool, address currency);
    function getAllInvestments() external view returns (RentalInvestmentDTO[] memory investments);
    function createCarInvestment(RentalCarInvestment memory car, string memory name_, address currency) external;
    function claimAndCreatePool(uint256 investId, RentalInvestmentCarRequest memory createCarRequest) external;
    function changeListingStatus(uint256 investId) external;
}
