// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool); 

    function approve(address spender, uint256 value) external returns (bool); 

    function transferFrom(address from, address to, uint256 value) external returns (bool); 

    function totalSupply() external view returns (uint256); 

    function balanceOf(address who) external view returns (uint256); 

    function allowance(address owner, address spender) external view returns (uint256); 
    event Transfer(address indexed from, address indexed to, uint256 value); 

    event Approval(address indexed owner, address indexed spender, uint256 value); 



}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); 
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a); 
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a); 
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0); 
        return a % b;
    }
}


contract ERC20 is IERC20{
    using  SafeMath for uint;

    mapping (address => uint) private  _balances;
    mapping (address => mapping (address => uint)) private  _allowances;

    uint private  _totalSupply;

    function totalSupply() public view returns(uint){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint){
        return _balances[account];
    }

    function allowance(address owner , address spender) public view returns(uint){
        return _allowances[owner][spender];
    }

    function _approve(address owner ,address spender , uint amount) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender , uint amount) public returns(bool){
        _approve(msg.sender , spender , amount);
        return true;
    }

    function _transfer(address from , address to , uint amount) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function transfer(address to , uint amount) public returns(bool){
        _transfer(msg.sender , to , amount);
        return true;
    }

    function transferFrom(address from , address to , uint amount) public returns(bool){
        _transfer(from , to , amount);
        _approve(from , msg.sender , _allowances[from][msg.sender].sub(amount));
        return true;
    }

    function increasedAllow(address spender , uint addValue) public returns(bool){
        _approve(msg.sender ,spender , _allowances[msg.sender][spender].add(addValue));
        return true;
    }

    function decreasedAllow(address spender , uint subtractedValue) public returns(bool){
        _approve(msg.sender , spender , _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _mint(address account , uint amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account , uint amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account , uint amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }




}


abstract contract Detailed is IERC20{
    string private  _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_ , string memory symbol_ , uint8 decimals_){
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol()public view returns(string memory){
        return _symbol;
    }

    function decimals() public view returns(uint8){
        return _decimals;
    }

}

contract burnable is ERC20{
    function burn(uint amount)public {
        _burn(msg.sender , amount);
    }

    function burnFrom(address from , uint amount) public {
        _burnFrom(from , amount);
    }
}

contract WWT is ERC20 , burnable , Detailed{
    constructor()Detailed("WWT" , "Token" , 18){
        _mint(msg.sender ,240_000_000 * 10 ** 18);
    }
}
