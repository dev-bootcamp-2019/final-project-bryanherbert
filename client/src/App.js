import React, { Component } from "react";
import FundMarketplace from "./contracts/FundMarketplace.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";
import { Button, Jumbotron, Row, Col, Form, FormGroup, Label, Input, FormText} from 'reactstrap';

import "./App.css";

class Fund extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      investmentAmount: null,
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleInvestClick = this.handleInvestClick.bind(this);
  }

  handleChange(event) {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value
    });
  }

  handleInvestClick= async(event) => {
    event.preventDefault();
    const { investmentAmount} = this.state;
    const investment = this.props.web3.utils.toWei(investmentAmount.toString(), "ether");
    var feeRate = await this.props.contract.checkFeeRate.call(this.props.fundNum);
    var fee = (investment/feeRate) + 1;
    await this.props.contract.Invest(
      this.props.fundNum, 
      investment,
      { from: this.props.accounts[0], value:fee });
    
    //Update state with result
    this.setState(this.props.setup);
  }

  render(){
    return(
      <div className="fund">
        <h3>{this.props.name} Fund</h3>
        <p>Manager: {this.props.manager}</p>
        <p>Total Capital: {this.props.capital} ether</p>
        <p>Annual Fee Rate: {this.props.feeRate}%</p>
        <p>Payment Cycle: {this.props.paymentCycle} days</p>
        <Form inline className="invest-button">
          <FormGroup>
            <Label for="investButton" hidden></Label>
            <Input type="text" name="investmentAmount" id="investment" placeholder="Ether" onChange={this.handleChange}/>
          </FormGroup>
          {' '}
          <Button color="success" onClick={this.handleInvestClick}>Invest</Button>
        </Form>
      </div>
    );
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
      
      inputName: null, 
      
      inputManager: null,
      
      inputInvestment: null,  
      
      inputFeeRate: null, 
      
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
    //const response = await contract.getFundDetails(count);
    
    //Update state with result
    this.setState(this.setup);
  }


  setup = async () => {
    //Add web3 here
    const { web3, accounts, contract } = this.state;

    //Test for getting the fundCount
    const fundCount = await contract.fundCount();

    //Update state with result
    this.setState({ 
      fundCount: fundCount.toNumber()
    })

    //Populate fundList Array
    if(fundCount > 0){
      for(let i=1; i<=fundCount; i++){
        const response = await contract.getFundDetails(i);
        if(i===1){
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

    const fundList = this.state.fundList;
    const funds = fundList.map((fund, fundNum) => {
      return(
        <Fund key = {fundNum}
          //Could probably just use key but not sure how
          fundNum = {fundNum+1}
          name = {fund.fundName}
          manager = {fund.fundManager}
          capital = {fund.fundInvestment}
          feeRate = {fund.fundFeeRate} 
          paymentCycle = {fund.fundPaymentCycle}
          web3 = {this.state.web3}
          accounts =  {this.state.accounts}
          contract = {this.state.contract}
          setup = {this.setup}
          //handleChange = {(event) => this.handleChange(event)}
          //handleInvestClick = {(event) => this.handleInvestClick(event)}
        />
      );
    })

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
        <div>
          <Row>
              <Col sm="12" md={{ size: 6, offset: 3}}>
                <Form className="fundform" onSubmit={this.handleSubmit}>
                  <h3>Launch a Fund with the form below:</h3>
                  <FormGroup>
                    <Label for="fundNameInput">Fund Name</Label>
                    <Input type="text" name="inputName" id="nameForm" onChange = {this.handleChange}/>
                  </FormGroup>

                  <FormGroup>
                    <Label for="fundInvestmentInput">Initial Investment (in ether)</Label>
                    <Input type = "text" name ="inputInvestment" id="investmentForm" onChange = {this.handleChange}/>
                  </FormGroup>

                  <FormGroup>
                    <Label for="fundFeeRateInput">Annual Management Fee (%)</Label>
                    <Input type = "text" name ="inputFeeRate" id="feeRateForm" onChange = {this.handleChange}/>
                  </FormGroup>

                  <FormGroup>
                    <Label for="fundPaymentCycleInput">Payment Cycle (in days)</Label>
                    <Input type = "text" name ="inputPaymentCycle" id="paymentCycleForm" onChange = {this.handleChange}/>
                  </FormGroup>

                  <FormGroup>
                    <Button type="submit" color="primary">Submit</Button>
                  </FormGroup>
                </Form>
              </Col>
            </Row>
        </div>
        <div>
          <h2>Fund Marketplace</h2>
        </div>
        <div>
          <p>
            Total Fund Count: <strong>{this.state.fundCount}</strong>
          </p>
        </div>
        <div>
          <ol>{funds}</ol>                  
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
