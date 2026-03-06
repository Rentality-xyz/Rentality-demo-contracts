// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;



// import '../Schemas.sol';
// import '../proxy/UUPSAccess.sol';
// import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
// import '../payments/RentalityCurrencyConverter.sol';
// import './RentalityInvestmentPool.sol';
// import '../RentalityCarToken.sol';
// import '../Schemas.sol';
// import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
// import {RentalityViewLib} from '../libs/RentalityViewLib.sol';
// import {RentalityUserService} from '../RentalityUserService.sol';
// import {IERC20} from '../payments/abstract/IERC20.sol';
// import {RentalityInvestDeployer} from './RentalityInvestDeployer.sol';
// import {ARentalityContext} from '../abstract/ARentalityContext.sol';
// import {RentalityLiquidityPool} from './RentalityLiquidityPool.sol';

// /// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
// ///  selfdestruct, as far as RentalityUtils doesn't has this logic,
// /// it's completely safe for upgrade
// /// @custom:oz-upgrades-unsafe-allow external-library-linking
// contract RentalityInvestment is Initializable, UUPSAccess, ARentalityContext {
//   uint private investmentId;
//   RentalityCurrencyConverter private converter;
//   RentalityCarToken private carToken;
//   RentalityInsurance private insuranceService;

//   mapping(uint => Schemas.CarInvestment) private investmentIdToCarInfo;
//   mapping(uint => RentalityCarInvestmentPool) private investIdToPool;
//   mapping(uint => RentalityInvestmentNft) private investIdToNft;
//   mapping(uint => address) private investmentIdToCreator;
//   mapping(uint => uint) private carIdToInvestId;
//   RentalityInvestDeployer private investDeployer;
//   mapping(uint => address) private investmentIdToCurrency;
//   mapping((uint => bool) private investmentIdToListed;
//   mapping(uint => bool) private investIdToclaimed;

//     modifier onlyPlatform() {
//   require(isTrustedForwarder(msg.sender), "Only forwarder");
//   _;
// }

//   function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, address currency) public onlyPlatform {
//     address sender = _msgGatewaySender();
//     require(RentalityUserService(address(userService)).isInvestorManager(sender), 'only Invest Manager');
//         require(converter.currencyTypeIsAvailable(currency), 'currency type is not available');

//     investmentId += 1;
//     string memory sym = _createSumbol(investmentId);
//     investmentIdToCurrency[investmentId] = currency;

//     investmentIdToCarInfo[investmentId] = car;
//     investIdToNft[investmentId] = RentalityInvestmentNft(
//       investDeployer.createNewNft(name_, sym, investmentId, car.car.tokenUri)
//     );
//     investmentIdToCreator[investmentId] = sender;
//     investmentIdToListed[investmentId] = true;

//         investIdToPool[investmentId] = RentalityLiquidityPool(
//       investDeployer.createNewPool(
//         investmentId,
//         investmentIdToCurrency[investmentId],
//         name_,
//         sym
//       ));
//   }

//   function invest(uint investId, uint amount) public payable onlyPlatform {
//     address sender = _msgGatewaySender();
//     Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];
//     require(investmentIdToListed[investId], 'Investment: not listed');

//     require(investment.inProgress, 'Not available');

//     uint payedInCurrency = _getPoolBalance[investId];
//     uint amountAfterInvestment = payedInCurrency + amount;


//     if (amountAfterInvestment == investment.priceInCurrency) {
//       investment.inProgress = false;
//     }

//     address currency = investmentIdToCurrency[investmentId];
//     if (currency == address(0)) {
//       require(msg.value == amount, "amount is not eq to msg.value");
//       investIdToPool[investId].deposit{value: amount}(amount, sender);

//     } else {
//       require(IERC20(currency).allowance(sender, address(this)) >= amount, 'Investment: wrong allowance');
//       bool success = IERC20(currency).transferFrom(sender, address(investIdToPool), amount);
//        investIdToPool[investId].deposit{value: amount}(amount, sender);
//       require(success, 'Transfer failed.');
//     }
//   }


//   function claim(uint investId, Schemas.CreateCarRequest memory createCarRequest) public onlyPlatform {
//     address sender = _msgGatewaySender();
//      bool isInvestorManager = RentalityUserService(address(userService)).isInvestorManager(sender);
//     require(isInvestorManager, 'Only for creator');
//     require(!investIdToClaimed[investId], 'Claimed');
//     require(carToken.isUniqueVinNumber(createCarRequest.carVinNumber), 'Car with this VIN number already exists');


//     Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];
//     investment.car = createCarRequest;
    
//     uint amountInvested = _getPoolBalance(investId);
  
//     if (investment.priceInCurrency <= amountInvested || !investment.inProgress)
//         investment.inProgress = false;

//     require(!investment.inProgress, 'In progress');
//       investIdToClaimed[investId] = true;


//     uint carId = carToken.addCar(investment.car, sender);
//     insuranceService.saveInsuranceRequired(
//       carId,
//       investment.car.insurancePriceInUsdCents,
//       investment.car.insuranceRequired,
//       sender
//     );
//     carIdToInvestId[carId] = investId;
//     RentalityLiquidityPool(investIdToPool).claimToBuy(sender, amountInvested);
//     }
//   }

//   function getPaymentsInfo(
//     uint carId
//   ) public onlyPlatform view returns (uint percents, RentalityLiquidityPool pool, address currency) {
//     uint invesment = carIdToInvestId[carId];
//     percents = investmentIdToCarInfo[invesment].creatorPercents;
//     pool = investIdToPool[invesment];
//     currency = investmentIdToCurrency[invesment];
//   }
  
//   function getAllInvestments() onlyPlatform public view returns (Schemas.InvestmentDTO[] memory investments) {
//     address sender = _msgGatewaySender();
//     investments = new Schemas.InvestmentDTO[](investmentId);
//     uint totalInvestments = 0;
//     bool isInvestorManager = RentalityUserService(address(userService)).isInvestorManager(sender);
//     for (uint i = 1; i <= investmentId; i++) {
//       Schemas.CarInvestment memory investment = investmentIdToCarInfo[i];
//       if(investmentIdToListed[i] || isInvestorManager) {
  
//       uint price = 0;
//       uint myShares = 0;
//       bool isBought = investmentIdToClaimed[i];
//       address currency = investmentIdToCurrency[i];
//       (uint[] memory tokens, uint iInvested, uint totalHolders, uint totalTokens) = RentalityViewLib
//         .getAllMyTokensWithTotalPrice(sender, investIdToNft[i]);
//       (uint payed, , ) = converter.getToUsdLatest(currency, investmentIdToPayedInETH[i]);
//       if (isBought) {
//         RentalityLiquidityPool pool = RentalityLiquidityPool(investIdToPool[i]);
//         price  =  pool.convertToAssets(1 ** investIdToPool[i].decimals());
//        myShares = pool.balanceOf(sender);

//       }
//       (uint percentages,) = RentalityViewLib.calculatePercentage(
//         pool.totalSupply(),
//         myShares
//       );
           
//       (uint priceInUsdCents, , ) = converter.getToUsdLatest(currency, investment.priceInCurrency);
    
//       investments[totalInvestments] = Schemas.InvestmentDTO(
//         investment,
//         address(investIdToNft[i]),
//         i,
//         payed,
//         investmentIdToCreator[i],
//         isBought,
//         income,
//         myIncome,
//         iInvested,
//         isBought ? investIdToPool[i].creationDate() : 0,
//         tokens.length,
//         percentages,
//         totalHolders,
//         totalTokens,
//         currency,
//         !isBought ? 0 : investIdToPool[i].getTotalEarnings(),
//         !isBought ? 0 : investIdToPool[i].getTotalEarningsByUser(sender),
//         investIdToNft[i].name(),
//         investIdToNft[i].symbol(),
//         priceInUsdCents,
//         investmentIdToPayedInETH[i],
//         investmentIdToListed[i]
//       );
//       totalInvestments++; 
//     }
//     }
//       assembly("memory-safe") {
//         mstore(investments, totalInvestments)
//       }
//   }

//   function changeListingStatus(uint investId) onlyPlatform public {
//      address sender = _msgGatewaySender();
//     require(RentalityUserService(address(userService)).isInvestorManager(sender), 'only Invest manager');
//     bool listed = investmentIdToListed[investId];
//     investmentIdToListed[investId] = !listed;
//   }
 

//   function claimAllMy(uint investId) onlyPlatform public {
//     address sender = _msgGatewaySender();
//     (uint[] memory tokens, , , ) = RentalityViewLib.getAllMyTokensWithTotalPrice(sender, investIdToNft[investId]);
//     investIdToPool[investId].claimAllMy(sender, tokens);
//   }

//   function _getTotalIncomeByNFTs(
//     uint[] memory tokens,
//     RentalityCarInvestmentPool pool,
//     RentalityInvestmentNft nft
//   ) private view returns (uint) {
//     uint totalIncome = 0;
//     for (uint i = 0; i < tokens.length; i++) {
//       totalIncome += _getIncomesByNftId(tokens[i], pool, nft);
//     }
//     return totalIncome;
//   }
//   function _getIncomesByNftId(
//     uint id,
//     RentalityCarInvestmentPool pool,
//     RentalityInvestmentNft nft
//   ) private view returns (uint) {
//     (Income[] memory incomes, uint lastIncomeClaimed, uint totalPriceInEth) = pool.getIncomeInfoByNft(id);
//     uint tokenPrice = nft.tokenIdToPriceInEth(id);
//     uint part = (tokenPrice * 100_000) / totalPriceInEth;

//     uint result = 0;
//     for (uint i = lastIncomeClaimed; i < incomes.length; i++) {
//       result += incomes[i].income;
//     }
//     return (result * part) / 100_000;
//   }

//    function _createSumbol(uint tokenId) private view returns (string memory) {
//     (uint month, uint year) = _getMonthAndYear();
//     string memory monthResult;

//     if (month < 10) monthResult = string.concat('0', Strings.toString(month));
//     else monthResult = Strings.toString(month);

//     return
//       string.concat(
//         string.concat(string.concat('RENTALITY', '-00000'), Strings.toString(tokenId)),
//         string.concat('-', string.concat(string.concat(monthResult, Strings.toString(year % 100))))
//       );
//   }
//   function _getMonthAndYear() private view returns (uint month, uint year) {
//     uint timestamp = block.timestamp;
//     int256 z = int256(timestamp / 86400 + 719468);

//     int256 era = (z >= 0 ? z : z - 146096) / 146097;

//     int256 doe = z - era * 146097;

//     int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;

//     year = uint256(yoe) + uint256(era) * 400;

//     int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);

//     int256 mp = (5 * doy + 2) / 153;

//     month = uint256(mp + 3);

//     if (month > 12) {
//       month -= 12;

//       year += 1;
//     }
//   }

//   function _getPoolBalance(uint investId) private view returns (uint) {
//     return investIdToPool[investId].totalAssetsUnderManagement();
//   }



//   function isTrustedForwarder(address forwarder) internal view override returns (bool) {
//     return userService.isRentalityPlatform(forwarder);
//   }



//   function initialize(
//     address _userService,
//     address _currencyConverter,
//     address _carService,
//     address _insuranceServce,
//     address _investDeployer
//   ) public initializer {
//     userService = IRentalityAccessControl(_userService);
//     converter = RentalityCurrencyConverter(_currencyConverter);
//     carToken = RentalityCarToken(_carService);
//     insuranceService = RentalityInsurance(_insuranceServce);
//     investDeployer = RentalityInvestDeployer(_investDeployer);
//   }
// }
