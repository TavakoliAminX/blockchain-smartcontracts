// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract AdvancedToken is ERC20, Ownable, Pausable, ERC20Burnable, ERC20Snapshot, Initializable, AccessControl {
    using SafeMath for uint256;
    //address public admin;
    uint public transactionFee;
    address public feeCollector;
    mapping(address => bool) private whitelist;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event FeeChanged(uint256 newFee);
    event Whitelisted(address indexed account, bool isWhitelisted);
    event FeeCollectorChanged(address indexed newCollector);

    function initialize( string memory name,  string memory symbol,  uint256 initialSupply,  uint256 fee,  address initialFeeCollector,address admin ) public initializer {
        ERC20(name, symbol);
        Ownable();
        Pausable();
        ERC20Burnable();
        ERC20Snapshot();

        _mint(msg.sender, initialSupply);
        transactionFee = fee;
        feeCollector = initialFeeCollector;

        setupRole( msg.sender);
        setup(ADMIN_ROLE , admin);
        whitelist[msg.sender] = true;
    }
    function setupRole(address account) public {
    setupRole(ADMIN_ROLE, account);
    }

    function setTransactionFee(uint256 fee) external onlyRole(ADMIN_ROLE) {
        require(fee <= 10000);
        transactionFee = fee;
        emit FeeChanged(fee);
    }

    function setFeeCollector(address newCollector) external onlyRole(ADMIN_ROLE) {
        require(newCollector != address(0));
        feeCollector = newCollector;
        emit FeeCollectorChanged(newCollector);
    }

    function addToWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        whitelist[account] = true;
        emit Whitelisted(account, true);
    }

    function removeFromWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        whitelist[account] = false;
        emit Whitelisted(account, false);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function snapshot() external onlyRole(ADMIN_ROLE) {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (whitelist[sender] || whitelist[recipient] || transactionFee == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 fee = amount.mul(transactionFee).div(10000);
            uint256 amountAfterFee = amount.sub(fee);
            super._transfer(sender, feeCollector, fee);
            super._transfer(sender, recipient, amountAfterFee);
        }
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance > 0);
        _transfer(address(this), feeCollector, balance);
    }

    
}
