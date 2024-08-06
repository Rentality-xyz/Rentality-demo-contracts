// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "./RentalityInvestmentNft.sol";


contract RentalityCarInvestmentPool {
    IRentalityAccessControl private userService;
    RentalityInvestmentNft immutable private nft;
    uint immutable private investmentID;
    uint immutable private totalPriceInEth;

    uint[] private incomes;

    mapping(uint => uint) private nftIdToLastIncomeNumber;

    constructor(uint _investmentId, address _nft, uint totalPrice, address _userService) {
        nft = RentalityInvestmentNft(_nft);
        investmentID = _investmentId;
        totalPriceInEth = totalPrice;
        userService = IRentalityAccessControl(_userService);
    }
    function deposit() public payable {
        incomes.push(msg.value);
    }

    function claimAllMy() public {
        require(incomes.length > 0, "no incomes");
        uint[] memory tokens = nft.getMyTokens();
        uint toClaim = 0;
        for (uint i = 0; i < tokens.length; i++) {
            uint lastIncomeClaimed = nftIdToLastIncomeNumber[tokens[i]];
            uint tokenPrice = nft.tokenIdToPriceInEth(tokens[i]);
            uint part = (tokenPrice * 100_000) / totalPriceInEth;
            if (incomes.length > lastIncomeClaimed) {
                uint totalIncome = 0;
                for (uint j = lastIncomeClaimed; j < incomes.length; j++) {
                    totalIncome += incomes[j];
                }
                toClaim += (totalIncome * part) / 100_000;
                nftIdToLastIncomeNumber[tokens[i]] = incomes.length;
            }
        }

        if (toClaim > 0) {
            (bool successRefund,) = payable(tx.origin).call{value: toClaim}('');
            require(successRefund, 'payment failed.');

        }
    }

    function getIncomesByNftId(uint id) public view returns (uint) {
        uint lastIncomeClaimed = nftIdToLastIncomeNumber[id];
        uint result = 0;
        for (uint i = lastIncomeClaimed; i < incomes.length; i++) {
            result += incomes[i];
        }
        return result;
    }

    function getTotalIncome() public view returns (uint) {
        uint result = 0;
        for (uint i = 0; i < incomes.length; i++) {
            result += incomes[i];
        }
        return result;
    }

}
