// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../payments/RentalityCurrencyConverter.sol";
import "./RentalityInvestmentPool.sol";
import "../RentalityCarToken.sol";


contract RentalityInvestment is Initializable, UUPSAccess {
    uint public investmentId;
    RentalityCurrencyConverter private converter;
    RentalityCarToken private carToken;

    mapping(uint => Schemas.CarInvestment) public investmentIdToCarInfo;
    mapping(uint => uint) private investmentIdToPayedInETH;
    mapping(uint => RentalityCarInvestmentPool) private investIdToPool;
    mapping(uint => RentalityInvestmentNft) private investIdToNft;

    function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, string memory symbol_) public {
        require(userService.isAdmin(tx.origin), "only Admin");
        investmentId += 1;
        investmentIdToCarInfo[investmentId] = car;
        RentalityInvestmentNft newNftCollection = new RentalityInvestmentNft(name_, symbol_, investmentId, car.car.tokenUri);
        investIdToNft[investmentId] = newNftCollection;
    }

    function invest(uint investId) public payable {
        uint payedInETH = investmentIdToPayedInETH[investmentId];
        Schemas.CarInvestment storage investment = investmentIdToCarInfo[investmentId];

        uint amountInUsd = converter.getToUsdWithCache(address(0), payedInETH);
        require(investment.inProgress, "Not available");

        uint amountAfterInvestment = converter.getToUsdWithCache(address(0), payedInETH + msg.value);

        if (amountAfterInvestment >= investment.priceInUsd) {
            investment.inProgress = false;
            RentalityCarInvestmentPool newPool = new RentalityCarInvestmentPool(
                investId,
                address(investIdToNft[investmentId]),
                payedInETH + msg.value,
                address(userService)
            );
            investIdToPool[investmentId] = newPool;
            carToken.addCar(investment.car);
        }
        investmentIdToPayedInETH[investmentId] += msg.value;
        investIdToNft[investmentId].mint(msg.value);
        uint tokenId = investIdToNft[investmentId].tokenId();

    }

    function getAllInvestments() public view returns (Schemas.CarInvestment[] memory) {
        Schemas.CarInvestment[] memory cars = new Schemas.CarInvestment[](investmentId);
        for (uint i = 0; i < investmentId; i ++) {
            cars[i] = investmentIdToCarInfo[i];
        }
        return cars;
    }

    function getMyInvestmentsToClaim() public view returns (Schemas.InvestmentDTO[] memory) {
        Schemas.InvestmentDTO[] memory result;
        uint counter = 0;
        for (uint i = 0; i < investmentId; i++)
            if (investIdToNft[i].hasInvestments(tx.origin))
                counter ++;
        result = new Schemas.InvestmentDTO[](counter);
        for (uint i = 0; i < investmentId; i++) {
            result[i].tokenURI = investIdToNft[i].tokenURI(i);
            result[i].income = investIdToPool[i].getTotalIncome();
            (uint[] memory tokens,) = investIdToNft[i].getAllMyTokensWithTotalPrice();
            uint myIncome = 0;
            for (uint i = 0; i < tokens.length; i++) {
                myIncome += investIdToPool[i].getIncomesByNftId(i);
            }
            result[i].myIncome = myIncome;

        }

        return result;


    }

    /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.

    function initialize(address _userService, address _currencyConverter) public initializer {
        userService = IRentalityAccessControl(_userService);
        converter = RentalityCurrencyConverter(_currencyConverter);
    }
}
