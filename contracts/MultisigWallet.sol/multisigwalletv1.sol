// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Multi-signature Wallet
 * @dev A secure multi-signature wallet requiring multiple approvals for transactions
 * @notice Allows a group of owners to collectively manage funds with configurable approval thresholds
 */
contract MultisigWallet {
    // ============ STATE VARIABLES ============
    
    /// @notice List of wallet owners
    address[] public owners;
    
    /// @notice Mapping to check if an address is an authorized owner
    mapping(address => bool) public isOwner;
    
    /// @notice Minimum number of confirmations required to execute transactions
    uint public minNumOfConfirmations;
    
    /// @notice Structure representing a transaction proposal
    struct Transaction {
        address to;           // Recipient address
        uint256 value;        // Amount of ETH to transfer
        bytes data;           // Calldata for contract interactions
        bool executed;        // Execution status
        uint numOfConfirmations; // Current confirmation count
    }
    
    /// @notice Array of all submitted transactions
    Transaction[] public transactions;
    
    /// @notice Mapping of transaction index => owner => confirmation status
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // ============ EVENTS ============
    
    /// @notice Emitted when a new transaction is submitted
    event SubmitTransaction(uint indexed txIndex, address indexed to, uint value, bytes data);
    
    /// @notice Emitted when an owner confirms a transaction
    event ConfirmTransaction(uint indexed txIndex, address indexed owner);
    
    /// @notice Emitted when a transaction is successfully executed
    event ExecuteTransaction(uint indexed txIndex, address indexed executor);
    
    /// @notice Emitted when ETH is deposited into the wallet
    event Deposit(address indexed sender, uint amount);

    // ============ MODIFIERS ============
    
    /// @dev Restricts access to wallet owners only
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    
    /// @dev Validates that a transaction exists
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }
    
    /// @dev Ensures transaction hasn't been executed yet
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }
    
    /// @dev Ensures owner hasn't already confirmed the transaction
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }

    // ============ CONSTRUCTOR ============
    
    /**
     * @dev Initializes the multi-signature wallet
     * @param _owners Array of owner addresses
     * @param _minNumOfConfirmations Minimum confirmations required for execution
     * @notice Owners must be unique, non-zero addresses
     */
    constructor(address[] memory _owners, uint _minNumOfConfirmations) {
        require(_owners.length > 0, "Owners required");
        require(
            _minNumOfConfirmations > 0 && _minNumOfConfirmations <= _owners.length,
            "Invalid number of confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        minNumOfConfirmations = _minNumOfConfirmations;
    }

    // ============ EXTERNAL FUNCTIONS ============
    
    /**
     * @dev Allows the contract to receive ETH
     * @notice Emits Deposit event when ETH is received
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // ============ PUBLIC FUNCTIONS ============
    
    /**
     * @dev Submits a new transaction for approval
     * @param _to Recipient address
     * @param _value Amount of ETH to send
     * @param _data Calldata for contract interactions
     * @return txIndex Index of the newly created transaction
     */
    function submitTransaction(address _to, uint _value, bytes memory _data)
        public onlyOwner returns (uint txIndex)
    {
        txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numOfConfirmations: 0
        }));

        emit SubmitTransaction(txIndex, _to, _value, _data);
    }
    
    /**
     * @dev Confirms a pending transaction
     * @param _txIndex Index of the transaction to confirm
     */
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
    
    /**
     * @dev Executes a transaction that has sufficient confirmations
     * @param _txIndex Index of the transaction to execute
     */
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

    // ============ VIEW FUNCTIONS ============
    
    /**
     * @dev Returns the total number of transactions
     * @return count Total transaction count
     */
    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }
    
    /**
     * @dev Returns transaction details for a given index
     * @param _txIndex Index of the transaction
     * @return to Recipient address
     * @return value Amount of ETH
     * @return data Calldata
     * @return executed Execution status
     * @return numOfConfirmations Current confirmation count
     */
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
