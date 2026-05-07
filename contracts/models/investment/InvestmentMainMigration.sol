// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/investment/InvestmentBase.sol";
import "../car/CarTypes.sol";
import "./InvestmentTypes.sol";
import "../../infrastructure/upgradeable/UUPSOwnable.sol";

interface IInvestmentMigrationAccess {
    function isRentalityPlatform(address user) external view returns (bool);
    function isInvestorManager(address user) external view returns (bool);
}

interface IInvestmentMigrationCurrencyConverter {
    function currencyTypeIsAvailable(address tokenAddress) external view returns (bool);
    function getToUsdLatest(address currencyType, uint256 amount) external view returns (uint256, int256, uint8);
}

interface IInvestmentMigrationCarMain {
    function createCar(CreateCarRequest calldata request, address user) external returns (uint256);
    function isUniqueVinNumber(string memory carVinNumber) external view returns (bool);
}

interface IInvestmentMigrationInsuranceMain {
    function saveInsuranceRequired(uint256 carId, uint256 priceInUsdCents, bool required, address user) external;
}

interface IInvestmentMigrationDeployer {
    function createNewPool(uint256 id, address nft, uint256 totalPayed, address currency) external returns (address);
    function createNewNft(string memory name, string memory sym, uint256 id, string memory tokenUri)
        external
        returns (address);
}

contract InvestmentMainMigration is InvestmentBase, UUPSOwnable {
    IInvestmentMigrationAccess public userAccess;
    IInvestmentMigrationCurrencyConverter public converter;
    IInvestmentMigrationCarMain public carMain;
    IInvestmentMigrationInsuranceMain public insuranceService;
    IInvestmentMigrationDeployer public investDeployer;

    mapping(uint256 => CarInvestment) internal investmentIdToCarInfo;
    mapping(uint256 => address) internal investmentIdToPool;
    mapping(uint256 => address) internal investmentIdToNft;

    struct MigrationInvestmentImport {
        uint256 investmentId;
        CarInvestment investment;
        uint256 fundedAmount;
        address creator;
        address currency;
        bool listed;
        uint256 carId;
        address pool;
        address nft;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function migrationImportInvestment(MigrationInvestmentImport calldata item) external onlyOwner {
        uint256 investmentId = item.investmentId;
        require(investmentId != 0, "Migration: zero investment id");

        investmentIdToCarInfo[investmentId] = item.investment;
        investmentIdToFundedAmount[investmentId] = item.fundedAmount;
        investmentIdToCreator[investmentId] = item.creator;
        investmentIdToCurrency[investmentId] = item.currency;
        investmentIdToListed[investmentId] = item.listed;
        investmentIdToPool[investmentId] = item.pool;
        investmentIdToNft[investmentId] = item.nft;

        if (item.carId != 0) {
            carIdToInvestmentId[item.carId] = investmentId;
        }
        if (investmentId > investmentCount) {
            investmentCount = investmentId;
        }
    }

    function getFundingInfo(uint256 investmentId) external view returns (InvestmentFundingInfo memory) {
        CarInvestment memory investment = investmentIdToCarInfo[investmentId];
        return InvestmentFundingInfo({
            targetAmount: investment.priceInCurrency,
            fundedAmount: investmentIdToFundedAmount[investmentId],
            currency: investmentIdToCurrency[investmentId],
            listed: investmentIdToListed[investmentId],
            inProgress: investment.inProgress
        });
    }

    function getPaymentsInfo(uint256 carId) external view returns (InvestmentPayoutRoute memory) {
        uint256 investmentId = carIdToInvestmentId[carId];
        return InvestmentPayoutRoute({
            creatorPercents: investmentIdToCarInfo[investmentId].creatorPercents,
            pool: investmentIdToPool[investmentId],
            currency: investmentIdToCurrency[investmentId]
        });
    }
}
