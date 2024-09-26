// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;
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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context , IERC20 , IERC20Metadata{

    uint private  _totalSupply;
    uint private  _decimals;
    string private  _name;
    string private _symbol;

    mapping (address => uint) private  _balances;
    mapping (address => mapping (address => uint)) private  _allowances;

    constructor( string memory name_ , string memory symbol_ , uint inisialBalance_ ,  uint decimals_ ,address tokenOwner){
        _name = name_;
        _symbol = symbol_;
        _totalSupply = inisialBalance_ * 10** decimals_;
        _decimals = _decimals;
        _balances[tokenOwner] = _totalSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }

    function name() public view virtual  override  returns(string memory){
        return _name;
    }

    function symbol() public view virtual  override  returns(string memory){
        return _symbol;
    }

    function totalSupply() public view virtual  override  returns(uint){
        return _totalSupply;
    }

    function decimals() public view virtual  override  returns(uint){
        return _decimals;
    }

    function balanceOf(address account) public view virtual  override  returns(uint){
        return _balances[account];
    }

    function _transfer(address sender , address recipient , uint amount) internal  virtual {
        require(sender != address(0));
        require(recipient != address(0));
        uint balanceSender = _balances[sender];
        require(balanceSender >= amount);
        _balances[sender] = balanceSender - amount;
        _balances[recipient] += amount;
        emit Transfer(sender,recipient, amount);
    }

    function transfer(address recipient , uint amount) public virtual  override  returns(bool){
        address sender = _msgSender();
        _transfer(sender , recipient , amount);
        return true;
    }

    function allowance(address owner , address spender) public view virtual  override  returns(uint){
        return _allowances[owner][spender];
    }

    function _approve(address owner , address spender , uint amount) internal  virtual {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender ,uint amount) public virtual  override  returns(bool){
        address owner = _msgSender();
        _approve(owner , spender , amount);
        return true;
    }

    function transferFrom(address sender ,address recipient , uint amount) public virtual  override  returns(bool){
        address owner = _msgSender();
        _transfer(sender , recipient , amount);
        uint currentAllow = _allowances[sender][owner];
        require(currentAllow >= amount);
        _approve(sender , owner , currentAllow - amount);
        return true;
    }

    function increasedAllow(address spender , uint addValue) public virtual  returns(bool){
        address owner = _msgSender();
        _approve(owner , spender , allowance(owner , spender) + addValue);
        return true;
    }

    function dcearesedAllow(address spender , uint subtractedValue) public virtual  returns(bool){
        address owner = _msgSender();
        uint currentAllowance = allowance(owner , spender);
        require(currentAllowance >= subtractedValue);
        _approve(owner , spender ,currentAllowance - subtractedValue);
        return true;
    }

}

contract SWToken is ERC20{
   constructor(string memory name_ , string memory symbol_ , uint inisialBalance_ , uint decimals_ , address tokenOwner_ , address payable  receiver_)payable ERC20(name_ , symbol_ , inisialBalance_ , decimals_ , tokenOwner_){
    payable (receiver_).transfer(msg.value);
   }
}
