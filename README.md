# Mimic
A dApp on the Ethereum network that serves as a decentralized marketplace for investment strategies. Users can act as both investors and managers and the dApp utilizes smart contracts to manage investments, fee payments and fund management.

Investors can subscribe to different funds, which are controlled by managers who make investment decisions to buy or sell equities for the fund. These decisions are then broken up into orders and distributed to the subscribed investors on a pro rata basis. Investors then execute these trades to mimic the strategy of the fund.

## Demo on Rinkeby Testnet
The FundMarketplace contract and relevant libraries are deployed on the Rinkeby testnet. For reference, the contract addresses are listed in `deployed_addresses.txt`.

## Note on Investment Subscription Model
Mimic enables investors to subscribe to the investment strategies of different managers. In a traditional investment fund, an investor transfers her investment to the fund and the manager at the fund will directly invest that capital into asset classes. The fund changes value and the investor recognizes her gains or losses when she withdraws her balance in the fund. 

With Mimic's Investment Subscription Model, the investor does not actually transfer capital to the manager, but instead allocates a "virtual balance" that she would like managed by the fund. The manager of the fund uses the sum of these virtual balances (total capital) to make investment decisions. However, each individual investor still controls the funds they've subscribed to the fund. 

The manager will make an investment decision on behalf of the fund and "place an order". This order is then broken down into smaller orders on a pro rata basis and communicated to each investor based on the size of her investment in the fund. The investor receives her pro rata order and executes it with their allocated capital through her broker. In this way, the investor's allocated capital for the fund is used to create a portfolio that will produce an identical return to that of the overall fund. Put simply, the investor subscribes to a fund and receives investment decisions proportional to her allocated capital in the fund. The only value transfer across the platform is the payment of management fees.

For example, Investor A could allocate 100 ether to "Alpha Fund", which has a 2% management fee. When Investor A clicks the "Invest" button, she will only transfer 2 ether to hold in escrow for the payment of the management fee but retains ownership of the 100 ether investment. The resulting total capital of Alpha Fund increases to 1,000 ether and the manager of Alpha Fund makes investment decisions with that balance. The manager of the fund then decides to buy 1,000 ether worth of Apple shares and communicates that decision by placing an order on the Mimic platform. Investor A then receives an order to buy 100 ether worth of Apple shares (10% of the order because she owns 10% of the fund). Investor A uses her 100 ether of allocated capital to purchase the shares. In this way, her portfolio will "mimic" the performance of the fund.

## User Stories
**Note: A user can be both an investor and a manager**
### Investor
An investor opens the dApp. The dApp checks the investor's address and populates the "My Investments" table with any funds in which the investor currently has a balance. 

In the "Fund Marketplace" section, the investor can browse through different funds which include the following information:
- Name of the Fund
- Address of the Manager
- Total Capital Invested in the Fund
- Annual Fee Rate
- Payment Cycle (determines frequency of fee payments)

The investor can choose to subscribe to a fund by entering in an amount of ether into the input and clicking the "Invest" button. Metamask will prompt the user to sign a transaction that will update the data in the smart contract and transfer the management fees for a single year to the smart contract, which acts as the escrow account. 

Once the investor has invested in a fund, that fund will appear under the "My Investments" Table. An entry in the table contains the following information:
- Name of the Fund
- Investor's Virtual Balance managed by the Fund
- Percentage of the Balance currently deployed
- Fees Menu Button (opens a modal with fee payment functionality)
- Order Menu (opens a modal with the list of received orders)
- Withdraw Button (allows the investor to withdraw capital from the fund)

The investor clicks on the "Fees Menu" button, which pulls up a modal that details the total fees held currently held in escrow and the fee payment due in the next cycle. If a full cycle has not occurred, the "Pay Fees" button will be disabled. If a full cycle has occurred, the investor can click the "Pay Fees" button to transfer the current fee payment from the smart contract to the manager's account.

The investor clicks on the Order Menu, which pulls up a modal that details the list of personalized investments that the investor has received from the fund.

If the investor wishes to withdraw some or all of her balance from a fund, she can click the "Withdraw Button" and remove her balance and remaining fees from the fund.

### Manager
A manager opens the dApp. The dApp checks the manager's address and populates the "My Funds" table with any funds that the manager operates. With the fund launch form, the manager can create a fund and define its parameters including:
- Name of the Fund
- Manager's Initial Investment (virtual balance that the manager allocates)
- Annual Management Fee
- Payment Cycle (determines how often fee payments are made)

The manager can get the details of her funds and interact with them in the "My Funds" table. The "My Fund" provides the following information:
- Name of the Fund
- Manager's Virtual Balance managed by the Fund
- Total Capital managed by the Fund
- Capital Deployed by the Fund
- Annual Fee Rate
- Payment Cycle
- Fees Menu Button (opens a modal with fee payment functionality)
- Order Menu Button (opens a modal with order functionality)
- Close Fund (removes the fund from the marketplace)

The manager clicks on the "Fee Menu" button, which pulls up a modal that details the fees available for the manager to collect. She clicks the "Collect Fees" button to transfer the fees from the smart contract to her account.

The manager clicks on the "Order Menu" button, which pulls up a modal with two tabs: "New Order" and "Past Orders". In the "New Order" tab, the manager can make an investment for the fund by placing order with the following information:
- Action (Buy or Sell)
- Ticker
- Quantity of Shares
- Price per Share

After entering in the information, the manager clicks the "Place Order" button. This investment is recorded in the "Past Orders" tab. As a result, each investor who is subscribed to the fund receives an adjusted order that changes the quantity of shares based on each investor's level of capital invested in the fund. The manager can see her own designated quantity under the "My Quantity" column of the past orders tab.

When the manager decides to close the fund, she clicks the "Close Fund" Button, which deletes the fund's data from the smart contract and returns unearned fees to the investors.

## Prerequisites
- npm 6.5+
- truffle 4.1.4+
- ganache-cli 6.1.8+
- Metamask-enabled browser

## Running the dApp

## Testing
I've written tests in both Solidity and Javascrip that check the following behavior:
- fund initialization
- investing in a fund
- placing and receiving investment orders
- paying and collecting fees
- withdrawing capital from a fund

## Security Implementation
[Open file](https://github.com/dev-bootcamp-2019/final-project-bryanherbert/blob/master/avoiding_common_attacks.md)

## Design Pattern Choices
[Open file](https://github.com/dev-bootcamp-2019/final-project-bryanherbert/blob/master/design_pattern_decisions.md)

## Author
Bryan Herbert
- Github: [bryanherbert](https://github.com/bryanherbert)