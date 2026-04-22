// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/Schemas.sol';

interface IInvestmentGatewayFacet {
    function invest(uint256 investId, uint256 amount) external payable;
    function claimAllMy(uint256 investId) external;
    function getPaymentsInfo(uint256 carId) external view returns (uint256 percents, address pool, address currency);
    function getAllInvestments() external view returns (Schemas.InvestmentDTO[] memory investments);
    function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, address currency) external;
    function claimAndCreatePool(uint256 investId, Schemas.CreateCarRequest memory createCarRequest) external;
    function changeListingStatus(uint256 investId) external;
}
