// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '../infrastructure/upgradeable/UUPSOwnable.sol';

contract RentalityInvestmentNftMock is ERC721URIStorage {
  address public immutable minter;
  string private storedTokenUri;
  uint256 private nextTokenId;
  uint256 private holdersCount;
  mapping(uint256 => uint256) public tokenIdToPriceInEth;

  constructor(string memory name_, string memory symbol_, string memory tokenUri_, address minter_)
    ERC721(name_, symbol_)
  {
    storedTokenUri = tokenUri_;
    minter = minter_;
  }

  function mint(uint256 amount, address user) external returns (uint256 tokenId) {
    require(msg.sender == minter, 'Only minter');

    if (balanceOf(user) == 0) {
      holdersCount += 1;
    }

    nextTokenId += 1;
    tokenId = nextTokenId;
    tokenIdToPriceInEth[tokenId] = amount;
    _safeMint(user, tokenId);
    _setTokenURI(tokenId, storedTokenUri);
  }

  function totalSupplyWithTotalHolders() external view returns (uint256, uint256) {
    return (nextTokenId, holdersCount);
  }
}

contract RentalityInvestmentPoolMock {
  struct InvestmentPoolIncome {
    uint256 income;
    uint256 totalProfit;
  }

  uint256 public immutable creationDate;
  uint256 public immutable totalPriceInCurrency;

  constructor(uint256 totalPayed_) {
    creationDate = block.timestamp;
    totalPriceInCurrency = totalPayed_;
  }

  function claimAllMy(address, uint256[] memory) external {}

  function getIncomeInfoByNft(uint256)
    external
    view
    returns (InvestmentPoolIncome[] memory incomes, uint256 lastIncomeClaimed, uint256 totalPrice)
  {
    incomes = new InvestmentPoolIncome[](0);
    lastIncomeClaimed = 0;
    totalPrice = totalPriceInCurrency;
  }

  function getTotalEarnings() external pure returns (uint256) {
    return 0;
  }

  function getTotalEarningsByUser(address) external pure returns (uint256) {
    return 0;
  }
}

contract RentalityInvestDeployer is UUPSOwnable {
  address public userAccess;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress) public initializer {
    __Ownable_init();
    userAccess = userAccessAddress;
  }

  function createNewPool(uint256, address, uint256 totalPayed, address) external returns (address) {
    RentalityInvestmentPoolMock pool = new RentalityInvestmentPoolMock(totalPayed);
    return address(pool);
  }

  function createNewNft(string memory name, string memory sym, uint256, string memory tokenUri)
    external
    returns (address)
  {
    RentalityInvestmentNftMock nft = new RentalityInvestmentNftMock(name, sym, tokenUri, msg.sender);
    return address(nft);
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = userAccessAddress;
  }
}
