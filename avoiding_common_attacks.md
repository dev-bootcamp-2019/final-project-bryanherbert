# Avoiding Common Attacks

## User Permissions
Depending on their relationship to the fund, users only have certain rights as to which contract function they can execute. These rights are controlled by modifiers.  
An investor of a fund can:
- invest in a fund
- pay fees
- withdraw balance
- receive information about the fund  

  A manager of a fund can:
- initialize a fund
- collect fees
- place orders
- end the fundraising period
- close the fund
- receive information about the fund 

  An administrator of the contract can:
- execute the circuit breaker for the contract

## Overflow & Underflow Protection
Each contract uses OpenZeppelin's `SafeMath` library to perform integer operations to prevent overflow or underflow.

## Reentrancy & Cross-Function Race Attack Protection
All transactions that send ether use `.transfer()` and this function does not provide enough gas to execute any malicious code. In addition, transfers occur at the end of functions after all internal state changes have been made and the withdrawal patter is used, which prevents reentrancy. Cross-Function Attacks are blocked with `require` assertions. For example when an investor attempts to withdraw, she must already be invested in the fund and cannot withdraw more than her current balance. Therefore an attacker couldn't call `Invest()` and `withdrawFunds()` at the same time with the intention of having the `Invest()` function revert and the `withdrawFunds()` function succeed.

## Contract Balance
The FundMarketplace.sol contract is meant to send and receive ether, because it acts as an escrow account for the payment of fees between investors and managers, and controls the business logic of these payments. There is no fallback function, so that if any ether is sent without a function call, it will be refunded to the sender. I chose not to implement a kill() function, because there would be no clear way to return fees to investors and managers. A future implementation will include such a methodology as well as the kill() function to recover any forcibly sent ether.

## Timestamp Dependence
None functions in the contract are timestamp dependent, except for `PayFee()`. However, this timing is calculated on the scale of days and so a difference in block timestamp of less than 30 seconds is irrelevant. Furthermore, the ordering of fee payments does not matter either.

## DOS Attack (Block Gas Limit and Unexpected Revert)
The withdrawal pattern is used to transfer fees in ether to the manager in order to avoid an unexpected revert attack. The contract also does not iterate over loops of unknown size to avoid a DOS attack with Block Gas Limit