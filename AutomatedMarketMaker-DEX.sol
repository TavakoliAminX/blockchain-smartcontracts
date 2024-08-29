// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM {

    IERC20 public token1;
    IERC20 public token2;

    uint public reserve1; 
    uint public reserve2; 

    uint public totalLiquidity; 
    mapping(address => uint) public liquidity; 

    constructor(IERC20 _token1, IERC20 _token2) {
        token1 = _token1; 
        token2 = _token2; 
    }

    function addLiquidity(uint amount1, uint amount2) public returns (uint liquidityTokens) {
        if (totalLiquidity == 0) {
            
            reserve1 = amount1;
            reserve2 = amount2;
            totalLiquidity = amount1; 
        } else {
            
            uint amount2Optimal = (amount1 * reserve2) / reserve1;
            require(amount2 >= amount2Optimal, "Insufficient token2 amount");

           
            reserve1 += amount1;
            reserve2 += amount2Optimal;

            
            liquidityTokens = (amount1 * totalLiquidity) / reserve1;
            totalLiquidity += liquidityTokens; 
        }

        
        liquidity[msg.sender] += liquidityTokens;

        
        token1.transferFrom(msg.sender, address(this), amount1);
        token2.transferFrom(msg.sender, address(this), amount2);
    }

    function swap(uint amountIn, bool isToken1ToToken2) public returns (uint amountOut) {
        if (isToken1ToToken2) {
            
            uint amountInWithFee = amountIn * 997 / 1000; 
            
            amountOut = reserve2 - ((reserve1 * reserve2) / (reserve1 + amountInWithFee));
            reserve1 += amountIn; 
            reserve2 -= amountOut; 

            token1.transferFrom(msg.sender, address(this), amountIn);
            token2.transfer(msg.sender, amountOut);
        } else {
          
            uint amountInWithFee = amountIn * 997 / 1000; 
            
            amountOut = reserve1 - ((reserve1 * reserve2) / (reserve2 + amountInWithFee));
            reserve2 += amountIn; 
            reserve1 -= amountOut; 

            token2.transferFrom(msg.sender, address(this), amountIn);
            token1.transfer(msg.sender, amountOut);
        }
    }

    function removeLiquidity(uint liquidityTokens) public returns (uint amount1, uint amount2) {
        require(liquidity[msg.sender] >= liquidityTokens, "Insufficient liquidity");

        amount1 = (liquidityTokens * reserve1) / totalLiquidity;
        amount2 = (liquidityTokens * reserve2) / totalLiquidity;

        reserve1 -= amount1;
        reserve2 -= amount2;
        totalLiquidity -= liquidityTokens;
        liquidity[msg.sender] -= liquidityTokens;

        token1.transfer(msg.sender, amount1);
        token2.transfer(msg.sender, amount2);
    }
}
