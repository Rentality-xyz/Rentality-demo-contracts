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

contract RentalityInvestment is Initializable, UUPSAccess {
  uint public investmentId;
  RentalityCurrencyConverter private converter;
  RentalityCarToken private carToken;
  RentalityInsurance private insuranceService;

  mapping(uint => Schemas.CarInvestment) private investmentIdToCarInfo;
  mapping(uint => uint) public investmentIdToPayedInETH;
  mapping(uint => RentalityCarInvestmentPool) private investIdToPool;
  mapping(uint => RentalityInvestmentNft) private investIdToNft;
  mapping(uint => address) private investmentIdToCreator;
  mapping(uint => uint) private carIdToInvestId;

  function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, string memory symbol_) public {
    require(carToken.isUniqueVinNumber(car.car.carVinNumber), 'Car with this VIN number already exists');

    investmentId += 1;
    investmentIdToCarInfo[investmentId] = car;
    RentalityInvestmentNft newNftCollection = new RentalityInvestmentNft(
      name_,
      symbol_,
      investmentId,
      car.car.tokenUri
    );
    investIdToNft[investmentId] = newNftCollection;
    investmentIdToCreator[investmentId] = msg.sender;
  }

  function invest(uint investId) public payable {
    uint payedInETH = investmentIdToPayedInETH[investId];
    Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];

    require(investment.inProgress, 'Not available');

    (uint amountAfterInvestment,,) = converter.getToUsdLatest(address(0), payedInETH + msg.value);

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
    uint payedInETH = investmentIdToPayedInETH[investId];
    RentalityCarInvestmentPool newPool = new RentalityCarInvestmentPool(
      investId,
      address(investIdToNft[investId]),
      payedInETH,
      address(userService)
    );
    investIdToPool[investId] = newPool;

    uint carId = carToken.addCar(investment.car, msg.sender);
     insuranceService.saveInsuranceRequired(carId, investment.car.insurancePriceInUsdCents, investment.car.insuranceRequired, msg.sender);
    carIdToInvestId[carId] = investId;
    (bool success, ) = payable(msg.sender).call{value: payedInETH}('');
    require(success, 'Fail to transfer.');
  }

  function isInvestorsCar(uint carId) public view returns (bool) {
    return carIdToInvestId[carId] != 0;
  }

  function getPaymentsInfo(uint carId) public view returns (uint, RentalityCarInvestmentPool) {
    uint investID = carIdToInvestId[carId];
    require(investID != 0, 'Wrong car');

    return (investmentIdToCarInfo[investID].creatorPercents, investIdToPool[investID]);
  }

  function getAllInvestments() public view returns (Schemas.InvestmentDTO[] memory) {
    Schemas.InvestmentDTO[] memory cars = new Schemas.InvestmentDTO[](investmentId);
    for (uint i = 1; i <= investmentId; i++) {
      (uint payed, , ) = converter.getToUsdLatest(address(0), investmentIdToPayedInETH[i]);
      uint income = 0;
      uint myIncomeInUsdCents = 0;
      bool isBought = address(investIdToPool[i]) != address(0);
      if (isBought) {
        (income, , ) = converter.getToUsdLatest(address(0), investIdToPool[i].getTotalIncome());
        (uint[] memory tokens, ) = investIdToNft[i].getAllMyTokensWithTotalPrice(msg.sender);
        uint myIncome = 0;
        for (uint j = 0; j < tokens.length; j++) {
          myIncome += investIdToPool[i].getIncomesByNftId(tokens[j]);
        }
        (myIncomeInUsdCents, , ) = converter.getToUsdLatest(address(0), myIncome);
      }
      cars[i - 1] = Schemas.InvestmentDTO(
        investmentIdToCarInfo[i],
        address(investIdToNft[i]),
        i,
        payed,
        investmentIdToCreator[i],
        isBought,
        income,
        myIncomeInUsdCents
      );
    }
    return cars;
  }

  function claimAllMy(uint investId) public {
    investIdToPool[investId].claimAllMy(msg.sender);
  }

  /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.

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
