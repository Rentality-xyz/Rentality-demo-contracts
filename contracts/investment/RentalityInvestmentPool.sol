// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import './RentalityInvestmentNft.sol';
import {IERC20} from '../payments/abstract/IERC20.sol';

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
    address private currency;

    constructor(uint _investmentId, address _nft, uint totalPrice, address _userService, address _currency) {
        nft = RentalityInvestmentNft(_nft);
        investmentID = _investmentId;
        totalPriceInEth = totalPrice;
        userService = IRentalityAccessControl(_userService);
        creationDate = block.timestamp;
        currency = _currency;
    }
    function deposit(uint totalProfit, uint amount) public payable {
       require(userService.isManager(msg.sender),"only Manager"); 
        incomes.push(Income(amount, totalProfit));
    }

    function claimAllMy(address user, uint[] memory tokens) public {
        require(userService.isManager(msg.sender),"only Manager");
        require(incomes.length > 0, 'no incomes');
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
            if(currency == address(0)) {
            (bool successRefund,) = payable(user).call{value: toClaim}('');
            require(successRefund, 'payment failed.');
            }
            else {
                bool success = IERC20(currency).transfer(user, toClaim);
                require(success, "investment: tranfer fail");
            }
        }
    }

    function getIncomeInfoByNft(uint id) public view returns(Income[] memory, uint, uint) {
        return (incomes, nftIdToLastIncomeNumber[id], totalPriceInEth);
    }
}