import React, { Component } from "react";
import FundMarketplace from "./contracts/FundMarketplace.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";
import { Button, Jumbotron, Row, Col, Form, FormGroup, Label, Input, FormText} from 'reactstrap';

import "./App.css";

function Fund(props) {
  // constructor(props){
  //   super(props);
  //   this.state = {
  //     name: null,
  //     manager: null,
  //     capital: null,
  //     feeRate: null,
  //     paymentCycle: null,
  //   };

  return(
    <div className = "fund">
      <h1>{props.name} Fund</h1>
      <p>Manager: {props.manager}</p>
      <p>Total Capital: {props.capital} ether</p>
      <p>Annual Fee Rate: {props.feeRate}%</p>
      <p>Payment Cycle: {props.paymentCycle} days</p>
    </div>
  );
}

class Board extends React.Component {
  //i is fund number
  renderFund(info) {
    return (
      <Fund
          name = {info.name}
          manager = {info.manager}
          capital = {info.capital}
          feeRate = {info.feeRate}
          paymentCycle = {info.paymentCycle}
      />
    );
  }

  render(){
    return (
      <div>
        {this.renderFund(this.props)}
      </div>
    )
  }

}

class App extends Component {
  constructor(props){
    super(props);
    this.state = {
      
      fundList: [
        {
          fundName: null,
          fundManager: null,
          fundInvestment: null,
          fundFeeRate: null,
          fundPaymentCycle: null,
        }
      ],
      
      name: null,
      inputName: null, 
      
      manager: null,
      inputManager: null,
      
      investment: null,
      inputInvestment: null,  
      
      feeRate: null,
      inputFeeRate: null, 
      
      paymentCycle: null,
      inputPaymentCycle: null, 
      
      fundCount: null, 
      
      web3: null, 
      accounts: null, 
      contract: null };
    
    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

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
    
      this.setState({ web3, accounts, contract: instance }, this.setup);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`
      );
      console.log(error);
    }
  };

  handleChange(event) {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value
    });
  }

  handleSubmit = async (event) => {
    event.preventDefault();
    const { web3, accounts, contract, inputName, inputInvestment, inputFeeRate, inputPaymentCycle } = this.state;
    const name = web3.utils.asciiToHex(inputName);
    console.log(name)
    const manager = accounts[0];
    let amount = inputInvestment;
    let investment = web3.utils.toWei(amount.toString(), "ether");
    let feeRate = inputFeeRate;
    let paymentCycle = inputPaymentCycle;

    await contract.initializeFund(name, 
      manager, 
      investment, 
      feeRate, 
      paymentCycle, 
      { from: manager });
    const count = await contract.fundCount();
    const response = await contract.getFundDetails(count);
    
    //Update state with result
    this.setState({ 
      name: web3.utils.hexToAscii(response[0]), 
      manager: response[1], 
      investment: web3.utils.fromWei(response[2].toString(), "ether"), 
      feeRate: response[4].toNumber(), 
      paymentCycle: response[5].toNumber(),
      fundCount: count.toNumber()
    });
  }


  setup = async () => {
    //Add web3 here
    const { web3, accounts, contract } = this.state;

    //Test for getting the fundCount
    const fundCount = await contract.fundCount();

    //Update state with result
    this.setState({ 
      fundCount: fundCount.toNumber()
    });

    //Clear fundList
    //for (var member in this.state.fundList) delete this.state.fundList[member];

    //Define fundList variable to concatenate (not sure this is right, based on tic tac toe)
    //const fundList = this.state.fundList.slice(0, this.state.fundCount);
    //console.log("Pre Fund List: "+fundList);

    //Populate fundList Array
    if(fundCount > 0){
      for(let i=1; i<=fundCount; i++){
        const response = await contract.getFundDetails(i);
        if(i==1){
          this.setState({
            fundList: [
              {
                fundName: web3.utils.hexToAscii(response[0]), 
                fundManager: response[1], 
                fundInvestment: web3.utils.fromWei(response[2].toString(), "ether"), 
                fundFeeRate: response[4].toNumber(), 
                fundPaymentCycle: response[5].toNumber()
              }
            ]
          });
        } else{
            console.log("i = "+i);
            //maybe make this a slice
            const tempFundList = this.state.fundList;
            this.setState({
              fundList: tempFundList.concat([
                {
                  fundName: web3.utils.hexToAscii(response[0]), 
                  fundManager: response[1], 
                  fundInvestment: web3.utils.fromWei(response[2].toString(), "ether"), 
                  fundFeeRate: response[4].toNumber(), 
                  fundPaymentCycle: response[5].toNumber()
                }
              ])
            });
          }
      };
    };
    console.log("post Fund List: "+this.state.fundList);
    console.log("test name: "+this.state.fundList[0].fundName);
    console.log("test name: "+this.state.fundList[1].fundName);
    console.log("test name: "+this.state.fundList[2].fundName);
    console.log("test name: "+this.state.fundList[3].fundName);
    console.log("test name: "+this.state.fundList[4].fundName);
  };




  // runExample = async () => {
  //   //Add web3 here
  //   const { web3, accounts, contract } = this.state;

  //   //Initializes fund with account[0]
  //   let name = web3.utils.asciiToHex("alpha");
  //   const manager = accounts[0];
  //   let amount = 1;
  //   let investment = web3.utils.toWei(amount.toString(), "ether");
  //   let feeRate = 2;
  //   let paymentCycle = 0;
  //   let fundNum = 1;

  //   await contract.initializeFund(name, manager, investment, feeRate, paymentCycle, { from: manager });

  //   //Get the information from the newly established fund
  //   const response = await contract.getFundDetails(fundNum);

  //   //Test for getting the fundCount
  //   const fundCount = await contract.fundCount();

  //   //Update state with result
  //   this.setState({ 
  //     name: web3.utils.hexToAscii(response[0]), 
  //     manager: response[1], 
  //     investment: web3.utils.fromWei(response[2].toString(), "ether"), 
  //     feeRate: response[4].toNumber(), 
  //     paymentCycle: response[5].toNumber(),
  //     fundCount: fundCount.toNumber()
  //   });
  // };

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    const fundList = async () => {
      var i = this.state.fundCount;
      const { web3, contract } = this.state;
      const response = await contract.getFundDetails(i);
      console.log(i);
      return(
        <Fund
          name = {web3.utils.hexToAscii(response[0])}
          manager = {response[1]}
          investment = {web3.utils.fromWei(response[2].toString(), "ether")}
          feeRate = {response[4].toNumber()} 
          paymentCycle = {response[5].toNumber()}
        />
      );
    }

    return (
      <div className="App">
        <div>
          <Jumbotron>
            <h1 className="display-3">Welcome to Mimic</h1>
            <p className="lead">
            Your one stop shop for wealth management guidance
            </p>
          </Jumbotron>
        </div>
        <h2>Fund Marketplace</h2>
        <Row>
          <Col>
            <Form onSubmit={this.handleSubmit}>
            <h3>Launch a Fund with the form below:</h3>
            <FormGroup>
              <Label for="fundNameInput">Fund Name</Label>
              <Input type="text" name="inputName" id="nameForm" onChange = {this.handleChange}/>
            </FormGroup>
            <label>
              Initial Investment (in ether): 
              <input
                name="inputInvestment"
                type="text"
                onChange = {this.handleChange} />
            </label>
            <br></br>
            <label>
              Annual Management Fee Rate (%):
              <input
                name="inputFeeRate"
                type="text"
                onChange = {this.handleChange} />
            </label>
            <br></br>
            <label>
              Payment Cycle (in days): 
              <input
                name="inputPaymentCycle"
                type="text"
                onChange = {this.handleChange} />
            </label>
            <br></br>
            <input type="submit" value="Submit"/>
          </Form>
        </Col>
          <Col>
          <div>The name of the fund is: <strong>{this.state.name}</strong></div>
          <div>The manager of the fund is: <strong>{this.state.manager}</strong></div>
          <div>The size of the fund is: <strong>{this.state.investment} ether</strong></div>
          <div>The fee rate of the fund is: <strong>{this.state.feeRate}%</strong></div>
          <div>The payment cycle of the fund is: <strong>{this.state.paymentCycle} days</strong></div>
          <p>
            Total Fund Count: <strong>{this.state.fundCount}</strong>
          </p>
        </Col>
        </Row>
        <div>
          <ol>{fundList}</ol>                      
        </div>
      </div>
    );
  }
}

export default App;




// {Array(this.state.fundCount).fill(
//   <Board
//     name = {this.state.name}
//     manager = {this.state.manager}
//     capital = {this.state.investment}
//     feeRate = {this.state.feeRate}
//     paymentCycle = {this.state.paymentCycle}
//   />)
//   }
