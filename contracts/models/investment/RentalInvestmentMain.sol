// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../base/investment/InvestmentBase.sol';
import '../base/investment/InvestmentTypes.sol';
import '../car/CarTypes.sol';
import './RentalInvestmentTypes.sol';

interface IRentalInvestmentAccess {
    function isRentalityPlatform(address user) external view returns (bool);
    function isInvestorManager(address user) external view returns (bool);
}

interface IRentalInvestmentCurrencyConverter {
    function currencyTypeIsAvailable(address tokenAddress) external view returns (bool);
    function getToUsdLatest(address currencyType, uint256 amount) external view returns (uint256, int256, uint8);
}

interface IRentalInvestmentCarMain {
    function createCar(CreateCarRequest calldata request, address user) external returns (uint256);
    function isUniqueVinNumber(string memory carVinNumber) external view returns (bool);
}

interface IRentalInvestmentInsuranceMain {
    function saveInsuranceRequired(uint256 carId, uint256 priceInUsdCents, bool required, address user) external;
}

interface IRentalInvestmentDeployer {
    function createNewPool(uint256 id, address nft, uint256 totalPayed, address currency) external returns (address);
    function createNewNft(string memory name, string memory sym, uint256 id, string memory tokenUri)
        external
        returns (address);
}

interface IRentalInvestmentPool {
    function claimAllMy(address user, uint256[] memory tokens) external;
}

interface IRentalInvestmentNft {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupplyWithTotalHolders() external view returns (uint256, uint256);
}

contract RentalInvestmentMain is InvestmentBase, UUPSOwnable {
    IRentalInvestmentAccess public userAccess;
    IRentalInvestmentCurrencyConverter public converter;
    IRentalInvestmentCarMain public carMain;
    IRentalInvestmentInsuranceMain public insuranceService;
    IRentalInvestmentDeployer public investDeployer;

    mapping(uint256 => RentalCarInvestment) internal investmentIdToCarInfo;
    mapping(uint256 => address) internal investmentIdToPool;
    mapping(uint256 => address) internal investmentIdToNft;

    error OnlyPlatform();
    error OnlyInvestorManager(address user);
    error UnsupportedCurrency(address currency);
    error InvestmentNotListed(uint256 investmentId);
    error InvestmentUnavailable(uint256 investmentId);
    error WrongNativeAmount(uint256 expected, uint256 actual);
    error WrongAllowance(address currency, address user, uint256 amount);
    error TransferFailed(address currency, address user, uint256 amount);
    error AlreadyClaimed(uint256 investmentId);
    error DuplicateVin(string vin);
    error StillInProgress(uint256 investmentId);

    modifier onlyPlatform() {
        if (!userAccess.isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address userAccessAddress,
        address currencyConverterAddress,
        address carMainAddress,
        address insuranceServiceAddress,
        address investDeployerAddress
    ) public initializer {
        __Ownable_init();
        userAccess = IRentalInvestmentAccess(userAccessAddress);
        converter = IRentalInvestmentCurrencyConverter(currencyConverterAddress);
        carMain = IRentalInvestmentCarMain(carMainAddress);
        insuranceService = IRentalInvestmentInsuranceMain(insuranceServiceAddress);
        investDeployer = IRentalInvestmentDeployer(investDeployerAddress);
    }

    function createCarInvestment(
        RentalCarInvestment calldata investment,
        string memory name_,
        address currency,
        address sender
    ) external onlyPlatform {
        if (!userAccess.isInvestorManager(sender)) {
            revert OnlyInvestorManager(sender);
        }
        if (!converter.currencyTypeIsAvailable(currency)) {
            revert UnsupportedCurrency(currency);
        }

        uint256 investId = _nextInvestmentId();
        investmentIdToCurrency[investId] = currency;
        investmentIdToCarInfo[investId] = investment;
        investmentIdToNft[investId] = investDeployer.createNewNft(
            name_,
            _createSymbol(investId),
            investId,
            investment.car.car.asset.metadataURI
        );
        investmentIdToCreator[investId] = sender;
        investmentIdToListed[investId] = true;
    }

    function invest(uint256 investId, uint256 amount, address sender) external payable onlyPlatform {
        RentalCarInvestment storage investment = investmentIdToCarInfo[investId];
        if (!investmentIdToListed[investId]) {
            revert InvestmentNotListed(investId);
        }
        if (!investment.inProgress) {
            revert InvestmentUnavailable(investId);
        }

        uint256 amountAfterInvestment = investmentIdToFundedAmount[investId] + amount;
        if (amountAfterInvestment >= investment.priceInCurrency) {
            investment.inProgress = false;
        }

        address currency = investmentIdToCurrency[investId];
        if (currency == address(0)) {
            if (msg.value != amount) {
                revert WrongNativeAmount(amount, msg.value);
            }
            investmentIdToFundedAmount[investId] += msg.value;
            _mintInvestmentNft(investId, msg.value, sender);
            return;
        }

        if (IERC20(currency).allowance(sender, address(this)) < amount) {
            revert WrongAllowance(currency, sender, amount);
        }
        bool success = IERC20(currency).transferFrom(sender, address(this), amount);
        if (!success) {
            revert TransferFailed(currency, sender, amount);
        }
        investmentIdToFundedAmount[investId] += amount;
        _mintInvestmentNft(investId, amount, sender);
    }

    function claimAndCreatePool(
        uint256 investId,
        RentalInvestmentCarRequest calldata createCarRequest,
        address sender
    ) external onlyPlatform returns (uint256 carId) {
        if (!userAccess.isInvestorManager(sender)) {
            revert OnlyInvestorManager(sender);
        }
        if (investmentIdToPool[investId] != address(0)) {
            revert AlreadyClaimed(investId);
        }
        if (!carMain.isUniqueVinNumber(createCarRequest.car.carVinNumber)) {
            revert DuplicateVin(createCarRequest.car.carVinNumber);
        }

        RentalCarInvestment storage investment = investmentIdToCarInfo[investId];
        investment.car = createCarRequest;

        uint256 amountInvested = investmentIdToFundedAmount[investId];
        if (investment.priceInCurrency <= amountInvested || !investment.inProgress) {
            investment.inProgress = false;
        }
        if (investment.inProgress) {
            revert StillInProgress(investId);
        }

        investmentIdToPool[investId] = investDeployer.createNewPool(
            investId,
            investmentIdToNft[investId],
            investmentIdToFundedAmount[investId],
            investmentIdToCurrency[investId]
        );

        carId = carMain.createCar(createCarRequest.car, sender);
        if (address(insuranceService) != address(0)) {
            insuranceService.saveInsuranceRequired(
                carId,
                investment.car.insurancePriceInUsdCents,
                investment.car.insuranceRequired,
                sender
            );
        }
        carIdToInvestmentId[carId] = investId;

        _transferFundsToCreator(investId, sender);
    }

    function getFundingInfo(uint256 investmentId) public view returns (InvestmentFundingInfo memory) {
        RentalCarInvestment memory investment = investmentIdToCarInfo[investmentId];
        return InvestmentFundingInfo({
            targetAmount: investment.priceInCurrency,
            fundedAmount: investmentIdToFundedAmount[investmentId],
            currency: investmentIdToCurrency[investmentId],
            listed: investmentIdToListed[investmentId],
            inProgress: investment.inProgress
        });
    }

    function getPaymentsInfo(uint256 carId) public view returns (InvestmentPayoutRoute memory payoutRoute) {
        uint256 investmentId = carIdToInvestmentId[carId];
        return InvestmentPayoutRoute({
            creatorPercents: investmentIdToCarInfo[investmentId].creatorPercents,
            pool: investmentIdToPool[investmentId],
            currency: investmentIdToCurrency[investmentId]
        });
    }

    function getInvestment(uint256 investmentId) external view returns (RentalCarInvestment memory) {
        return investmentIdToCarInfo[investmentId];
    }

    function getPool(uint256 investmentId) external view returns (address) {
        return investmentIdToPool[investmentId];
    }

    function getNft(uint256 investmentId) external view returns (address) {
        return investmentIdToNft[investmentId];
    }

    function getInvestmentCurrency(uint256 investmentId) external view returns (address) {
        return investmentIdToCurrency[investmentId];
    }

    function isListed(uint256 investmentId) external view returns (bool) {
        return investmentIdToListed[investmentId];
    }

    function getCarInvestmentId(uint256 carId) external view returns (uint256) {
        return carIdToInvestmentId[carId];
    }

    function changeListingStatus(uint256 investId, address sender) external onlyPlatform {
        if (!userAccess.isInvestorManager(sender)) {
            revert OnlyInvestorManager(sender);
        }
        investmentIdToListed[investId] = !investmentIdToListed[investId];
    }

    function claimAllMy(uint256 investId, address sender) external onlyPlatform {
        IRentalInvestmentNft nft = IRentalInvestmentNft(investmentIdToNft[investId]);
        uint256[] memory tokens = _getAllMyTokens(sender, nft);
        IRentalInvestmentPool(investmentIdToPool[investId]).claimAllMy(sender, tokens);
    }

    function updateUserAccess(address userAccessAddress) external onlyOwner {
        userAccess = IRentalInvestmentAccess(userAccessAddress);
    }

    function updateConverter(address currencyConverterAddress) external onlyOwner {
        converter = IRentalInvestmentCurrencyConverter(currencyConverterAddress);
    }

    function updateCarMain(address carMainAddress) external onlyOwner {
        carMain = IRentalInvestmentCarMain(carMainAddress);
    }

    function updateInsuranceService(address insuranceServiceAddress) external onlyOwner {
        insuranceService = IRentalInvestmentInsuranceMain(insuranceServiceAddress);
    }

    function updateInvestDeployer(address investDeployerAddress) external onlyOwner {
        investDeployer = IRentalInvestmentDeployer(investDeployerAddress);
    }

    function _mintInvestmentNft(uint256 investId, uint256 amount, address user) internal {
        (bool success, bytes memory data) = investmentIdToNft[investId].call(
            abi.encodeWithSignature('mint(uint256,address)', amount, user)
        );
        require(success, string(data));
    }

    function _getAllMyTokens(address user, IRentalInvestmentNft nft) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](nft.balanceOf(user));
        uint256 counter = 0;
        (uint256 totalSupply,) = nft.totalSupplyWithTotalHolders();
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (nft.ownerOf(i) == user) {
                result[counter] = i;
                counter += 1;
            }
        }
        return result;
    }

    function _transferFundsToCreator(uint256 investId, address receiver) internal {
        uint256 amount = investmentIdToFundedAmount[investId];
        address currency = investmentIdToCurrency[investId];
        if (currency == address(0)) {
            (bool success,) = payable(receiver).call{value: amount}('');
            require(success, 'Fail to transfer.');
        } else {
            bool success = IERC20(currency).transfer(receiver, amount);
            require(success, 'Transfer failed.');
        }
    }

    function _createSymbol(uint256 tokenId) private view returns (string memory) {
        (uint256 month, uint256 year) = _getMonthAndYear();
        string memory monthResult = month < 10 ? string.concat('0', Strings.toString(month)) : Strings.toString(month);
        return string.concat(
            string.concat(string.concat('RENTALITY', '-00000'), Strings.toString(tokenId)),
            string.concat('-', string.concat(monthResult, Strings.toString(year % 100)))
        );
    }

    function _getMonthAndYear() private view returns (uint256 month, uint256 year) {
        uint256 timestamp = block.timestamp;
        int256 z = int256(timestamp / 86400 + 719468);
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        year = uint256(yoe) + uint256(era) * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        month = uint256(mp + 3);
        if (month > 12) {
            month -= 12;
            year += 1;
        }
    }
}
