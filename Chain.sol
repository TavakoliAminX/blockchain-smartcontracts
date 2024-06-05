// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
contract Ownable {
    address private origOwner;


    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    constructor() {
        origOwner = msg.sender;
        emit TransferOwnership(address(0), origOwner);
    }

    function ownerLookup() public view returns(address) {
        return origOwner;
    }

    modifier virtual onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == origOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit TransferOwnership(origOwner, address(0));
        origOwner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit TransferOwnership(origOwner, newOwner);
        origOwner = newOwner;
    }
}










pragma solidity 0.8.20;

contract SellerRole {
    using Roles for Roles.Role;

    event SellerAdded(address indexed account);
    event SellerRemoved(address indexed account);

    Roles.Role private sellers;

    constructor() {
        _addSeller(msg.sender);
    }

    modifier virtual onlySeller() {
        require(isSeller(msg.sender));
        _;
    }

    function isSeller(address account) public view returns (bool) {
        return sellers.has(account);
    }

    function addSeller(address account) public onlySeller {
        _addSeller(account);
    }

    function renounceSeller() public {
        _removeSeller(msg.sender);
    }

    function _addSeller(address account) internal {
        sellers.add(account);
        emit SellerAdded(account);
    }

    function _removeSeller(address account) internal {
        sellers.remove(account);
        emit SellerRemoved(account);
    }
}








pragma solidity 0.8.20;

contract TransporterRole {
    using Roles for Roles.Role;

    event TransporterAdded(address indexed account);
    event TransporterRemoved(address indexed account);

    Roles.Role private transporters;

    constructor() {
        _addTransporter(msg.sender);
    }

    modifier virtual onlyTransporter() {
        require(isTransporter(msg.sender));
        _;
    }

    function isTransporter(address account) public view returns (bool) {
        return transporters.has(account);
    }

    function addTransporter(address account) public onlyTransporter {
        _addTransporter(account);
    }

    function renounceTransporter() public {
        _removeTransporter(msg.sender);
    }

    function _addTransporter(address account) internal {
        transporters.add(account);
        emit TransporterAdded(account);
    }

    function _removeTransporter(address account) internal {
        transporters.remove(account);
        emit TransporterRemoved(account);
    }
}











pragma solidity ^0.8.20;

contract ConsumerRole {
    using Roles for Roles.Role;

    event ConsumerAdded(address indexed account);
    event ConsumerRemoved(address indexed account);

    Roles.Role private consumers;

    constructor() {
        _addConsumer(msg.sender);
    }

    modifier virtual onlyConsumer() {
        require(isConsumer(msg.sender));
        _;
    }

    function isConsumer(address account) public view returns (bool) {
        return consumers.has(account);
    }

    function addConsumer(address account) public onlyConsumer {
        _addConsumer(account);
    }

    function renounceConsumer() public {
        _removeConsumer(msg.sender);
    }

    function _addConsumer(address account) internal {
        consumers.add(account);
        emit ConsumerAdded(account);
    }

    function _removeConsumer(address account) internal {
        consumers.remove(account);
        emit ConsumerRemoved(account);
    }
}












pragma solidity 0.8.20;

contract Chain is Ownable, SellerRole, TransporterRole, ConsumerRole {

    uint upc;
    uint sku;

    mapping(uint => Item) items;
    mapping(uint => string[]) itemsHistory;

    enum State {
        Printed, 
        Purchased, 
        Shipped, 
        Received 
    }

    State constant defaultState = State.Printed;

    struct Item {
        uint sku; 
        uint upc; 
        address originSellerID; 
        string originSellerName; 
        uint productID; 
        string productNotes; 
        uint productPrice; 
        State itemState; 
        address transporterID; 
        address payable consumerID; 
    }

    event Printed(uint upc);
    event Purchased(uint upc);
    event Shipped(uint upc);
    event Received(uint upc);

    modifier onlyOwner() override(Ownable) {
        require(msg.sender == ownerLookup());
        _;
    }

    modifier verifySeller(uint _upc) override(SellerRole) {
        require(msg.sender == items[_upc].originSellerID);
        _;
    }

    modifier verifyConsumer(uint _upc) override(ConsumerRole) {
        require(msg.sender == items[_upc].consumerID);
        _;
    }

    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;
        payable(msg.sender).transfer(amountToReturn);
    }

    modifier printed(uint _upc) {
        require(items[_upc].itemState == State.Printed);
        _;
    }

    modifier purchased(uint _upc) {
        require(items[_upc].itemState == State.Purchased);
        _;
    }

    modifier shipped(uint _upc) {
        require(items[_upc].itemState == State.Shipped);
        _;
    }

    modifier received(uint _upc) {
        require(items[_upc].itemState == State.Received);
        _;
    }

    constructor() payable {
        owner = msg.sender;
        sku = 1;
        upc = 1;
    }

    function kill() public {
        if (msg.sender == ownerLookup()) {
            address payable ownerAddressPayable = _make_payable(ownerLookup());
            selfdestruct(ownerAddressPayable);
        }
    }

    function _make_payable(address x) internal pure returns(address payable) {
        return payable(x);
    }

    function printItem(uint _upc, string memory _originSellerName, string memory _productNotes, uint _price) public onlySeller {
        items[_upc] = Item({
            sku: sku,
            upc: _upc,
            originSellerID: msg.sender,
            originSellerName: _originSellerName,
            productID: sku + _upc,
            productNotes: _productNotes,
            productPrice: _price,
            itemState: State.Printed,
            transporterID: address(0),
            consumerID: payable(address(0))
        });
        sku = sku + 1;
        emit Printed(_upc);
    }

    function purchaseItem(uint _upc) public payable printed(_upc) paidEnough(items[_upc].productPrice) checkValue(_upc) {
        items[_upc].consumerID = payable(msg.sender);
        items[_upc].itemState = State.Purchased;
        emit Purchased(_upc);
    }

    function shipItem(uint _upc) public printed(_upc) onlyTransporter {
        items[_upc].itemState = State.Shipped;
        emit Shipped(_upc);
    }

    function receiveItem(uint _upc) public purchased(_upc) verifyConsumer(_upc) {
        items[_upc].itemState = State.Received;
        emit Received(_upc);
    }

    function fetchItem(uint _upc) public view returns (
        uint itemSKU,
        uint itemUPC,
        address ownerID,
        address originSellerID,
        string memory originSellerName,
        uint productID,
        string memory productNotes,
        uint productPrice,
        State itemState,
        address transporterID,
        address consumerID
    ) {
        Item memory item = items[_upc];
        return (
            item.sku,
            item.upc,
            ownerLookup(),
            item.originSellerID,
            item.originSellerName,
            item.productID,
            item.productNotes,
            item.productPrice,
            item.itemState,
            item.transporterID,
            item.consumerID
        );
    }
}
