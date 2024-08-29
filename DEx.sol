// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SimpleDEX {
    address public owner;
    uint256 public feePercentage = 1; 

    struct Pool {
        uint256 tokenA;
        uint256 tokenB;
    }

    mapping(address => mapping(address => Pool)) public pools;

    event PoolCreated(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event Swap(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPool(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external onlyOwner {
        require(pools[tokenA][tokenB].tokenA == 0 && pools[tokenA][tokenB].tokenB == 0, "Pool already exists");
        require(amountA > 0 && amountB > 0, "Amounts must be greater than zero");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        pools[tokenA][tokenB] = Pool(amountA, amountB);
        emit PoolCreated(tokenA, tokenB, amountA, amountB);
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        Pool storage pool = pools[tokenA][tokenB];
        require(pool.tokenA > 0 && pool.tokenB > 0, "Pool does not exist");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        pool.tokenA += amountA;
        pool.tokenB += amountB;

        emit LiquidityAdded(tokenA, tokenB, amountA, amountB);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        Pool storage pool = pools[tokenA][tokenB];
        require(pool.tokenA >= amountA && pool.tokenB >= amountB, "Insufficient liquidity");

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        pool.tokenA -= amountA;
        pool.tokenB -= amountB;

        emit LiquidityRemoved(tokenA, tokenB, amountA, amountB);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external {
        Pool storage pool = pools[tokenIn][tokenOut];
        require(pool.tokenA > 0 && pool.tokenB > 0, "Pool does not exist");

        uint256 amountOut = getAmountOut(tokenIn, tokenOut, amountIn);
        require(amountOut > 0, "Insufficient output amount");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        pool.tokenA += amountIn;
        pool.tokenB -= amountOut;

        emit Swap(tokenIn, tokenOut, amountIn, amountOut);
    }

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
        Pool storage pool = pools[tokenIn][tokenOut];
        require(pool.tokenA > 0 && pool.tokenB > 0, "Pool does not exist");

        uint256 amountInWithFee = amountIn * (100 - feePercentage);
        uint256 numerator = amountInWithFee * pool.tokenB;
        uint256 denominator = pool.tokenA * 100;

        return numerator / denominator;
    }

    function setFee(uint256 newFee) external onlyOwner {
        feePercentage = newFee;
    }
}
