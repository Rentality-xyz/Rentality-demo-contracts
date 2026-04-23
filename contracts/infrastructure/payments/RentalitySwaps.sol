// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../../models/payment/PaymentTypes.sol';
import '../upgradeable/UUPSOwnable.sol';

interface IRentalitySwapsAccess {
  function isAdmin(address user) external view returns (bool);
}

contract RentalitySwaps is UUPSOwnable {
  address public router;
  address public weth;
  address public allowedToken;
  IRentalitySwapsAccess public userAccess;
  address public uniswapFactory;

  error OnlyAdmin();

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address routerAddress,
    address wethAddress,
    address allowedTokenAddress,
    address userAccessAddress,
    address uniswapFactoryAddress
  ) public initializer {
    __Ownable_init();
    router = routerAddress;
    weth = wethAddress;
    allowedToken = allowedTokenAddress;
    userAccess = IRentalitySwapsAccess(userAccessAddress);
    uniswapFactory = uniswapFactoryAddress;
  }

  function swapExactInputSingle(
    address from,
    address to,
    uint128 amountIn,
    address sender,
    uint128 minimumAmountOut,
    uint24
  ) external payable returns (uint256 amountOut) {
    if (from == to) {
      return amountIn;
    }
    if (to != address(0) && sender != address(this)) {
      IERC20(to).transfer(sender, minimumAmountOut);
    }
    return minimumAmountOut;
  }

  function getAllowedCurrencies() external view returns (AllowedCurrencyDTO[] memory currencies) {
    uint256 length = allowedToken == address(0) ? 1 : 2;
    currencies = new AllowedCurrencyDTO[](length);
    currencies[0] = AllowedCurrencyDTO(18, 'Native', 'NATIVE', address(0));
    if (allowedToken != address(0)) {
      currencies[1] = AllowedCurrencyDTO(
        IERC20Metadata(allowedToken).decimals(),
        IERC20Metadata(allowedToken).name(),
        IERC20Metadata(allowedToken).symbol(),
        allowedToken
      );
    }
  }

  function setAllowedToken(address allowedTokenAddress) external {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }
    allowedToken = allowedTokenAddress;
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalitySwapsAccess(userAccessAddress);
  }
}
