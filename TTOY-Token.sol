// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Counters {
    struct Counter {
        uint256 _value; 
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {


    string private  _name;
    string private  _symbol;
    uint private _totalSupply;

    mapping (address => uint) private  _balances;
    mapping (address => mapping (address => uint)) private  _allowances;

    constructor(string memory name_ , string memory symbol_ ){
        _name = name_;
        _symbol = symbol_;
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

    function decimals() public view virtual  override  returns(uint8){
        return 18;
    }

    function balanceOf(address account) public view virtual  override  returns(uint){
        return _balances[account];
    }

    function _transfer(address from , address to , uint amount) internal virtual {
        require(from != address(0));
        require(to != address(0));
        uint balancesFrom = _balances[from];
        require(balancesFrom >= amount);
        unchecked{
            _balances[from] = balancesFrom - amount;
            _balances[to] += amount;
        }
        emit Transfer(from , to , amount);
    }


    function transfer(address to , uint amount) public virtual  override  returns(bool){
        address owner = _msgSender();
        _transfer(owner , to , amount);
        return true;
    }

    function allowance(address owner , address spender) public view virtual  override  returns(uint){
        return _allowances[owner][spender];
    }

    function _approve(address owner , address spender , uint amount) internal  virtual {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner , spender , amount);
    }

    function approve(address spender , uint amount) public virtual  override  returns(bool){
        address owner = _msgSender();
        _approve(owner , spender , amount);
        return true;
    }

    function _mint(address account , uint amount) internal virtual {
        require(account != address(0));
        _totalSupply += amount;
        unchecked{
            _balances[account] += amount;
        }
        emit Transfer(address(0) , account , amount);
    }

    function _burn(address account , uint amount) internal  virtual {
        require(account != address(0));
        uint balancesAccount = _balances[account];
        require(balancesAccount >= amount);
        unchecked{
            _balances[account] = balancesAccount - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account , address(0) , amount);
    }

    function _spendAllowa(address owner , address spender , uint amount) internal  virtual {
        uint currentAllow = allowance(owner , spender);
        if(currentAllow != type(uint).max){
            require(currentAllow >= amount);
            unchecked{
                _approve(owner , spender , currentAllow - amount);
            }
        }
    }

    function transferFrom(address from , address to , uint amount) public virtual  override  returns(bool){
        address spender = _msgSender();
        _spendAllowa(from , spender , amount);
        _transfer(from , to , amount);
        return true;
    }

    function _befroTokenTransfer(address from , address to , uint amount) internal  virtual {}
    function _afterTokenTransfer(address from , address to , uint amount) internal  virtual {}

    function increasedAllowance(address spender , uint addValue) public virtual returns(bool) {
        address owner = _msgSender();
        _approve(owner , spender , allowance(owner , spender) + addValue);
        return true;
    }

    function decreasedAllowance(address spender , uint subtractedValue) public virtual  returns(bool){
        address owner = _msgSender();
        uint currentAllo = allowance(owner , spender);
        require(currentAllo >= subtractedValue);
        unchecked{
            _approve(owner , spender , currentAllo - subtractedValue);
        }
        return true;

    }

    
}


contract TTOY is ERC20, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _minted; 
    address private _lp;
    address private _weth;
    address private  _dev;
    address private _router;
    uint private  _maxMint;
    uint private  _price;


    constructor(uint price_ , uint maxMint_ , address router_ , address dev_ , address weth_)ERC20("TOKEN" , "TTOY"){
        _maxMint = maxMint_;
        _price = price_;
        _router = router_;
        _dev = dev_;
        _weth = weth_;
    }

    function mint(uint amount) external  payable {
        require(amount > 0);
        require(_minted.current() + amount <= _maxMint);
        require(msg.value == amount * _price);
        _mint(_msgSender(), amount);
        _minted.increment();

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external onlyOwner {
        require(tokenAmount > 0 && ethAmount > 0);

        IERC20(_weth).approve(_router, tokenAmount);
        
        IUniswapV2Router01(_router).addLiquidityETH{value: ethAmount}(
            address(this),   
            tokenAmount,     
            0,               
            0,               
            owner(),        
            block.timestamp  
        );
    }



    function rewardDev() external onlyOwner {
        payable(_dev).transfer(address(this).balance);
    }


    function balance() external view returns (uint256) {
        return address(this).balance;
    }


    function weth() external view returns (address) {
        return _weth;
    }


    function uniswapRouter() external view returns (address) {
        return _router;
    }


    function dev() external view returns (address) {
        return _dev;
    }

   
    function setLP(address lp_) external onlyOwner {
        _lp = lp_;
    }


}