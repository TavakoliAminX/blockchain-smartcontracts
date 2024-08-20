// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract InvestmentManager {
    
    address public owner;

    
    IERC20 public acceptedToken;

    
    constructor(IERC20 _acceptedToken) {
        owner = msg.sender; 
        acceptedToken = _acceptedToken; 
    }

    
    mapping(address => uint256) public balances;

    
    struct Investment {
        address project;  
        uint256 amount;   
        bool active;      
    }

    
    mapping(address => Investment[]) public investments;

    
    mapping(address => bool) public voters;

    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event InvestmentMade(address indexed user, address indexed project, uint256 amount);
    event InvestmentClosed(address indexed user, address indexed project, uint256 amount);
    event Voted(address indexed user, address indexed project, bool support);

    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    
    modifier onlyVoters() {
        require(voters[msg.sender], "Only voters can perform this action");
        _;
    }

    
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero"); 
        require(acceptedToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance"); 
        acceptedToken.transferFrom(msg.sender, address(this), amount); 
        balances[msg.sender] += amount; 
        emit Deposit(msg.sender, amount); 
    }

    
    function withdraw(uint256 amount) external {
        require(amount <= balances[msg.sender], "Insufficient balance"); 
        balances[msg.sender] -= amount; 
        acceptedToken.transfer(msg.sender, amount); 
        emit Withdraw(msg.sender, amount); 
    }

    
    function invest(address project, uint256 amount) external onlyVoters {
        require(amount > 0, "Investment amount must be greater than zero"); 
        require(amount <= balances[msg.sender], "Insufficient balance for investment"); 
        balances[msg.sender] -= amount; 
        investments[msg.sender].push(Investment(project, amount, true)); 
        emit InvestmentMade(msg.sender, project, amount); 
    }

    
    function closeInvestment(uint256 index) external {
        Investment storage inv = investments[msg.sender][index]; 
        require(inv.active, "Investment is not active"); 
        inv.active = false; 
        balances[msg.sender] += inv.amount; 
        emit InvestmentClosed(msg.sender, inv.project, inv.amount); 
    }

    
    function vote(address project, bool support) external onlyVoters {
        emit Voted(msg.sender, project, support); 
    }

    
    function addVoter(address voter) external onlyOwner {
        voters[voter] = true; 
    }

    
    function removeVoter(address voter) external onlyOwner {
        voters[voter] = false; 
    }

   
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner; 
    }
}
