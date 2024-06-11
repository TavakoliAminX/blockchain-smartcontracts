// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract SecureStore {
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

contract DiscountedPurchase {
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

contract HeadsOrTails {
    bool public chosen;
    bool public lastChoiceHead;
    address payable public lastParty;

    function choose(bool _chooseHead) public payable {
        require(!chosen);
        require(msg.value == 1 ether);

        chosen = true;
        lastChoiceHead = _chooseHead;
        lastParty = payable(msg.sender);
    }

    function guess(bool _guessHead) public payable {
        require(chosen);
        require(msg.value == 1 ether);

        if (_guessHead == lastChoiceHead) {
            payable(msg.sender).transfer(2 ether);
        } else {
            lastParty.transfer(2 ether);
        }

        chosen = false;
    }
}

contract SecureVault {
    mapping(address => uint) public balances;

    function store() public payable {
        balances[msg.sender] += msg.value;
    }

    function redeem() public {
        uint amount = balances[msg.sender];
        require(amount > 0);

        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }
}

contract HeadsTailsGame {
    address payable public partyA;
    address payable public partyB;
    bytes32 public commitmentA;
    bool public chooseHeadB;
    uint public timeB;

    constructor(bytes32 _commitmentA) payable {
        require(msg.value == 1 ether);

        commitmentA = _commitmentA;
        partyA = payable(msg.sender);
    }

    function guess(bool _chooseHead) public payable {
        require(msg.value == 1 ether);
        require(partyB == address(0));

        chooseHeadB = _chooseHead;
        timeB = block.timestamp;
        partyB = payable(msg.sender);
    }

    function resolve(bool _chooseHead, uint _randomNumber) public {
        require(msg.sender == partyA);
        require(keccak256(abi.encodePacked(_chooseHead, _randomNumber)) == commitmentA);
        require(address(this).balance >= 2 ether);

        if (_chooseHead == chooseHeadB) {
            partyB.transfer(2 ether);
        } else {
            partyA.transfer(2 ether);
        }
    }

    function timeOut() public {
        require(block.timestamp > timeB + 1 days);
        require(address(this).balance >= 2 ether);

        partyB.transfer(2 ether);
    }
}

contract SimpleToken {
    mapping(address => int) public balances;

    constructor() {
        balances[msg.sender] += 1000e18;
    }

    function sendToken(address _recipient, int _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }
}

contract BondedCurve {
    mapping(address => uint) public balances;
    uint public totalSupply;

    function buy() public payable {
        uint tokenToReceive = (1e18 * msg.value) / (1e18 + totalSupply);
        balances[msg.sender] += tokenToReceive;
        totalSupply += tokenToReceive;
    }

    function sell(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        uint ethToReceive = ((1e18 + totalSupply) * _amount) / 1e18;
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        payable(msg.sender).transfer(ethToReceive);
    }

    function sendToken(address _recipient, uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }
}

contract SecureCoffers {
    struct Coffer {
        uint nbSlots;
        mapping(uint => uint) slots;
    }
    mapping(address => Coffer) public coffers;

    function createCoffer(uint _slots) external {
        Coffer storage coffer = coffers[msg.sender];
        require(coffer.nbSlots == 0);
        coffer.nbSlots = _slots;
    }

    function deposit(uint _slot) public payable {
        Coffer storage coffer = coffers[msg.sender];
        require(_slot < coffer.nbSlots);
        coffer.slots[_slot] += msg.value;
    }

    function withdraw(uint _slot) public {
        Coffer storage coffer = coffers[msg.sender];
        require(_slot < coffer.nbSlots);
        uint amount = coffer.slots[_slot];
        coffer.slots[_slot] = 0;
        payable(msg.sender).transfer(amount);
    }

    function closeAccount() public {
        Coffer storage coffer = coffers[msg.sender];
        uint amountToSend;
        for (uint i = 0; i < coffer.nbSlots; ++i) {
            amountToSend += coffer.slots[i];
            coffer.slots[i] = 0;
        }
        coffer.nbSlots = 0;
        payable(msg.sender).transfer(amountToSend);
    }
}

contract CommonFunds {
    mapping(address => uint) public coffers;
    uint public scalingFactor;

    function deposit() public payable {
        require(msg.value > 0);
        if (scalingFactor != 0) {
            uint toAdd = (scalingFactor * msg.value) / (address(this).balance - msg.value);
            coffers[msg.sender] += toAdd;
            scalingFactor += toAdd;
        } else {
            scalingFactor = 100;
            coffers[msg.sender] = 100;
        }
    }

    function withdraw(uint _amount) public {
        require(_amount <= address(this).balance);
        uint toRemove = (scalingFactor * _amount) / address(this).balance;
        coffers[msg.sender] -= toRemove;
        scalingFactor -= toRemove;
        payable(msg.sender).transfer(_amount);
    }
}

contract DisputeResolver {
    enum Side {A, B}

    address payable public owner;
    address payable[2] public sides;

    uint256 public baseDeposit;
    uint256 public reward;
    Side public winner;
    bool public declared;

    uint256[2] public partyDeposits;

    constructor(uint256 _baseDeposit) payable {
        require(msg.value > 0);
        owner = payable(msg.sender);
        reward = msg.value;
        baseDeposit = _baseDeposit;
    }

    function deposit(Side _side) public payable {
        require(!declared);
        require(sides[uint(_side)] == address(0));
        require(msg.value >= baseDeposit);
        sides[uint(_side)] = payable(msg.sender);
        partyDeposits[uint(_side)] = msg.value;
        owner.transfer(baseDeposit);
    }

    function declareWinner(Side _winner) public {
        require(msg.sender == owner);
        require(!declared);
        declared = true;
        winner = _winner;
    }

    function payReward() public {
        require(declared);
        uint depositA = partyDeposits[0];
        uint depositB = partyDeposits[1];

        partyDeposits[0] = 0;
        partyDeposits[1] = 0;

        if (!sides[uint(winner)].send(reward)) {
            revert();
        }
        if (depositA > baseDeposit && sides[0] != address(0)) {
            if (!sides[0].send(depositA - baseDeposit)) {
                revert();
            }
        }
        if (depositB > baseDeposit && sides[1] != address(0)) {
            if (!sides[1].send(depositB - baseDeposit)) {
                revert();
            }
        }
        reward = 0;
    }
}

