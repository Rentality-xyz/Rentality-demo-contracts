// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './RentalityInvestmentNft.sol';

    struct Income {
        uint income;
        uint totalProfit;
    }

contract RentalityCarInvestmentPool {
    IRentalityAccessControl private userService;
    RentalityInvestmentNft private immutable nft;
    uint private immutable investmentID;
    uint private immutable totalPriceInEth;

    Income[] private incomes;

    mapping(uint => uint) private nftIdToLastIncomeNumber;
    uint public creationDate;

    constructor(uint _investmentId, address _nft, uint totalPrice, address _userService) {
        nft = RentalityInvestmentNft(_nft);
        investmentID = _investmentId;
        totalPriceInEth = totalPrice;
        userService = IRentalityAccessControl(_userService);
        creationDate = block.timestamp;
    }
    function deposit(uint totalProfit) public payable {
       require(userService.isManager(msg.sender),"only Manager"); 
        incomes.push(Income(msg.value, totalProfit));
    }

    function claimAllMy(address user) public {
        require(userService.isManager(msg.sender),"only Manager");
        require(incomes.length > 0, 'no incomes');
        (uint[] memory tokens,,,) = nft.getAllMyTokensWithTotalPrice(user);
        uint toClaim = 0;
        for (uint i = 0; i < tokens.length; i++) {
            uint lastIncomeClaimed = nftIdToLastIncomeNumber[tokens[i]];
            uint tokenPrice = nft.tokenIdToPriceInEth(tokens[i]);
            uint part = (tokenPrice * 100_000) / totalPriceInEth;
            if (incomes.length > lastIncomeClaimed) {
                uint totalIncome = 0;
                for (uint j = lastIncomeClaimed; j < incomes.length; j++) {
                    totalIncome += incomes[j].income;
                }
                toClaim += (totalIncome * part) / 100_000;
                nftIdToLastIncomeNumber[tokens[i]] = incomes.length;
            }
        }

        if (toClaim > 0) {
            (bool successRefund,) = payable(user).call{value: toClaim}('');
            require(successRefund, 'payment failed.');
        }
    }

    function getIncomesByNftId(uint id) public view returns (uint) {
        uint lastIncomeClaimed = nftIdToLastIncomeNumber[id];
        uint tokenPrice = nft.tokenIdToPriceInEth(id);
        uint part = (tokenPrice * 100_000) / totalPriceInEth;

        uint result = 0;
        for (uint i = lastIncomeClaimed; i < incomes.length; i++) {
            result += incomes[i].income;
        }
        return (result * part) / 100_000;
    }


    function getTotalIncome() public view returns (uint) {
        uint result = 0;
        for (uint i = 0; i < incomes.length; i++) {
            result += incomes[i].totalProfit;
        }
        return result;
    }
}
