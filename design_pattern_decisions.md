# Design Pattern Decisions

**Hey Bucko give examples in code**

## Circuit Breaker
I implemented a circuit breaker with the setStopped() function. This function can only be called by the owner of the FundMarketplace contract and all investor and manager functionality is disabled in the event of an attack or a bug detection. The only exception is the withdrawFunds() function which allows investors to recover their fees.
````
modifier stopInEmergency () {
    require(
        !stopped,
        "Emergency State: Vulnerability Detected"
    );
    _;
}

function setStopped ()
public 
isAdmin()
{
    stopped = !stopped;
}

function Invest(uint _fundNum, uint _investment) 
external payable 
stopInEmergency() 
{
    InvestLib.Invest(funds, _fundNum, _investment, msg.sender, msg.value);
    emit Investment(_fundNum, msg.sender, _investment);
}
```

## Pull Over Push Payments
I separate the function logic of fee payments into PayFee() and CollectFee(). When a payment cycle is over, the investor will call PayFee() to handle the accounting of crediting the manager's account with fees. Then the manager calls CollectFees(), which zeros out his fees balance in the fund and uses .transfer() to send ether to her wallet. Because these transfers take place at the end of the function, all necessary state changes have already occurred. This pattern protects against re-entrancy and DOS attacks.

## Mortal
I decided not to implement a mortal design pattern, because there would be no automatic way to distribute fees stored in the contract to both investor and manager. This would make the contract less trustworthy as if would incentivize the administrator to be malicious. Instead, the circuit breaker design pattern restricts all activity with the exception of withdrawing funds.

## Fail Early and Fail Loud
All of the contract functions have modifiers that throw an exception if the conditions for execution are not met. This practice prevents wasteful code execution and provides warning messages to point the user to the invalid code.

## Events
I emitted events for all contract functions in FundMarketplace.sol. The event for OrderPlaced is used to populate the Orders Menu for the investor and the manager, serving as the communication between the manager and his investors. In a future implementation of the project, I plan to encrypt these events as anyone could listen for them and see the contents. Another option would be to make these communications off-chain.

## Restricting Access
While all users can function as both investors and managers, their ability to access functions within a fund are dependent upon their relationship to the fund. For example, while any address can initiate, invest in a fund, only the manager of the fund can place orders, collect fees, close the fund, and end the fundraising period. Investors, in turn, can pay fees and withdraw some or all of their investment before the fund closes.

## Sending/Receiving Ether
The FundMarketplace.sol contract is meant to send and receive ether, because it acts as an escrow account for the payment of fees between investors and managers, and controls the business logic of these payments. There is no fallback function, so that if any ether is sent without a function call, it will be refunded to the sender.

## Multiple Contracts
I chose to create multiple library contracts, which were stateless and contained most of the functionality of FundMarketplace.sol, in order to reduce the size of the main contract, wich was primarily responsible for storage and events. In terms of gas costs, deploying 10 contracts instead of 1 large one is most likely suboptimal. However, the libraries are useful for upgradeability in regards to the FundMarketplace.sol contract if the functionality still applies to the upgraded contract. I plan to try to reduce the number of contracts deployed in future iterations of the project.

## Future Improvements
- Revise fee payments structure so that the state changes regarding the fees in escrow are controlled solely by the manager and not by the investors. In the current implementation, an investor could choose not to pay their funds when the paymentCycle is over.
- Functionality to refill fees once a yearly cycle is up
- Restrict Payment Cycle to Monthly and Quarterly options and synchronize payments between investors
- Use Oraclize to provide current ETH/USD conversion so that managers can place orders and investors receive orders in USD
- Encrypt OrderPlace Events or move communication off-chain
- Use API of brokerage firms to automate order execution
