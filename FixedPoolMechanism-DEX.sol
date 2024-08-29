// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract FixedPoolAMM {
    IERC20 public token1;
    IERC20 public token2;
    uint public constant RATE = 1000; 

    uint public reserve1;
    uint public reserve2;

    event LiquidityAdded(address indexed provider, uint amount1, uint amount2);
    event LiquidityRemoved(address indexed provider, uint amount1, uint amount2);
    event Swapped(address indexed user, bool isToken1ToToken2, uint amountIn, uint amountOut);

    constructor(IERC20 _token1, IERC20 _token2) {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(uint amount1, uint amount2) public {
        require(amount1 > 0 && amount2 > 0, "Invalid amounts");
        
        require(token1.transferFrom(msg.sender, address(this), amount1), "Token1 transfer failed");
        require(token2.transferFrom(msg.sender, address(this), amount2), "Token2 transfer failed");

        reserve1 += amount1;
        reserve2 += amount2;

        emit LiquidityAdded(msg.sender, amount1, amount2);
    }

    function removeLiquidity(uint amount1, uint amount2) public {
        require(amount1 <= reserve1 && amount2 <= reserve2, "Insufficient liquidity");

        require(token1.transfer(msg.sender, amount1), "Token1 transfer failed");
        require(token2.transfer(msg.sender, amount2), "Token2 transfer failed");

        reserve1 -= amount1;
        reserve2 -= amount2;

        emit LiquidityRemoved(msg.sender, amount1, amount2);
    }

    function swap(uint amountIn, bool isToken1ToToken2) public {
        require(amountIn > 0, "Invalid amount");
        uint amountOut;

        if (isToken1ToToken2) {
            amountOut = (amountIn * RATE) / 1000;
            require(reserve2 >= amountOut, "Insufficient liquidity");

            require(token1.transferFrom(msg.sender, address(this), amountIn), "Token1 transfer failed");
            require(token2.transfer(msg.sender, amountOut), "Token2 transfer failed");

            reserve1 += amountIn;
            reserve2 -= amountOut;
        } else {
            amountOut = (amountIn * 1000) / RATE;
            require(reserve1 >= amountOut, "Insufficient liquidity");

            require(token2.transferFrom(msg.sender, address(this), amountIn), "Token2 transfer failed");
            require(token1.transfer(msg.sender, amountOut), "Token1 transfer failed");

            reserve2 += amountIn;
            reserve1 -= amountOut;
        }

        emit Swapped(msg.sender, isToken1ToToken2, amountIn, amountOut);
    }
}
