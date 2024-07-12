// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeFiProtocol {

    address public owner;
    uint public totalDeposits;
    uint public totalLoans;
    uint public totalInterest;
    

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event LoanTaken(address indexed user, uint amount, uint interestRate);
    event LoanRepaid(address indexed user, uint amount);
    constructor(address _owner){
        owner = _owner;
    }
    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    struct Deposit {
        uint amount;
        uint depositTime;
    }
    mapping(address => Deposit) public deposits;
   
    struct Loan {
        uint amount;
        uint interestRate;
        uint loanTime;
        bool repaid;
    }

    mapping(address => Loan) public loans;

   
    function deposit() external payable {
        require(msg.value > 0);
        
        Deposit storage userDeposit = deposits[msg.sender];
        userDeposit.amount += msg.value;
        userDeposit.depositTime = block.timestamp;

        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.amount >= _amount);

        uint interest = calculateInterest(userDeposit.amount, userDeposit.depositTime);
        userDeposit.amount -= _amount;

        totalDeposits -= _amount;
        totalInterest += interest;

        payable(msg.sender).transfer(_amount + interest);

        emit Withdrawn(msg.sender, _amount);
    }

 
    function calculateInterest(uint amount, uint depositTime) internal  returns (uint){
        uint timeElapsed = block.timestamp - _depositTime; 

        uint interestRatePerSecond =  0.0001 ether; 

        return (amount , interestRatePerSecond , timeElapsed) / 1 ether;
    }

   

    function takeLoan(uint _amount) external {
        require(_amount > 0);
        require(_amount <= totalDeposits / 2);

        Loan storage userLoan = loans[msg.sender];
        require(userLoan.amount == 0);

        uint interestRate = 0.05 ether; 
        userLoan.amount = _amount;
        userLoan.interestRate = interestRate;
        userLoan.loanTime = block.timestamp;
        userLoan.repaid = false;

        totalLoans += _amount;

        payable(msg.sender).transfer(_amount);

        emit LoanTaken(msg.sender, _amount, interestRate);
    }

    function repayLoan() external payable {
        Loan storage userLoan = loans[msg.sender];
        require(userLoan.amount > 0);

        uint timeElapsed = block.timestamp - userLoan.loanTime;
        uint interest = (userLoan.amount * userLoan.interestRate , timeElapsed) / 1 ether;
        uint totalRepayment = userLoan.amount + interest;

        require(msg.value >= totalRepayment);

        userLoan.repaid = true;
        totalLoans -= userLoan.amount;
        totalInterest += interest;

        if (msg.value > totalRepayment) {
            payable(msg.sender).transfer(msg.value - totalRepayment); 
        }

        emit LoanRepaid(msg.sender, userLoan.amount);
    }
    function calculateInterest(uint amount, uint depositTime) internal view returns (uint) {
    uint timeElapsed = block.timestamp - depositTime;
    uint interestRatePerSecond = 0.0001 ether; 
    return (amount, interestRatePerSecond * timeElapsed) / 1 ether;
    }

    function getDepositInfo(address _user) external view returns (uint, uint) {
        Deposit storage userDeposit = deposits[_user];
        return (userDeposit.amount, userDeposit.depositTime);
    }

    function getLoanInfo(address _user) external view returns (uint, uint, uint, bool) {
        Loan storage userLoan = loans[_user];
        return (userLoan.amount, userLoan.interestRate, userLoan.loanTime, userLoan.repaid);
    }

    function getTotalInterest() external view returns (uint) {
        return totalInterest;
    }

    function getTotalDeposits() external view returns (uint) {
        return totalDeposits;
    }

    function getTotalLoans() external view returns (uint) {
        return totalLoans;
    }
}
