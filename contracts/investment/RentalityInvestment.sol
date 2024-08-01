// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../payments/RentalityCurrencyConverter.sol";
import "./RentalityInvestmentPool.sol";
import "../RentalityCarToken.sol";
import "../Schemas.sol";


contract RentalityInvestment is Initializable, UUPSAccess {
    uint public investmentId;
    RentalityCurrencyConverter private converter;
    RentalityCarToken private carToken;

    mapping(uint => Schemas.CarInvestment) public investmentIdToCarInfo;
    mapping(uint => uint) private investmentIdToPayedInETH;
    mapping(uint => RentalityCarInvestmentPool) private investIdToPool;
    mapping(uint => RentalityInvestmentNft) private investIdToNft;
    mapping(uint => address) private investmentIdToCreator;
    mapping(uint => uint) private carIdToInvestId;

    function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, string memory symbol_) public {
        require(userService.isHost(tx.origin), "only Host");
        investmentId += 1;
        investmentIdToCarInfo[investmentId] = car;
        RentalityInvestmentNft newNftCollection = new RentalityInvestmentNft(name_, symbol_, investmentId, car.car.tokenUri);
        investIdToNft[investmentId] = newNftCollection;
        investmentIdToCreator[investmentId] = tx.origin;
    }

    function invest(uint investId) public payable {
        uint payedInETH = investmentIdToPayedInETH[investId];
        Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];

        uint amountInUsd = converter.getToUsdWithCache(address(0), payedInETH);
        require(investment.inProgress, "Not available");

        uint amountAfterInvestment = converter.getToUsdWithCache(address(0), payedInETH + msg.value);

        if (amountAfterInvestment >= investment.priceInUsd) {
            investment.inProgress = false;
        }
        investmentIdToPayedInETH[investId] += msg.value;
        investIdToNft[investId].mint(msg.value);
        uint tokenId = investIdToNft[investId].tokenId();
    }

    function claimAndCreatePool(uint investId) public {
        require(investmentIdToCreator[investId] == tx.origin, "Only for creator");
        require(address(investIdToPool[investId]) == address(0), "Already claimed");

        Schemas.CarInvestment storage investment = investmentIdToCarInfo[investId];
        require(!investment.inProgress, "Still in progress");
        uint payedInETH = investmentIdToPayedInETH[investId];
        RentalityCarInvestmentPool newPool = new RentalityCarInvestmentPool(
            investId,
            address(investIdToNft[investId]),
            payedInETH,
            address(userService)
        );
        investIdToPool[investId] = newPool;
        uint carId = carToken.addCar(investment.car);
        carIdToInvestId[carId] = investId;
        (bool success,) = payable(tx.origin).call{value: payedInETH}('');
        require(success, 'Fail to transfer.');

    }

    function isInvestorsCar(uint carId) public view returns (bool) {
        return carIdToInvestId[carId] != 0;
    }

    function getPaymentsInfo(uint carId) public view returns (uint, RentalityCarInvestmentPool) {
        uint investID = carIdToInvestId[carId];
        require(investID != 0, "Is not investment car");

        Schemas.CarInvestment storage investment = investmentIdToCarInfo[investID];
        return (investment.creatorPercents, investIdToPool[investID]);
    }


    function getAllInvestments() public view returns (Schemas.InvestmentDTO[] memory) {
        Schemas.InvestmentDTO[] memory cars = new Schemas.InvestmentDTO[](investmentId);
        for (uint i = 1; i <= investmentId; i++) {
            cars[i - 1] = Schemas.InvestmentDTO(
                investmentIdToCarInfo[i],
                address(investIdToNft[i])
            );
        }
        return cars;
    }

    function getMyInvestmentsToClaim() public view returns (Schemas.ClaimInvestmentDTO[] memory) {
        Schemas.ClaimInvestmentDTO[] memory result;
        uint counter = 0;
        for (uint i = 1; i <= investmentId; i++)
            if (investIdToNft[i].hasInvestments(tx.origin))
                counter ++;

        result = new Schemas.ClaimInvestmentDTO[](counter);
        for (uint i = 1; i <= investmentId; i++) {
            result[i - 1].tokenURI = investIdToNft[i].tokenURI(i);
            result[i - 1].income = investIdToPool[i].getTotalIncome();
            (uint[] memory tokens,) = investIdToNft[i].getAllMyTokensWithTotalPrice();
            uint myIncome = 0;
            for (uint j = 0; j < tokens.length; j++) {
                myIncome += investIdToPool[i].getIncomesByNftId(tokens[j]);
            }
            result[i - 1].myIncome = myIncome;

        }

        return result;

    }

    function claimAllMy(uint investId) public {
        investIdToPool[investId].claimAllMy();
    }

    /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.

    function initialize(address _userService, address _currencyConverter, address _carService) public initializer {
        userService = IRentalityAccessControl(_userService);
        converter = RentalityCurrencyConverter(_currencyConverter);
        carToken = RentalityCarToken(_carService);
    }
}
