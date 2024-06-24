// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleBlockchain {

     constructor() {
       
        createBlock(0,"genesis-block");
    }


    struct Block {
        uint id;
        uint previousHash;
        uint timestamp;
        string data;
        uint hash;
    }

    Block[] public blockchain;

    function createBlock(uint previousHash, string memory data) public {
        uint id = blockchain.length;
        uint timestamp = block.timestamp;
        uint hash = uint256(keccak256(abi.encodePacked(id, previousHash, timestamp, data)));
        Block memory newBlock = Block(id, previousHash, timestamp, data, hash);
        blockchain.push(newBlock);
    }

    function getBlock(uint _index) public view returns (Block memory) {
        require(_index < blockchain.length);
        return blockchain[_index];
    }

    function getBlockchainLength() public view returns (uint) {
        return blockchain.length;
    }
}
