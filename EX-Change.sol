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


contract MyToken is IERC20 {
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0));
        require(_balances[msg.sender] >= amount);

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0));

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0));
        require(recipient != address(0));
        require(_balances[sender] >= amount);
        require(_allowances[sender][msg.sender] >= amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}

contract TokenExchange {
    IERC20 public token;
    uint256 public rate; 

    event BoughtTokens(address indexed buyer, uint256 amount);
    event SoldTokens(address indexed seller, uint256 amount);

    constructor(IERC20 _token, uint256 _rate) {
        token = _token;
        rate = _rate;
    }

    function buyTokens() public payable {
        uint256 tokenAmount = msg.value * rate;
        require(token.balanceOf(address(this)) >= tokenAmount);
        token.transfer(msg.sender, tokenAmount);
        emit BoughtTokens(msg.sender, tokenAmount);
    }

    function sellTokens(uint256 tokenAmount) public {
        require(token.balanceOf(msg.sender) >= tokenAmount);
        uint256 etherAmount = tokenAmount / rate;
        require(address(this).balance >= etherAmount);

        token.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(etherAmount);
        emit SoldTokens(msg.sender, tokenAmount);
    }


    function withdraw(uint256 amount) public {
        require(address(this).balance >= amount);
        payable(msg.sender).transfer(amount);
    }

    function withdrawTokens(uint256 tokenAmount) public {
        require(token.balanceOf(address(this)) >= tokenAmount);
        token.transfer(msg.sender, tokenAmount);
    }

    receive() external payable {}
}
