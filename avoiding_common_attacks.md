# Avoiding Common Attacks

## User Permissions

## Overflow && Underflow Protection
Each contract uses OpenZeppelin's `SafeMath` library to perform integer operations to prevent overflow or underflow.

## Reentrancy Attack Protection
All transactions that send ether use `.transfer()` and this function does not provide enough gas to execute any malicious code. In addition, transfers occur at the end of functions after state changes have been made.

## Contract Balance
Contract does store balance, but can be recovered by killing contract o 