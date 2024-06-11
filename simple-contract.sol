// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Simple {
    mapping(address => uint) public balances;

    function buyToken() public payable {
        balances[msg.sender] += msg.value / 1 ether;
    }
    
    function sendToken(address _recipient, uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }
}

pragma solidity 0.8.20;

contract Vote {
    mapping(address => uint) public votingRights;
    mapping(address => uint) public votesCast;
    mapping(bytes32 => uint) public votesReceived;

    function buyVotingRights() public payable {
        votingRights[msg.sender] += msg.value / (1 ether);
    }
    
    function vote(uint _nbVotes, bytes32 _proposition) public {
        require(_nbVotes + votesCast[msg.sender] <= votingRights[msg.sender]);
        votesCast[msg.sender] += _nbVotes;
        votesReceived[_proposition] += _nbVotes;
    }
}

pragma solidity 0.8.20;

contract Buy {
    mapping(address => uint) public balances;
    uint public price = 1;
    address public owner = msg.sender;

    function buyToken(uint _amount, uint _price) public payable {
        require(_price >= price);
        require(_price * _amount * 1 ether <= msg.value);
        balances[msg.sender] += _amount;
    }
    
    function setPrice(uint _price) public {
        require(msg.sender == owner);
        price = _price;
    }
}

pragma solidity 0.8.20;

contract Storecontract {
    struct Safe {
        address owner;
        uint amount;
    }
    
    Safe[] public safes;

    function store() public payable {
        safes.push(Safe({owner: msg.sender, amount: msg.value}));
    }
    
    function take() public {
        for (uint i; i < safes.length; ++i) {
            Safe storage safe = safes[i];
            if (safe.owner == msg.sender && safe.amount != 0) {
                payable(msg.sender).transfer(safe.amount);
                safe.amount = 0;
            }
        }
    }
}

pragma solidity 0.8.20;

contract Count {
    mapping(address => uint) public contribution;
    uint public totalContributions;
    address owner = msg.sender;

    function CountContribution() public {
        recordContribution(owner, 1 ether);
    }
    
    function contribute() public payable {
        recordContribution(msg.sender, msg.value);
    }
    
    function recordContribution(address _user, uint _amount) internal {
        contribution[_user] += _amount;
        totalContributions += _amount;
    }
}

pragma solidity 0.8.20;

contract token {
    mapping(address => uint) public balances;

    function buyToken() public payable {
        balances[msg.sender] += msg.value / 1 ether;
    }
    
    function sendToken(address _recipient, uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }
    
    function sendAllTokens(address _recipient) public {
        balances[_recipient] += balances[msg.sender];
        balances[msg.sender] = 0;
    }
}

pragma solidity 0.8.20;

contract discount {
    uint public basePrice = 1 ether;
    mapping(address => uint) public objectBought;

    function buy() public payable {
        require(msg.value * (1 + objectBought[msg.sender]) == basePrice);
        objectBought[msg.sender] += 1;
    }
    
    function price() public view returns (uint) {
        return basePrice / (1 + objectBought[msg.sender]);
    }
}

pragma solidity 0.8.20;

contract Tail {
    bool public chosen;
    bool public lastChoiceHead;
    address public lastParty;

    function choose(bool _chooseHead) public payable {
        require(!chosen);
        require(msg.value == 1 ether);

        chosen = true;
        lastChoiceHead = _chooseHead;
        lastParty = msg.sender;
    }
    
    function guess(bool _guessHead) public payable {
        require(chosen);
        require(msg.value == 1 ether);

        if (_guessHead == lastChoiceHead)
            payable(msg.sender).transfer(2 ether);
        else
            payable(lastParty).transfer(2 ether);

        chosen = false;
    }
}

pragma solidity 0.8.20;

contract Vault {
    mapping(address => uint) public balances;

    function store() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function redeem() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}

pragma solidity 0.8.20;

contract Head {
    address public partyA;
    address public partyB;
    bytes32 public commitmentA;
    bool public chooseHeadB;
    uint public timeB;

    function HeadTail(bytes32 _commitmentA) public payable {
        require(msg.value == 1 ether);

        commitmentA = _commitmentA;
        partyA = msg.sender;
    }
    
    function guess(bool _chooseHead) public payable {
        require(msg.value == 1 ether);
        require(partyB == address(0));

        chooseHeadB = _chooseHead;
        timeB = block.timestamp;
        partyB = msg.sender;
    }
    
    function resolve(bool _chooseHead, uint _randomNumber) public {
        require(msg.sender == partyA);
        require(keccak256(abi.encodePacked(_chooseHead, _randomNumber)) == commitmentA);
        require(address(this).balance >= 2 ether);

        if (_chooseHead == chooseHeadB)
            payable(partyB).transfer(2 ether);
        else
            payable(partyA).transfer(2 ether);
    }
    
    function timeOut() public {
        require(block.timestamp > timeB + 1 days);
        require(address(this).balance >= 2 ether);
        payable(partyB).transfer(2 ether);
    }
}

pragma solidity 0.8.20;

contract Coffer {
    struct CofferStruct { 
        address owner; 
        uint[] slots; 
    }
    CofferStruct[] public coffers;

    function createCoffer(uint _slots) external {
        CofferStruct storage coffer = coffers.push();
        coffer.owner = msg.sender;
        coffer.slots = new uint[](_slots);
    }
    
    function deposit(uint _coffer, uint _slot) external payable {
        CofferStruct storage coffer = coffers[_coffer];
        coffer.slots[_slot] += msg.value;
    }
    
    function withdraw(uint _coffer, uint _slot) external {
        CofferStruct storage coffer = coffers[_coffer];
        require(coffer.owner == msg.sender);
        uint amount = coffer.slots[_slot];
        coffer.slots[_slot] = 0;
        payable(msg.sender).transfer(amount);
    }
}









