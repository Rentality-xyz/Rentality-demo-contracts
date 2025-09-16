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
import './swaps/IUniswapV3Factory.sol';
import './swaps/IUniswapV3Pool.sol';
import '../libs/TickMath.sol';


   struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }


contract RentalitySwaps is Initializable, UUPSAccess {
    ISwapRouter public router;
    address public weth;
    IUniswapV3Factory public factory;
    

    mapping(address => bool) private allowedCurrency;
    address[] private allowedCurrencyList;



    function addAllowedCurrency(address currency) public {
        // require(userService.isAdmin(msg.sender), "Only Admin");
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
    address sender,
    uint128 minimumAmountOut,
    uint24 fee
) public payable returns (uint256 amountOut) {
    require(isAllowedCurrency(to), 'Currency is not allowed');
    require(address(factory) != address(0), "Swaps not alowed");
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

    address poolAddress = IUniswapV3Factory(factory).getPool(from, to, fee);

    IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
    (uint160 sqrtPriceX96,, , , , ,) = pool.slot0();
    // uint160 priceLimit = calculateAdjustedSqrtPriceX96(sqrtPriceX96, 500);
    uint160 priceLimit = 0;
    ExactInputSingleParams memory params = ExactInputSingleParams({
        tokenIn: from,
        tokenOut: to,
        fee: fee,
        recipient: address(this),
        amountIn: amountIn,
        amountOutMinimum: minimumAmountOut,
        sqrtPriceLimitX96: priceLimit
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
    uint balance = IERC20(from).balanceOf(address(this));
     if(balance > 0) {
        IERC20(to).transfer(sender, balance);
     }
    return amount;
}

   function initialize(address _router, address _weth, address allowedToken, address _userService, address _factory) public virtual initializer {
        router = ISwapRouter(_router);
        weth = _weth;
        allowedCurrency[allowedToken] = true;
        allowedCurrencyList.push(allowedToken);
        allowedCurrency[address(0)] = true;
        userService = IRentalityAccessControl(_userService);
        factory = IUniswapV3Factory(_factory);
   }
    
     function setFactory(address _factory) public {
  
        factory = IUniswapV3Factory(_factory);

    }

    function calculateAdjustedSqrtPriceX96(uint160 currentSqrtPriceX96, int24 basisPointsDelta)
    public
    pure
    returns (uint160 adjustedSqrtPriceX96)
{
    int24 currentTick = TickMath.getTickAtSqrtRatio(currentSqrtPriceX96);
    int24 adjustedTick = currentTick + basisPointsDelta;
    adjustedSqrtPriceX96 = TickMath.getSqrtRatioAtTick(adjustedTick);
}


function getPrice(address from, address to, uint24 fee)
    public
    view
    returns (uint256)
{

    if(from == address(0)) {

        from = weth;
    }
    else if (to == address(0)){
   
        to = weth;
    }

    address poolAddress = IUniswapV3Factory(factory).getPool(from, to, fee);

    IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
    (uint160 sqrtPriceX96,, , , , ,) = pool.slot0();


    uint256 numerator1 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
    uint256 numerator2 = 10**IERC20(from).decimals();
    return mulDiv(numerator1, numerator2, 1 << 192);
}
  function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly ("memory-safe") {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly ("memory-safe") {
                    result := div(prod0, denominator)
                }
                return result;
            }
        }
  }

   function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    // require(userService.isAdmin(msg.sender), 'Only for Admin.');
  }
  
  receive() external payable {}


}