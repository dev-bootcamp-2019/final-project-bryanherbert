# Mimic
A dApp on the Ethereum network that serves as a decentralized marketplace for investment strategies. Users can act as both investors and managers and the dApp utilizes smart contracts to manage investments, fee payments and fund management.

Investors can subscribe to different funds, which are controlled by managers who make investment decisions to buy or sell equities for the fund. These decisions are then broken up into orders and distributed to the subscribed investors on a pro rata basis. Investors then execute these trades to mimic the strategy of the fund.

## Demo on Rinkeby Testnet
The FundMarketplace contract and relevant libraries are deployed on the Rinkeby testnet. For reference, the contract addresses are listed in `deployed_addresses.txt`.

## Note on Investment Subscription Model
Mimic enables investors to subscribe to the investment strategies of different managers. In a traditional investment fund, an investor transfers her investment to the fund and the manager at the fund will directly invest that capital into asset classes. The fund changes value and the investor recognizes her gains or losses when she withdraws her balance in the fund. 

With Mimic's Investment Subscription Model, the investor does not actually transfer capital to the manager, but instead allocates a "virtual balance" that she would like managed by the fund. The manager of the fund uses the sum of these virtual balances (total capital) to make investment decisions. However, each individual investor still controls the funds they've subscribed to the fund. 

The manager will make an investment decision on behalf of the fund and "place an order". This order is then broken down into smaller orders on a pro rata basis and communicated to each investor based on the size of her investment in the fund. The investor receives the order and executes it with their allocated capital through her broker. In this way, the investor's allocated capital for the fund is used to create a portfolio that will produce an identical return to that of the overall fund. Put simply, the investor subscribes to a fund and receives investment decisions proportional to her allocated capital in the fund. The only value transfer across the platform is the payment of management fees.

For example, Investor A could allocate 100 ether to "Alpha Fund", which has a 2% management fee. When Investor A clicks the "Invest" button, she will only transfer 2 ether to hold in escrow for the payment of the management fee but retains ownership of the 100 ether investment. The resulting total capital of Alpha Fund increases to 1,000 ether and the manager of Alpha Fund makes investment decisions with that balance. The manager of the fund then decides to buy 1,000 ether worth of Apple shares and communicates that decision by placing an order on the Mimic platform. Investor A then receives an order to buy 100 ether worth of Apple shares (10% of the order because she owns 10% of the fund). Investor A uses her 100 ether of allocated capital to purchase the shares. In this way, her portfolio will "mimic" the performance of the fund.

## User Stories
An investor opens the dApp. The dApp checks the investor's address and populates the "My Investments" Table with any funds in which the investor currently has a balance. In the "Fund Marketplace" section, the investor can browse through different funds which include the following information:
- Name of the Fund
- Address of the Manager
- Total Capital Invested in the Fund
- Annual Fee Rate
- Payment Cycle (determines frequency of fee payments)

The investor can choose to subscribe to a fund 


## Prerequisites

## Running the dApp

## Testing

## Security Implementation

## Design Pattern Choices

## Author
Bryan Herbert
- Github: [bryanherbert](https://github.com/bryanherbert)