// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../payments/RentalityCurrencyConverter.sol';
import './RentalityInvestmentPool.sol';
import '../RentalityCarToken.sol';
import '../Schemas.sol';
import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
import {RentalityViewLib} from '../libs/RentalityViewLib.sol';


/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityInvestment is Initializable, UUPSAccess {
  uint private investmentId;
  RentalityCurrencyConverter private converter;
  RentalityCarToken private carToken;
  RentalityInsurance private insuranceService;

  mapping(uint => Schemas.CarInvestment) private investmentIdToCarInfo;
  mapping(uint => uint) private investmentIdToPayedInETH;
  mapping(uint => RentalityCarInvestmentPool) private investIdToPool;
  mapping(uint => RentalityInvestmentNft) private investIdToNft;
  mapping(uint => address) private investmentIdToCreator;
  mapping(uint => uint) private carIdToInvestId;

  function createCarInvestment(Schemas.CarInvestment memory car, string memory name_) public {
    require(carToken.isUniqueVinNumber(car.car.carVinNumber), 'Car with this VIN number already exists');

    investmentId += 1;
   string memory sym = RentalityViewLib.createSumbol(investmentId);

    investmentIdToCarInfo[investmentId] = car;
    investIdToNft[investmentId] = new RentalityInvestmentNft(
      name_,
      sym,
      investmentId,
      car.car.tokenUri
    );
    investmentIdToCreator[investmentId] = msg.sender;
  }

  function invest(uint investId) public payable {
    Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];

    require(investment.inProgress, 'Not available');

    (uint amountAfterInvestment,,) = converter.getToUsdLatest(address(0), investmentIdToPayedInETH[investId] + msg.value);

    if (amountAfterInvestment >= investment.priceInUsd) {
      investment.inProgress = false;
    }
    investmentIdToPayedInETH[investId] += msg.value;
    investIdToNft[investId].mint(msg.value, msg.sender);
  }

  function claimAndCreatePool(uint investId) public {
    require(investmentIdToCreator[investId] == msg.sender, 'Only for creator');
    require(address(investIdToPool[investId]) == address(0), 'Claimed');

    Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];
    require(!investment.inProgress, 'In progress');
    investIdToPool[investId] = new RentalityCarInvestmentPool(
      investId,
      address(investIdToNft[investId]),
      investmentIdToPayedInETH[investId],
      address(userService)
    );

    uint carId = carToken.addCar(investment.car, msg.sender);
     insuranceService.saveInsuranceRequired(carId, investment.car.insurancePriceInUsdCents, investment.car.insuranceRequired, msg.sender);
    carIdToInvestId[carId] = investId;
    (bool success, ) = payable(msg.sender).call{value: investmentIdToPayedInETH[investId]}('');
    require(success, 'Fail to transfer.');
  }


  function getPaymentsInfo(uint carId) public view returns (uint percents, RentalityCarInvestmentPool pool) {
    percents = investmentIdToCarInfo[carIdToInvestId[carId]].creatorPercents;
    pool = investIdToPool[carIdToInvestId[carId]];
  }
 
  function getAllInvestments() public view returns (Schemas.InvestmentDTO[] memory cars) {
    cars = new Schemas.InvestmentDTO[](investmentId);
    for (uint i = 1; i <= investmentId; i++) {
      uint income = 0;
      uint myIncomeInUsdCents = 0;
      bool isBought = address(investIdToPool[i]) != address(0);
       (uint[] memory tokens, uint iInvested, uint totalHolders, uint totalTokens) = RentalityViewLib.getAllMyTokensWithTotalPrice(msg.sender, investIdToNft[i]);
       (uint payed,,) = converter.getToUsdLatest(address(0), investmentIdToPayedInETH[i]);
      if (isBought) {
        (income, , ) = converter.getToUsdLatest(address(0), RentalityViewLib.getTotalIncome(investIdToPool[i]));
        uint myIncome = RentalityViewLib.getTotalIncomeByNFTs(tokens,investIdToPool[i],investIdToNft[i]);
       
        (myIncomeInUsdCents, , ) = converter.getToUsdLatest(address(0), myIncome);
      }
      (uint percentages, uint investInUsd) = RentalityViewLib.calculatePercentage(iInvested,investmentIdToCarInfo[i].priceInUsd, converter);
      cars[i - 1] = Schemas.InvestmentDTO(
        investmentIdToCarInfo[i],
        address(investIdToNft[i]),
        i,
        payed,
        investmentIdToCreator[i],
        isBought,
        income,
        myIncomeInUsdCents,
        investInUsd,
        isBought ? investIdToPool[i].creationDate() : 0,
        tokens.length,
        percentages,
        totalHolders,
        totalTokens
      );
    }
  }

  function claimAllMy(uint investId) public {
    (uint[] memory tokens,,,) = RentalityViewLib.getAllMyTokensWithTotalPrice(msg.sender, investIdToNft[investId]);
    investIdToPool[investId].claimAllMy(msg.sender,tokens);
  }


  /// @notice Initializes the contract with the specified addresses

  function initialize(
    address _userService,
    address _currencyConverter,
    address _carService,
    address _insuranceServce
    ) public initializer {
    userService = IRentalityAccessControl(_userService);
    converter = RentalityCurrencyConverter(_currencyConverter);
    carToken = RentalityCarToken(_carService);
    insuranceService = RentalityInsurance(_insuranceServce);
  }
}