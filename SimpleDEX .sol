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

contract SimpleDEX {
    IERC20 public token1;
    IERC20 public token2;

    uint256 public rate;

    constructor(IERC20 _token1, IERC20 _token2, uint256 _rate) {
        token1 = _token1;
        token2 = _token2;
        rate = _rate;
    }

    function swapToken2ForToken1(uint256 _amount) public {
        require(token2.transferFrom(msg.sender, address(this), _amount));
        uint256 token1Amount = _amount / rate;
        require(token1.transfer(msg.sender, token1Amount));
    }

    function swapToken1ForToken2(uint256 _amount) public {
        require(token1.transferFrom(msg.sender, address(this), _amount));
        uint256 token2Amount = _amount * rate;
        require(token2.transfer(msg.sender, token2Amount));
    }

    
}
