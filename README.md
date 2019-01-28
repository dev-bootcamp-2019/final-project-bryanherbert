# Mimic
A dApp on the Ethereum network that serves as a decentralized marketplace for investment strategies. Mimic utilizes smart contracts to handle investments, fee payments and fund management.

Users can act both as investors and managers. Investors can subscribe to different funds, which are controlled by managers who make investment decisions to buy or sell equities for the fund. These decisions are then broken up into orders and distributed to the subscribed investors on a pro rata basis. Investors can execute these trades to mimic the strategy of the fund.

![alt text](./img/Screenshot1.png?raw=true "Homepage")

## Structure
The main contract is FundMarketplace.sol. It was implemented in Solidity v0.5.0 with the truffle development framework. This contract is responsible for storing the on-chain data, holding ether in escrow for fee payments and all the functions of the dApp. These functions are implemented across libraries that I wrote to decrease the size of the main contract. This choice is discussed in more detail in design_pattern_decsions.md. The libraries deployed as part of this project are:
- CollectFeesLib.sol
- InitLib.sol
- InvestLib.sol
- Misc.sol
- OrderLib.sol
- PayFeeLib.sol
- StructLib.sol
- WithdrawFundsLib.sol  
  
FundMarketplace.sol also uses the `SafeMath` library from OpenZeppelin, which is stored in the repository.  

One of the state variables in FundMarketplace.sol is funds, which is a Data struct defined in StructLib.sol. This Data struct is a mapping to a Fund struct, which contains all the data for the funds in the marketplace. This data includes:
- Fund Number
- Fund Name
- Fund Owner
- Total Capital
- Capital Deployed
- Fee Rate
- Payment Cycle
- A mapping used to determine if an address is a valid investor
- A mapping used to determine an address's virtual balance committed to the fund
- A mapping used to determine an address's fees in escrow
- A mapping used to determine an the start of an address's payment cycle
- A bool that indicates whether fundraising is active
- A bool that indicates whether the fund is closed
- A multihash struct that contains the information to reproduce the IPFS hash

As discussed above, the ether that an investor invests or commits to a fund is not actually transferred. Only the associated management fees are transferred to the FundMarketplace.sol contract when investor subscribes to a fund. As these payments become do, an investor will use the `PayFee()` function to change the state such that these fees are credited to the manager's account, who can then retrieve them with the `CollectFee` function. During the time in between, the ether is stored in the smart contract.

## Note on Investment Subscription Model
Mimic enables investors to subscribe to the investment strategies of different managers. In a traditional investment fund, an investor transfers her investment to the fund and the manager at the fund will directly invest that capital into asset classes. The fund changes value and the investor recognizes her gains or losses when she withdraws her balance in the fund. 

With Mimic's Investment Subscription Model, the investor does not actually transfer capital to the manager, but instead allocates a "virtual balance" that she would like managed by the fund. The manager of the fund uses the sum of these virtual balances (total capital) to make investment decisions. However, each individual investor still controls the funds they've subscribed to the fund. 

The manager will make an investment decision on behalf of the fund and "place an order". This order is then broken down into smaller orders on a pro rata basis and communicated to each investor based on the size of her investment in the fund. The investor receives her pro rata order and executes it with their allocated capital through her broker. In this way, the investor's allocated capital for the fund is used to create a portfolio that will produce an identical return to that of the overall fund. Put simply, the investor subscribes to a fund and receives investment decisions proportional to her allocated capital in the fund. The only value transfer across the platform is the payment of management fees.

For example, Investor A could allocate 100 ether to "Alpha Fund", which has a 2% management fee. When Investor A clicks the "Invest" button, she will only transfer 2 ether to hold in escrow for the payment of the management fee but retains ownership of the 100 ether investment. The resulting total capital of Alpha Fund increases to 1,000 ether and the manager of Alpha Fund makes investment decisions with that balance. The manager of the fund then decides to buy 1,000 ether worth of Apple shares and communicates that decision by placing an order on the Mimic platform. Investor A then receives an order to buy 100 ether worth of Apple shares (10% of the order because she owns 10% of the fund). Investor A uses her 100 ether of allocated capital to purchase the shares. In this way, her portfolio will "mimic" the performance of the fund.

## User Stories
**Note: A user can be both an investor and a manager**
### Investor
An investor opens the dApp. The dApp checks the investor's address, displays it, and populates the "My Investments" table with any funds in which the investor currently has a balance. 

In the "Fund Marketplace" section, the investor can browse through different funds which include the following information:
- Name of the Fund
- Address of the Manager
- Total Capital Invested in the Fund
- Annual Fee Rate
- Payment Cycle (determines frequency of fee payments)
- Link to Investment Prospectus stored on IPFS

The investor can choose to subscribe to a fund by entering in an amount of ether into the input and clicking the "Invest" button. Metamask will prompt the user to sign a transaction that will update the data in the smart contract and transfer the management fees for a single year to the smart contract, which acts as the escrow account. 

Once the investor has invested in a fund, that fund will appear under the "My Investments" Table. An entry in the table contains the following information:
- Name of the Fund
- Investor's Virtual Balance managed by the Fund
- Percentage of the Balance currently deployed
- A Link to the Fund's Investment Prospectus
- Fees Menu Button (opens a modal with fee payment functionality)
- Order Menu (opens a modal with the list of received orders)
- Withdraw Button (allows the investor to withdraw capital from the fund)

The investor clicks on the "Fees Menu" button, which pulls up a modal that details the total fees held currently held in escrow and the fee payment due in the next cycle. If a full cycle has not occurred, the "Pay Fees" button will be disabled. If a full cycle has occurred, the investor can click the "Pay Fees" button to initialize a state change that credits the manager's account with the fee payment.

The investor clicks on the Order Menu, which pulls up a modal that details the list of personalized investments that the investor has received from the fund. She can execute these orders through her brokerage account so that the performance of her investment will match that of the fund. The block number is also included in case it is necessary to look up the approximate time at which the order was sent.

If the investor wishes to withdraw some or all of her balance from a fund, she can click the "Withdraw Button" and remove her balance and remaining fees from the fund. Fees will only be returned if the entirety of the balance is removed.

### Manager
A manager opens the dApp. The dApp checks the manager's address, displays it and populates the "My Funds" table with any funds that the manager operates. With the fund launch form, the manager can create a fund and define its parameters including:
- Name of the Fund
- Manager's Initial Investment (virtual balance that the manager allocates)
- Annual Management Fee
- Payment Cycle (determines how often fee payments are made)
- Investment Prospectus (uploaded to IPFS)

The manager can get the details of her funds and interact with them in the "My Funds" table. The "My Fund" provides the following information:
- Name of the Fund
- Manager's Virtual Balance managed by the Fund
- Total Capital managed by the Fund
- Capital Deployed by the Fund
- Fund Menu Button (opens a modal with fund management functionality)
- Fees Menu Button (opens a modal with fee payment functionality)
- Order Menu Button (opens a modal with order functionality)
- Close Fund (removes the fund from the marketplace)

The manager clicks on the "Fund Menu" button, pulling up a modal that gives information about the annual fee rate, payment cycle and link to the prospectus. In addition, the manager has the option to end the fundraising period of the fund. If the fund were allowed to continue taking investments throughout its lifecycle, the ability of new investors to mimic the performance of the fund would breakdown. Therefore, the manager will enable the ability to raise capital during the fundraising period. Once the goal is met, the manager can deactivate the abiliity to raise new capital by clicking the "End Fundraising Period" Button. This disables the ability of new investors to commit capital to the fund.

The manager clicks on the "Fee Menu" button, which pulls up a modal that details the fees available for the manager to collect. She clicks the "Collect Fees" button to transfer the fees from the smart contract to her account.

The manager clicks on the "Order Menu" button, which pulls up a modal with two tabs: "New Order" and "Past Orders". In the "New Order" tab, the manager can make an investment for the fund by placing order with the following information:
- Action (Buy or Sell)
- Ticker
- Quantity of Shares
- Price per Share (in finney)

**Note: The price per share is in finney (0.001 ether). The following link provides a conversion from finney to ether to USD: 
[Converter](https://etherconverter.online)**

After entering in the information, the manager clicks the "Place Order" button. This investment is recorded in the "Past Orders" tab. As a result, each investor who is subscribed to the fund receives an adjusted order that changes the quantity of shares based on each investor's committed capital in the fund. The manager can see her own designated quantity under the "My Quantity" column of the past orders tab.

When the manager decides to close the fund, she clicks the "Close Fund" Button, which removes the fund's data from the manager's UI and the Fund Marketplace but allows investors to recover their unearned fees when they receive an alert that the fund has closed.

## Prerequisites
- NodeJs 11+
- npm 6+
- truffle 5.0.0+
- Solidity 0.5.0+
- ganache-cli 6.2.0+
- Metamask-enabled browser

## Running the dApp Locally
1. Clone the github repository:  
```
$ git clone https://github.com/dev-bootcamp-2019/final-project-bryanherbert.git
```
2. Install dependencies in the root directory and in the client directory:
```  
$ cd final-project-bryanherbert  
$ npm install
$ cd client 
$ npm install
```
3. Start Ganache:
``` 
$ ganache-cli
```
Copy the mnemonic to recover your account in Metamask.
**Note: The development network should be listening at `127.0.0.1:8545`**  

4. Use truffle to compile contracts:  
```
$ truffle compile
```
5. Use truffle to deploy contracts: 
``` 
$ truffle migrate
```
You can also migrate the contracts to the Ropsten testnet:
```
$ truffle migrate --network ropsten
```
In order to properly migrate onto the Ropsten network, you must set your own MNEMONIC and infuraKey in `truffle.js`.  

6. Run the frontend (in client directory):
```  
$ npm run start
```
Access the frontend in your browser at `http://localhost:3000/`.  

Once the dApp is running, you can begin to interact with it. In the development environment, the first ganache address will be the owner and admin user of the FundMarketplace.sol contract. This account can call the `setStopped()` function to halt all functionality except for functions that allow the user to withdraw fees. When switching accounts in Metamask, remember to refresh the page to update the UI.

### Demo on Ropsten Testnet
The FundMarketplace contract and relevant libraries are deployed on the Ropsten testnet. For reference, the contract addresses are listed in `deployed_addresses.txt`.

## Testing
I've written tests in both Solidity and Javascript that check the following behavior:
- fund initialization: tests state changes when a manager starts a fund
- investing in a fund: tests state changes and ether transfers when an investor subscribes to a fund
- placing and receiving investment orders: tests state changes when a manager places an order and tests functions that customize an investor's received order
- withdrawing capital from a fund: tests state changes and ether transfers when there is an investor partly or completely withdraws from a fund
- closing a fund: tests state changes when a manager closes a fund

There are currently no tests for paying and collecting fees because the setTimeout() function would take too long for a reasonable testing time (at least 1 day);

Use the following command to run the Solidity and Javascript tests:
```
$ truffle test
```
**Note: All of the other contracts deployed besides FundMarketplace.sol are libraries. Therefore, tests are only for FundMarketplace.sol which utilizes the functionality of the libraries.**

## IPFS
The project uses IPFS to store the investment prospectuses uploaded by fund managers. There is a separate `ipfs.js` file in `/src` which connects to the IPFS via an Infura node. When a fund manager initializes a fund with the form, she must upload an investment prospectus. The dApp takes the file as an input and converts it to a buffer, which is uploaded to IPFS. The hash of the file returned by IPFS is stored as part of the struct which contains other information about the fund. Importantly, it is stored in a multihash struct in case of changes to the IPFS hashing algorithm. When information about a fund is rendered in the dApp, it pulls in the hash from on-chain storage and then renders the file in a new tab when the link is clicked.

## Security Features
[Open file](https://github.com/dev-bootcamp-2019/final-project-bryanherbert/blob/master/avoiding_common_attacks.md)

## Design Pattern Choices
[Open file](https://github.com/dev-bootcamp-2019/final-project-bryanherbert/blob/master/design_pattern_decisions.md)

## Author
Bryan Herbert
- Github: [bryanherbert](https://github.com/bryanherbert)