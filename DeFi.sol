// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {

    address public owner;
    uint public totalLoans;
    uint public totalDeposits;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Loan(address indexed user, uint amount);
    event Repay(address indexed user, uint amount);

    mapping(address => uint) public depositBalances;
    mapping(address => uint) public loanBalances;

    constructor() {
        owner = msg.sender;      // set owner
    }
    // modifier onlyOwner(){
    //     require(owner == msg.sender);
    //     _;
    // }

    function deposit() public payable {
        require(msg.value > 0);
        depositBalances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public {
        require(depositBalances[msg.sender] >= _amount);
        depositBalances[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function requestLoan(uint _amount) public {
        require(_amount > 0);
        require(address(this).balance >= _amount);
        loanBalances[msg.sender] += _amount;
        totalLoans += _amount;
        payable(msg.sender).transfer(_amount);
        emit Loan(msg.sender, _amount);
    }

    function repayLoan() public payable {
        require(loanBalances[msg.sender] > 0);
        require(msg.value > 0);
        require(msg.value <= loanBalances[msg.sender]);
        loanBalances[msg.sender] -= msg.value;
        totalLoans -= msg.value;
        emit Repay(msg.sender, msg.value);
    }
}
