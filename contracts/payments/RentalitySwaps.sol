// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import '../RentalityCarToken.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {IRentalityAccessControl} from '../abstract/IRentalityAccessControl.sol';
import './swaps/ISwapRouter.sol';
import {IWETH} from './swaps/IWETH.sol';
import {IPermit2} from './swaps/IPermit2.sol';


   struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }


contract RentalitySwaps is Initializable, UUPSAccess {
    ISwapRouter public router;
    IPermit2 public permit2;
    address public weth;

    mapping(address => bool) private allowedCurrency;
    address[] private allowedCurrencyList;


    function initialize(address _router, address _weth, address allowedToken, address _nonfungiblePositionManager) public virtual initializer {
        router = ISwapRouter(_router);
        weth = _weth;
        allowedCurrency[allowedToken] = true;
        allowedCurrencyList.push(allowedToken);
    }
    function addAllowedCurrency(address currency) public {
        require(userService.isAdmin(msg.sender), "Only Admin");
        require(allowedCurrency[currency] == false, "Already exists");
        allowedCurrency[currency] = true;
        allowedCurrencyList.push(currency);
    }
    
    function getAllowedCurrencies() public view returns(Schemas.AllowedCurrencyDTO[] memory currencies) {
        currencies = new Schemas.AllowedCurrencyDTO[](allowedCurrencyList.length);
        for (uint i = 0; i < allowedCurrencyList.length; i++) {
            IERC20 tokenContract = IERC20(allowedCurrencyList[i]);
            currencies[i] = Schemas.AllowedCurrencyDTO({
                name: tokenContract.name(),
                symbol: tokenContract.symbol(),
                decimals: tokenContract.decimals(),
                tokenAddress: address(tokenContract)
            });
        }
    }



    function swapExactInputSingle(
    address from,
    address to,
    uint128 amountIn,
    address sender
) public payable returns (uint256 amountOut) {

    if(from == address(0)) {
        require(amountIn == msg.value, "Wrong value");
        IWETH(weth).deposit{value: msg.value}();
    }
    else {
    IERC20(from).transferFrom(sender, address(this), amountIn);
    }

    IERC20(from).approve(address(router), amountIn);
    ExactInputSingleParams memory params = ExactInputSingleParams({
        tokenIn: from,
        tokenOut: to,
        fee: 3000,
        recipient: address(this),
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
    });

   uint amount = router.exactInputSingle(params);
    IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this)));
    return amount;
}
  receive() external payable {}





}