// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AdvancedProDEX {
    IERC20 public token1;
    IERC20 public token2;

    uint256 public reserve1;
    uint256 public reserve2;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    uint256 public constant FEE_RATE = 3; // 0.3% fee
    uint256 public constant FEE_DENOMINATOR = 1000;

    address public admin;
    address public feeRecipient;

    event AddLiquidity(address indexed provider, uint256 amount1, uint256 amount2);
    event RemoveLiquidity(address indexed provider, uint256 amount1, uint256 amount2);
    event Swap(address indexed trader, uint256 amountIn, uint256 amountOut, address indexed tokenIn, address indexed tokenOut);
    event FeeChanged(uint256 newFeeRate, address newFeeRecipient);
    event AdminChanged(address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(IERC20 _token1, IERC20 _token2, address _admin, address _feeRecipient) {
        token1 = _token1;
        token2 = _token2;
        admin = _admin;
        feeRecipient = _feeRecipient;
    }

    function addLiquidity(uint256 _amount1, uint256 _amount2) public returns (uint256) {
        require(token1.transferFrom(msg.sender, address(this), _amount1));
        require(token2.transferFrom(msg.sender, address(this), _amount2));

        uint256 liquidityMinted = totalLiquidity == 0 ? sqrt(_amount1 * _amount2) : min((_amount1 * totalLiquidity) / reserve1, (_amount2 * totalLiquidity) / reserve2);
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        reserve1 += _amount1;
        reserve2 += _amount2;

        emit AddLiquidity(msg.sender, _amount1, _amount2);
        return liquidityMinted;
    }

    function removeLiquidity(uint256 _liquidity) public returns (uint256 amount1, uint256 amount2) {
        require(liquidity[msg.sender] >= _liquidity);

        amount1 = (_liquidity * reserve1) / totalLiquidity;
        amount2 = (_liquidity * reserve2) / totalLiquidity;

        liquidity[msg.sender] -= _liquidity;
        totalLiquidity -= _liquidity;

        reserve1 -= amount1;
        reserve2 -= amount2;

        require(token1.transfer(msg.sender, amount1));
        require(token2.transfer(msg.sender, amount2));

        emit RemoveLiquidity(msg.sender, amount1, amount2);
        return (amount1, amount2);
    }

    function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) public pure returns (uint256) {
        uint256 amountInWithFee = _amountIn * (FEE_DENOMINATOR - FEE_RATE);
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        return numerator / denominator;
    }

    function swapToken1ForToken2(uint256 _amount1In) public {
        uint256 amount2Out = getAmountOut(_amount1In, reserve1, reserve2);
        require(token1.transferFrom(msg.sender, address(this), _amount1In));
        require(token2.transfer(msg.sender, amount2Out));

        uint256 fee = (_amount1In * FEE_RATE) / FEE_DENOMINATOR;
        require(token1.transfer(feeRecipient, fee));

        reserve1 += (_amount1In - fee);
        reserve2 -= amount2Out;

        emit Swap(msg.sender, _amount1In, amount2Out, address(token1), address(token2));
    }

    function swapToken2ForToken1(uint256 _amount2In) public {
        uint256 amount1Out = getAmountOut(_amount2In, reserve2, reserve1);
        require(token2.transferFrom(msg.sender, address(this), _amount2In));
        require(token1.transfer(msg.sender, amount1Out));

        uint256 fee = (_amount2In * FEE_RATE) / FEE_DENOMINATOR;
        require(token2.transfer(feeRecipient, fee));

        reserve2 += (_amount2In - fee);
        reserve1 -= amount1Out;

        emit Swap(msg.sender, _amount2In, amount1Out, address(token2), address(token1));
    }

    function setFee(uint256 newFeeRate, address newFeeRecipient) public onlyAdmin {
        require(newFeeRate <= 10);
        FEE_RATE = newFeeRate;
        feeRecipient = newFeeRecipient;
        emit FeeChanged(newFeeRate, newFeeRecipient);
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }
}
