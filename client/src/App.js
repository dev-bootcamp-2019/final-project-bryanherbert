import React, { Component } from "react";
import FundMarketplace from "./contracts/FundMarketplace.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";

import "./App.css";

class App extends Component {
  state = { name: null, manager: null, investment: null, feeRate: null, paymentCycle: null, web3: null, accounts: null, contract: null };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const Contract = truffleContract(FundMarketplace);
      Contract.setProvider(web3.currentProvider);
      const instance = await Contract.deployed();

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, contract: instance }, this.runExample);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`
      );
      console.log(error);
    }
  };

  runExample = async () => {
    //Add web3 here
    const { web3, accounts, contract } = this.state;

    //Initializes fund with account[0]
    let name = web3.utils.asciiToHex("alpha");
    const manager = accounts[0];
    let amount = 1;
    let investment = web3.utils.toWei(amount.toString(), "ether");
    let feeRate = 2;
    let paymentCycle = 0;

    await contract.initializeFund(name, manager, investment, feeRate, paymentCycle, { from: manager });

    //Get the information from the newly established fund
    const response = await contract.getFundDetails(name);

    //Update state with result
    this.setState({ 
      name: web3.utils.hexToAscii(response[0]), 
      manager: response[1], 
      investment: web3.utils.fromWei(response[2].toString(), "ether"), 
      feeRate: response[4].toNumber(), 
      paymentCycle: response[5].toNumber(),});
  };

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <h1>Welcome to Mimic</h1>
        <p>Your one stop shop for wealth management guidance</p>
        <h2>Fund Marketplace</h2>
        <p>
          If your contracts compiled and migrated successfully, below will display the name of the alpha fund.
        </p>
        <div>The name of the fund is: <strong>{this.state.name}</strong></div>
        <div>The manager of the fund is: <strong>{this.state.manager}</strong></div>
        <div>The size of the fund is: <strong>{this.state.investment} ether</strong></div>
        <div>The fee rate of the fund is: <strong>{this.state.feeRate}%</strong></div>
        <div>The payment cycle of the fund is: <strong>{this.state.paymentCycle} days</strong></div>
      </div>
    );
  }
}

export default App;
