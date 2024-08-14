// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


contract NFT {
    address public owner;

  struct Order {
    uint8 orderType;  
    address seller;
    address token;
    uint256 tokenId;
    uint256 startPrice;
    uint256 endPrice;
    uint256 startBlock;
    uint256 endBlock;
    uint256 lastBidPrice;
    address lastBidder;
    bool isSold;
  }

  mapping (address => mapping (uint256 => bytes32[])) public orderIdByToken;
  mapping (address => bytes32[]) public orderIdBySeller;
  mapping (bytes32 => Order) public orderInfo;

  address public feeAddress;
  uint16 public feePercent;

  event MakeOrder(address indexed token, uint256 id, bytes32 indexed hash, address seller);
  event CancelOrder(address indexed token, uint256 id, bytes32 indexed hash, address seller);
  event Bid(address indexed token, uint256 id, bytes32 indexed hash, address bidder, uint256 bidPrice);
  event Claim(address indexed token, uint256 id, bytes32 indexed hash, address seller, address taker, uint256 price);


  constructor(uint16 _feePercent) {
    require(_feePercent <= 10000);
    feeAddress = msg.sender;
    feePercent = _feePercent;
  }


  function getCurrentPrice(bytes32 _order) public view returns (uint256) {
    Order storage o = orderInfo[_order];
    uint8 orderType = o.orderType;
    if (orderType == 0) {
      return o.startPrice;
    } else if (orderType == 2) {
      uint256 lastBidPrice = o.lastBidPrice;
      return lastBidPrice == 0 ? o.startPrice : lastBidPrice;
    } else {
      uint256 _startPrice = o.startPrice;
      uint256 _startBlock = o.startBlock;
      uint256 tickPerBlock = (_startPrice - o.endPrice) / (o.endBlock - _startBlock);
      return _startPrice - ((block.number - _startBlock) * tickPerBlock);
    }
  }

  function tokenOrderLength(address _token, uint256 _id) external view returns (uint256) {
    return orderIdByToken[_token][_id].length;
  }

  function sellerOrderLength(address _seller) external view returns (uint256) {
    return orderIdBySeller[_seller].length;
  }

  function dutchAuction(address _token, uint256 _id, uint256 _startPrice, uint256 _endPrice, uint256 _endBlock) public {
    require(_startPrice > _endPrice);
    _makeOrder(1, _token, _id, _startPrice, _endPrice, _endBlock);
  } 

  function englishAuction(address _token, uint256 _id, uint256 _startPrice, uint256 _endBlock) public {
    _makeOrder(2, _token, _id, _startPrice, 0, _endBlock);
  } 

  function fixedPrice(address _token, uint256 _id, uint256 _price, uint256 _endBlock) public {
    _makeOrder(0, _token, _id, _price, 0, _endBlock);
  } 
  function _makeOrder( uint8 _orderType, address _token, uint256 _id, uint256 _startPrice, uint256 _endPrice, uint256 _endBlock ) internal {
    require(_endBlock > block.number);

    
    bytes32 hash = _hash(_token, _id, msg.sender);
    orderInfo[hash] = Order(_orderType, msg.sender, _token, _id, _startPrice, _endPrice, block.number, _endBlock, 0, address(0), false);
    orderIdByToken[_token][_id].push(hash);
    orderIdBySeller[msg.sender].push(hash);

   
    emit TransferFrom(msg.sender, address(this), _id);
    emit MakeOrder(_token, _id, hash, msg.sender);
  }
  event TransferFrom(address indexed  from , address indexed  to , uint amount);

  function _hash(address _token, uint256 _id, address _seller) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(block.number, _token, _id, _seller));
  }

  function bid(bytes32 _order) payable external {
    Order storage o = orderInfo[_order];
    uint256 endBlock = o.endBlock;
    uint256 lastBidPrice = o.lastBidPrice;
    address lastBidder = o.lastBidder;

    require(o.orderType == 2);
    require(endBlock != 0);
    require(block.number <= endBlock);
    require(o.seller != msg.sender);

    if (lastBidPrice != 0) {
      require(msg.value >= lastBidPrice + (lastBidPrice / 20)); 
    } else {
      require(msg.value >= o.startPrice && msg.value > 0);
    }

    if (block.number > endBlock - 20) { 
      o.endBlock = endBlock + 20;
    }

    o.lastBidder = msg.sender;
    o.lastBidPrice = msg.value;

    if (lastBidPrice != 0) {
      payable(lastBidder).transfer(lastBidPrice);
    }
    
    emit Bid(o.token, o.tokenId, _order, msg.sender, msg.value);
  }

  function buyItNow(bytes32 _order) payable external {
    Order storage o = orderInfo[_order];
    uint256 endBlock = o.endBlock;
    require(endBlock != 0);
    require(endBlock > block.number);
    require(o.orderType < 2);
    require(o.isSold == false);

    uint256 currentPrice = getCurrentPrice(_order);
    require(msg.value >= currentPrice);

    o.isSold = true;   

    uint256 fee = currentPrice * feePercent / 10000;
    payable(o.seller).transfer(currentPrice - fee);
    payable(feeAddress).transfer(fee);
    if (msg.value > currentPrice) {
      payable(msg.sender).transfer(msg.value - currentPrice);
    }

    emit TransferFrom(address(this), msg.sender, o.tokenId);

    emit Claim(o.token, o.tokenId, _order, o.seller, msg.sender, currentPrice);
  }

  function claim(bytes32 _order) external {
    Order storage o = orderInfo[_order];
    address seller = o.seller;
    address lastBidder = o.lastBidder;
    require(o.isSold == false);

    require(seller == msg.sender || lastBidder == msg.sender);
    require(o.orderType == 2);
    require(block.number > o.endBlock);

    address token = o.token;
    uint256 tokenId = o.tokenId;
    uint256 lastBidPrice = o.lastBidPrice;

    uint256 fee = lastBidPrice * feePercent / 10000;

    o.isSold = true;

    payable(seller).transfer(lastBidPrice - fee);
    payable(feeAddress).transfer(fee);
      emit TransferFrom(address(this), msg.sender, tokenId);  

    emit Claim(token, tokenId, _order, seller, lastBidder, lastBidPrice);
  }


  function cancelOrder(bytes32 _order) external {
    Order storage o = orderInfo[_order];
    require(o.seller == msg.sender);
    require(o.lastBidPrice == 0);
    require(o.isSold == false);

    address token = o.token;
    uint256 tokenId = o.tokenId;

    o.endBlock = 0;  

          emit TransferFrom(address(this), msg.sender, tokenId);  
    emit CancelOrder(token, tokenId, _order, msg.sender);
  }

  function setFeeAddress(address _feeAddress) external onlyOwner {
    feeAddress = _feeAddress;
  }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
  function updateFeePercent(uint16 _percent) external onlyOwner {
    require(_percent <= 10000);
    feePercent = _percent;
  }

}