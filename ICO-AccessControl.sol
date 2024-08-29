// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ICO is AccessControl {
    using SafeMath for uint256;

    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    
    IERC20 public token;
    uint256 public tokenPrice = 10**15 wei; 
    uint256 public airdropAmount = 100 * 1e18;
    uint256 public maxAirdropAmount = 1_000_000 * 1e18;
    uint256 public totalReleasedAmount;
    uint256 public holdersCount;
    uint256 public icoEndTime;

    
    mapping (address => uint256) public airdrops;
    mapping (address => uint256) public holders;
    mapping (address => bool) public isInList;
    mapping (address => bool) public kycCompleted; 

    
    event Buy(address indexed buyer, uint256 amount);
    event Airdrop(address indexed receiver, uint256 amount);
    event TokenPriceUpdated(uint256 newPrice);
    event KYCCompleted(address indexed user);

    
    constructor(address _admin, address _token) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);  
        _grantRole(ADMIN_ROLE, _admin);  
        token = IERC20(_token);
    }

    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier isActive() {
        require(icoEndTime > 0 && block.timestamp <= icoEndTime, "ICO is not active");
        _;
    }

    modifier isInActive() {
        require(icoEndTime == 0, "ICO is already active");
        _;
    }

    
    function activate(uint256 duration) external onlyAdmin isInActive {
        icoEndTime = block.timestamp + duration;
    }
    function Inactivate() external onlyAdmin  {
        icoEndTime = 0;
    }

    
    function airdrop(address receiver) external isActive {
        require(airdrops[receiver] == 0, "Already received airdrop");
        require(totalReleasedAmount.add(airdropAmount) <= maxAirdropAmount, "Exceeds max airdrop limit");
        require(token.balanceOf(address(this)) >= airdropAmount, "Not enough tokens for airdrop");

        token.transfer(receiver, airdropAmount);
        airdrops[receiver] = airdropAmount;
        totalReleasedAmount = totalReleasedAmount.add(airdropAmount);

        if (!isInList[receiver]) {
            isInList[receiver] = true;
            holdersCount++;
        }

        holders[receiver] = holders[receiver].add(airdropAmount);
        emit Airdrop(receiver, airdropAmount);
    }

    
    function purchase(uint256 amount) external payable isActive {
        require(kycCompleted[msg.sender], "KYC not completed");
        require(msg.value == (amount.div(1e18)).mul(tokenPrice), "Incorrect ETH amount sent");
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens in contract");

        token.transfer(msg.sender, amount);

        if (!isInList[msg.sender]) {
            isInList[msg.sender] = true;
            holdersCount++;
        }

        holders[msg.sender] = holders[msg.sender].add(amount);
        emit Buy(msg.sender, amount);
    }

    
    function depositToken(uint256 amount) external onlyAdmin {
        token.transferFrom(msg.sender, address(this), amount);
    }

    
    function withdrawToken(uint256 amount) external onlyAdmin {
        require(amount <= token.balanceOf(address(this)), "Insufficient token balance");
        token.transfer(msg.sender, amount);
    }

    
    function withdrawETH(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "Insufficient ETH balance");
        payable(msg.sender).transfer(amount);
    }

    
    function balanceOfToken(address account) public view returns (uint256) {
        return token.balanceOf(account);
    }

    function balanceETH(address account) public view returns (uint256) {
        return account.balance;
    }

    function getICOAddress() public view returns (address) {
        return address(this);
    }

    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    
    function setTokenPrice(uint256 newPrice) external onlyAdmin {
        tokenPrice = newPrice;
        emit TokenPriceUpdated(newPrice);
    }

    
    function completeKYC(address user) external onlyAdmin {
        kycCompleted[user] = true;
        emit KYCCompleted(user);
    }

    
    function updateAdmin(address newAdmin) external onlyAdmin {
        grantRole(ADMIN_ROLE, newAdmin);
        revokeRole(ADMIN_ROLE, msg.sender);
    }
}
