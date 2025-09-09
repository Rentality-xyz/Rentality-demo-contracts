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


   struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }


contract RentalitySwaps is Initializable, UUPSAccess {
    ISwapRouter public router;
    address public weth;

    mapping(address => bool) private allowedCurrency;
    address[] private allowedCurrencyList;



    function addAllowedCurrency(address currency) public {
        require(userService.isAdmin(msg.sender), "Only Admin");
        require(allowedCurrency[currency] == false, "Already exists");
        allowedCurrency[currency] = true;
        allowedCurrencyList.push(currency);
    }
        function addAllowedCurrencies(address[] memory currencies) public {
        require(userService.isAdmin(msg.sender), "Only Admin");
        for (uint i = 0; i < currencies.length; i++) {
        require(allowedCurrency[currencies[i]] == false, "Already exists");
        allowedCurrency[currencies[i]] = true;
        allowedCurrencyList.push(currencies[i]);
        }
    }
    
    
    function getAllowedCurrencies() public view returns(Schemas.AllowedCurrencyDTO[] memory currencies) {
        currencies = new Schemas.AllowedCurrencyDTO[](allowedCurrencyList.length + 1);
        for (uint i = 0; i < allowedCurrencyList.length; i++) {
            IERC20 tokenContract = IERC20(allowedCurrencyList[i]);
            currencies[i] = Schemas.AllowedCurrencyDTO({
                name: tokenContract.name(),
                symbol: tokenContract.symbol(),
                decimals: tokenContract.decimals(),
                tokenAddress: address(tokenContract)
            });
        }
        currencies[allowedCurrencyList.length] = Schemas.AllowedCurrencyDTO({
                name: "ETH",
                symbol: "ETH",
                decimals: 18,
                tokenAddress: address(0)
            });
    }

    function isAllowedCurrency(address currency) public view returns(bool) {
        return allowedCurrency[currency];
    }



    function swapExactInputSingle(
    address from,
    address to,
    uint128 amountIn,
    address sender
) public payable returns (uint256 amountOut) {
    require(isAllowedCurrency(to), 'Currency is not allowed');
    bool toNative = to == address(0);

    if(from == address(0)) {
        require(amountIn == msg.value, "Wrong value");
        IWETH(weth).deposit{value: msg.value}();
        from = weth;
    }
    else {
    IERC20(from).transferFrom(sender, address(this), amountIn);
    }
        if(toNative) {
        to = weth;
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

 
     if(toNative) {
     IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this)));
     (bool succes, ) = msg.sender.call{value: msg.value}(bytes(""));
     require(succes, "Fail to send eth back");
     }
     else {
        IERC20(to).transfer(msg.sender, amount);
     }
    return amount;
}

   function initialize(address _router, address _weth, address allowedToken, address _userService) public virtual initializer {
        router = ISwapRouter(_router);
        weth = _weth;
        allowedCurrency[allowedToken] = true;
        allowedCurrencyList.push(allowedToken);
        allowedCurrency[address(0)] = true;
        userService = IRentalityAccessControl(_userService);

    }
  receive() external payable {}





}