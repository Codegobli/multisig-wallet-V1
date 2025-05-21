multisig-wallet-V1
A secure multi-signature wallet built in Solidity. Allows multiple owners to collectively authorize transactions.

Features
Multiple owners
Submit/confirm/execute transactions
Prevents single-point failure
Events for easy tracking

Tech Stack
Solidity ^0.8.20
Remix IDE (for development & testing)

How It Works
Deploy the contract with a list of owners and required confirmations.
Any owner can submit a transaction.
Other owners must confirm it.
Once minimum confirmations are reached, any owner can execute.

Events
Deposit: ETH received
SubmitTransaction
ConfirmTransaction
ExecuteTransaction
Security Considerations
Prevents re-execution
Requires unique confirmations
Avoids rogue spending by requiring consensus

License
MIT