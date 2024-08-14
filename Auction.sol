// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
contract Auction {
    
    struct Bid {
        bytes32 blindedBid; 
        uint deposit; 
    }
    mapping(address => Bid[]) public bids;
    
    
    address payable public beneficiary;
 
    uint public biddingEnd;
 
    uint public revealEnd;
    bool public ended;
    



    address public highestBidder;

    uint public highestBid;
    

    mapping(address => uint) public pendingWithdrawls;
    
    event AuctionEnded(address winner, uint highestBid);

    modifier onlyBefore(uint _time) {require(block.timestamp < _time); _;}

    modifier onlyAfter(uint _time) {require(block.timestamp > _time); _;}
    

    constructor ( uint _biddingTime, uint _revealTime, address payable _beneficiary )  {
        beneficiary =payable(_beneficiary);
        biddingEnd = block.timestamp + _biddingTime;
        revealEnd = biddingEnd + _revealTime;    
        }
        
    

    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }
    
  
    function reveal( uint[] memory _values, bool[] memory _fake, bytes32[] memory _secret )  public onlyBefore(biddingEnd) onlyAfter(revealEnd) {

            uint length = bids[msg.sender].length;
            require(_values.length == length);
            require(_fake.length == length);
            require(_secret.length == length);
            

            uint refund;
            for (uint i = 0; i < length; i++){
                Bid storage bidToCheck = bids[msg.sender][i];
                (uint value, bool fake, bytes32 secret) = (_values[i], _fake[i], _secret[i]);

                if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {

                    continue;
                }

                refund += bidToCheck.deposit;
                if (!fake && bidToCheck.deposit >= value) {
                    if (placeBid(msg.sender, value)) {
                        refund -= value;
                    }
                }

                bidToCheck.blindedBid = bytes32(0);
            }

       payable(msg.sender).transfer(refund);
        }
        

    function withdraw() public {
        uint amount = pendingWithdrawls[msg.sender];
        if (amount > 0) {
            pendingWithdrawls[msg.sender] = 0;
       }
       payable(msg.sender).transfer(amount);   
    }
    

    function auctionEnd() public onlyAfter(revealEnd) {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }

    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }
        
        if (bidder != address(0)) {
            pendingWithdrawls[highestBidder] += highestBid;
            highestBidder = bidder;
            highestBid = value;
            return true;
        }
    }
}