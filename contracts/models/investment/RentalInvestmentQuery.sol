// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '../base/investment/InvestmentTypes.sol';
import './RentalInvestmentMain.sol';
import './RentalInvestmentTypes.sol';

interface IRentalInvestmentQueryCurrencyConverter {
    function getToUsdLatest(address currencyType, uint256 amount) external view returns (uint256, int256, uint8);
}

interface IRentalInvestmentQueryNft {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenIdToPriceInEth(uint256 tokenId) external view returns (uint256);
    function totalSupplyWithTotalHolders() external view returns (uint256, uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

struct RentalInvestmentPoolIncome {
    uint256 income;
    uint256 totalProfit;
}

interface IRentalInvestmentQueryPool {
    function getIncomeInfoByNft(uint256 id)
        external
        view
        returns (RentalInvestmentPoolIncome[] memory, uint256, uint256);
    function creationDate() external view returns (uint256);
    function getTotalEarnings() external view returns (uint256);
    function getTotalEarningsByUser(address user) external view returns (uint256);
}

contract RentalInvestmentQuery {
    RentalInvestmentMain public immutable rentalInvestmentMain;
    IRentalInvestmentQueryCurrencyConverter public immutable converter;

    constructor(address rentalInvestmentMainAddress, address converterAddress) {
        rentalInvestmentMain = RentalInvestmentMain(rentalInvestmentMainAddress);
        converter = IRentalInvestmentQueryCurrencyConverter(converterAddress);
    }

    function getPaymentsInfo(uint256 carId)
        external
        view
        returns (uint256 percents, address pool, address currency)
    {
        InvestmentPayoutRoute memory payoutRoute = rentalInvestmentMain.getPaymentsInfo(carId);
        return (payoutRoute.creatorPercents, payoutRoute.pool, payoutRoute.currency);
    }

    function getAllInvestments(address user, bool isInvestorManager)
        external
        view
        returns (RentalInvestmentDTO[] memory investments)
    {
        uint256 total = rentalInvestmentMain.getInvestmentCount();
        investments = new RentalInvestmentDTO[](total);
        uint256 count = 0;
        for (uint256 i = 1; i <= total; i++) {
            bool listed = rentalInvestmentMain.isListed(i);
            if (!listed && !isInvestorManager) {
                continue;
            }

            RentalInvestmentDTO memory dto = _buildInvestmentDTO(i, user, listed);
            investments[count] = dto;
            count += 1;
        }

        assembly ('memory-safe') {
            mstore(investments, count)
        }
    }

    function getClaimInvestmentInfo(uint256 investId, address user)
        external
        view
        returns (RentalClaimInvestmentDTO memory)
    {
        address nftAddress = rentalInvestmentMain.getNft(investId);
        address poolAddress = rentalInvestmentMain.getPool(investId);
        if (nftAddress == address(0) || poolAddress == address(0)) {
            return RentalClaimInvestmentDTO({tokenURI: '', income: 0, myIncome: 0});
        }

        IRentalInvestmentQueryNft nft = IRentalInvestmentQueryNft(nftAddress);
        IRentalInvestmentQueryPool pool = IRentalInvestmentQueryPool(poolAddress);
        (uint256[] memory tokens, , , ) = _getAllMyTokensWithTotalPrice(user, nft);
        string memory tokenUri = tokens.length > 0 ? nft.tokenURI(tokens[0]) : '';

        return RentalClaimInvestmentDTO({
            tokenURI: tokenUri,
            income: _getTotalIncome(pool),
            myIncome: _getTotalIncomeByNFTs(tokens, pool, nft)
        });
    }

    function _buildInvestmentDTO(uint256 investmentId, address user, bool listed)
        internal
        view
        returns (RentalInvestmentDTO memory)
    {
        RentalCarInvestment memory investment = rentalInvestmentMain.getInvestment(investmentId);
        address nftAddress = rentalInvestmentMain.getNft(investmentId);
        address poolAddress = rentalInvestmentMain.getPool(investmentId);
        address currency = rentalInvestmentMain.getInvestmentCurrency(investmentId);
        address creator = rentalInvestmentMain.getCreator(investmentId);
        uint256 payedInCurrency = rentalInvestmentMain.getInvestedAmount(investmentId);
        (uint256 payedInUsd, , ) = converter.getToUsdLatest(currency, payedInCurrency);
        (uint256 priceInUsdCents, , ) = converter.getToUsdLatest(currency, investment.priceInCurrency);

        bool isBought = poolAddress != address(0);
        uint256 income = 0;
        uint256 myIncome = 0;
        uint256 listingDate = 0;
        uint256 myTokens = 0;
        uint256 myPart = 0;
        uint256 totalHolders = 0;
        uint256 totalTokens = 0;
        uint256 totalEarnings = 0;
        uint256 userReceivedEarnings = 0;
        string memory name = '';
        string memory symbol = '';
        uint256 myInvestingSum = 0;

        if (nftAddress != address(0)) {
            IRentalInvestmentQueryNft nft = IRentalInvestmentQueryNft(nftAddress);
            uint256[] memory tokens;
            (tokens, myInvestingSum, totalHolders, totalTokens) = _getAllMyTokensWithTotalPrice(user, nft);
            myTokens = tokens.length;
            (myPart,) = _calculatePercentage(myInvestingSum, investment.priceInCurrency);
            name = nft.name();
            symbol = nft.symbol();
            if (isBought) {
                IRentalInvestmentQueryPool pool = IRentalInvestmentQueryPool(poolAddress);
                income = _getTotalIncome(pool);
                myIncome = _getTotalIncomeByNFTs(tokens, pool, nft);
                listingDate = pool.creationDate();
                totalEarnings = pool.getTotalEarnings();
                userReceivedEarnings = pool.getTotalEarningsByUser(user);
            }
        }

        return RentalInvestmentDTO({
            investment: investment,
            nft: nftAddress,
            investmentId: investmentId,
            payedInUsd: payedInUsd,
            creator: creator,
            isCarBought: isBought,
            income: income,
            myIncome: myIncome,
            myInvestingSum: myInvestingSum,
            listingDate: listingDate,
            myTokens: myTokens,
            myPart: myPart,
            totalHolders: totalHolders,
            totalTokens: totalTokens,
            currency: currency,
            totalEarnings: totalEarnings,
            userReceivedEarnings: userReceivedEarnings,
            name: name,
            symbol: symbol,
            priceInUsdCents: priceInUsdCents,
            payedInCurrency: payedInCurrency,
            listed: listed
        });
    }

    function _calculatePercentage(uint256 invested, uint256 totalPrice) internal pure returns (uint256, uint256) {
        uint256 percentages = invested == 0 ? 0 : Math.ceilDiv(invested * 100, totalPrice);
        return (percentages, invested);
    }

    function _getAllMyTokensWithTotalPrice(address user, IRentalInvestmentQueryNft nft)
        internal
        view
        returns (uint256[] memory, uint256, uint256, uint256)
    {
        uint256[] memory result = new uint256[](nft.balanceOf(user));
        uint256 counter = 0;
        uint256 totalPrice = 0;
        (uint256 totalSupply, uint256 totalHolders) = nft.totalSupplyWithTotalHolders();
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (nft.ownerOf(i) == user) {
                result[counter] = i;
                counter += 1;
                totalPrice += nft.tokenIdToPriceInEth(i);
            }
        }
        return (result, totalPrice, totalHolders, totalSupply);
    }

    function _getTotalIncome(IRentalInvestmentQueryPool pool) internal view returns (uint256) {
        (RentalInvestmentPoolIncome[] memory incomes, , ) = pool.getIncomeInfoByNft(0);
        uint256 result = 0;
        for (uint256 i = 0; i < incomes.length; i++) {
            result += incomes[i].totalProfit;
        }
        return result;
    }

    function _getTotalIncomeByNFTs(
        uint256[] memory tokens,
        IRentalInvestmentQueryPool pool,
        IRentalInvestmentQueryNft nft
    ) internal view returns (uint256) {
        uint256 totalIncome = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            totalIncome += _getIncomesByNftId(tokens[i], pool, nft);
        }
        return totalIncome;
    }

    function _getIncomesByNftId(
        uint256 id,
        IRentalInvestmentQueryPool pool,
        IRentalInvestmentQueryNft nft
    ) internal view returns (uint256) {
        (RentalInvestmentPoolIncome[] memory incomes, uint256 lastIncomeClaimed, uint256 totalPriceInEth) =
            pool.getIncomeInfoByNft(id);
        uint256 tokenPrice = nft.tokenIdToPriceInEth(id);
        uint256 part = (tokenPrice * 100_000) / totalPriceInEth;
        uint256 result = 0;
        for (uint256 i = lastIncomeClaimed; i < incomes.length; i++) {
            result += incomes[i].income;
        }
        return (result * part) / 100_000;
    }
}
