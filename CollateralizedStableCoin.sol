// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CollateralizedStableCoin {
    address public owner;
    IERC20 public collateralToken; 
    IERC20 public stableCoin;      

    uint256 public collateralRatio = 150;
    uint256 public minimumCollateral = 1000 * 1e18; 
     constructor(IERC20 _collateralToken, IERC20 _stableCoin) {
        owner = msg.sender;
        collateralToken = _collateralToken;
        stableCoin = _stableCoin;
    }
    struct Collateral {
        uint256 amount;    
        uint256 stableCoinAmount; 
    }

    mapping(address => Collateral) public collaterals;

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event StableCoinIssued(address indexed user, uint256 amount);
    event StableCoinRepaid(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyValidCollateral(uint256 amount) {
        require(amount >= minimumCollateral, "Collateral below minimum");
        _;
    }

    modifier onlyValidRepayment(uint256 amount) {
        Collateral storage collateral = collaterals[msg.sender];
        require(amount <= collateral.stableCoinAmount, "Repayment amount exceeds issued stable coins");
        _;
    }

   

    function depositCollateral(uint256 amount) external onlyValidCollateral(amount) {
        require(amount > 0, "Amount must be greater than zero");
        collateralToken.transferFrom(msg.sender, address(this), amount);
        Collateral storage collateral = collaterals[msg.sender];
        collateral.amount += amount;
        emit CollateralDeposited(msg.sender, amount);
    }

    function withdrawCollateral(uint256 amount) external onlyValidRepayment(amount) {
        Collateral storage collateral = collaterals[msg.sender];
        require(amount <= collateral.amount, "Insufficient collateral");
        collateral.amount -= amount;
        collateralToken.transfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function issueStableCoin(uint256 amount) external onlyValidCollateral(amount) {
        Collateral storage collateral = collaterals[msg.sender];
        uint256 requiredCollateral = (amount * collateralRatio) / 100;
        require(collateral.amount >= requiredCollateral, "Insufficient collateral for issuance");
        collateral.stableCoinAmount += amount;
        stableCoin.transfer(msg.sender, amount);
        emit StableCoinIssued(msg.sender, amount);
    }

    function repayStableCoin(uint256 amount) external onlyValidRepayment(amount) {
        Collateral storage collateral = collaterals[msg.sender];
        collateral.stableCoinAmount -= amount;
        stableCoin.transferFrom(msg.sender, address(this), amount);
        emit StableCoinRepaid(msg.sender, amount);
    }

    function setCollateralRatio(uint256 newRatio) external onlyOwner {
        collateralRatio = newRatio;
    }

    function setMinimumCollateral(uint256 newMinimum) external onlyOwner {
        minimumCollateral = newMinimum;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
