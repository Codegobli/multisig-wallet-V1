// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultisigWallet {
    // STATE VARIABLES
    address[] public owners; //List of owners
    mapping(address => bool) public isOwner; // Checks wether an address is authorized
    uint public minNumOfConfirmations; //This stores the required number of confirmations

    //To submit a transactionn you have to include everyone of this
    struct Transaction {
        address to; //Where you are sending to
        uint256 value; //Amount you are sending
        bytes data; //This is only necessary when your interacting with a contract
        bool executed; //Check if its been executed. Default is false
        uint numOfConfirmations; // No of confirmations met
    }

    Transaction[] public transactions; //We need a way to store every transactions submitted, this does it

    // txIndex => owner => confirmed?
    mapping(uint => mapping(address => bool)) public isConfirmed;

    //  EVENTS
    event SubmitTransaction(uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(uint indexed txIndex, address indexed owner);
    event ExecuteTransaction(uint indexed txIndex, address indexed executor);
    event Deposit(address indexed sender, uint amount);

    //  MODIFIERS
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }

    // === CONSTRUCTOR ===
    constructor(address[] memory _owners, uint _minNumOfConfirmations) {
        require(_owners.length > 0, "Owners required");
        require(
            _minNumOfConfirmations > 0 && _minNumOfConfirmations <= _owners.length,
            "Invalid number of confirmations"
        ); // require that minimum number of confirmations should be greater than zero but less than or equal to entire length of owners

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        minNumOfConfirmations = _minNumOfConfirmations;
    }

    // === RECEIVE ETH ===
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // === SUBMIT A TRANSACTION ===
    function submitTransaction(address _to, uint _value, bytes memory _data)
        public onlyOwner
    {
        uint txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numOfConfirmations: 0
        }));

        emit SubmitTransaction(txIndex, _to, _value, _data);
    }

    // === CONFIRM A TRANSACTION ===
    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage txn = transactions[_txIndex];
        txn.numOfConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(_txIndex, msg.sender);
    }

    // === EXECUTE A TRANSACTION ===
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage txn = transactions[_txIndex];

        require(
            txn.numOfConfirmations >= minNumOfConfirmations,
            "Not enough confirmations"
        );

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(_txIndex, msg.sender);
    }

    // === GETTER FUNCTIONS ===
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numOfConfirmations
        )
    {
        Transaction memory txn = transactions[_txIndex];
        return (txn.to, txn.value, txn.data, txn.executed, txn.numOfConfirmations);
    }
}
