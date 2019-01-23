import React, { Component } from "react";
import FundMarketplace from "./contracts/FundMarketplace.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";
import { Button, Jumbotron, Row, Col, Form, FormGroup, Label, Input, FormText, Table, Modal, ModalHeader, ModalFooter, ModalBody} from 'reactstrap';

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
    const { investmentAmount } = this.state;
    const investment = this.props.web3.utils.toWei(investmentAmount.toString(), "ether");
    var feeRate = await this.props.contract.checkFeeRate.call(this.props.fundNum);
    var fee = (investment/feeRate) + 1;
    await this.props.contract.Invest(
      this.props.fundNum, 
      investment,
      { from: this.props.accounts[0], value:fee });
    
    //Update state with result - not sure this is correct format
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

class FeeModal extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      modal: false
    };
    this.toggle = this.toggle.bind(this);
    this.handleClick = this.handleClick.bind(this);
  }

  toggle() {
    this.setState({
      modal: !this.state.modal
    });
  }

  handleClick = async(event) => {
    event.preventDefault();
    await this.props.contract.collectFees(
      this.props.fundNumber,
      { from: this.props.account }
    );
    //Not sure this is correct format but it works
    this.setState(this.props.setup);
  }

  render() {
    return(
      <div>
        <Button color="success" onClick={this.toggle}>Fees Menu</Button>
        <Modal isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Fees Menu</ModalHeader>
          <ModalBody>
            <p>Available Fees to Collect: {this.props.fees} ether</p>
          </ModalBody>
          <ModalFooter>
            <Button color="success" onClick={this.handleClick}>Collect Fees</Button>
            <Button color="secondary" onClick={this.toggle}>Cancel</Button>
          </ModalFooter>
        </Modal>
      </div>
    );
  }
}

class OrderModal extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      fundNumber: this.props.fundNumber,
      account: this.props.account,
      contract: this.props.contract,
      web3: this.props.web3,
      modal: false,
      action: null,
      ticker: null,
      quantity: null,
      price: null
    };
    this.toggle = this.toggle.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggle() {
    this.setState({
      modal: !this.state.modal
    });
  }

  handleChange(event) {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value
    });
  }

  handleSubmit = async(event) => {
    event.preventDefault();
    const { fundNumber, account, contract, web3, action, ticker, quantity, price } = this.state;
    let finalAction = null;
    if(action === "Buy"){
      finalAction = "buy";
    }
    else if(action === "Sell"){
      finalAction = "sell";
    }
    finalAction = web3.utils.asciiToHex(finalAction);
    const finalTicker = web3.utils.asciiToHex(ticker);
    const finalPrice = web3.utils.toWei(price.toString(), "szabo");

    //Price currently must be in ether
    //figure out conversion
    await contract.placeOrder(
      fundNumber,
      finalAction,
      finalTicker,
      quantity,
      finalPrice,
      { from: account });
    
    //Update state with result
    //Not sure this is correct format but it works
    this.setState(this.props.setup);
    //Close window
    this.toggle();
  }

  render() {
    return(
      <div>
        <Button color="danger" onClick={this.toggle}>Order Menu</Button>
        <Modal isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Order Form</ModalHeader>
          <ModalBody>
            <Form className="orderForm">
              <FormGroup row>
                <Label for="select" sm={2}>Select</Label>
                <Col sm={10}>
                  <Input type="select" name="action" id="actionSelect" onChange={this.handleChange}>
                    <option></option>
                    <option>Buy</option>
                    <option>Sell</option>
                  </Input>
                </Col>
              </FormGroup>
              <FormGroup row>
                <Label for="ticker" sm={2}>Ticker</Label>
                <Col sm={10}>
                  <Input type="text" name="ticker" id="ticker" placeholder="Enter Stock Ticker" onChange={this.handleChange}/>
                </Col>
              </FormGroup>
              <FormGroup row>
                <Label for="quantity" sm={2}>Quantity</Label>
                <Col sm={10}>
                  <Input type="text" name="quantity" id="quantity" placeholder="Enter Number of Shares" onChange={this.handleChange}/>
                </Col>
              </FormGroup>
              <FormGroup row>
                <Label for="price" sm={2}>Price</Label>
                <Col sm={10}>
                  <Input type="text" name="price" id="price" placeholder="Enter Execution Price (in szabo)" onChange={this.handleChange}/>
                </Col>
              </FormGroup>
            </Form>
          </ModalBody>
          <ModalFooter>
            <Button color="danger" onClick={this.handleSubmit}>Place Order</Button>
            <Button color="secondary" onClick={this.toggle}>Cancel</Button>
          </ModalFooter>
        </Modal>
      </div>
    );
  }
}

class FundTableEntry extends React.Component{
  constructor(props){
    super(props);
  }

  render(){
    const fraction = (this.props.capitalDeployed/this.props.totalCapital)*100;
    const rounded = Math.floor(fraction*100)/100;
    return(
      <tr>
        <th scope="row">{this.props.i}</th>
        <td>{this.props.name}</td>
        <td>{this.props.virtualBalance} ether</td>
        <td>{this.props.totalCapital} ether</td>
        <td>{this.props.capitalDeployed} ether ({rounded}%)</td>
        <td>{this.props.feeRate}%</td>
        <td>{this.props.paymentCycle} days</td>
        <td>
          <FeeModal
            fees = {this.props.fees}
            account = {this.props.account}
            contract = {this.props.contract}
            fundNumber = {this.props.fundNumber}
            setup = {this.props.setup}
          />
        </td>
        <td>
          <OrderModal
            account = {this.props.account}
            contract = {this.props.contract}
            fundNumber = {this.props.fundNumber}
            web3 = {this.props.web3}
            setup = {this.props.setup}
          />
        </td>
      </tr>
    );
  }
}

class FundsTable extends React.Component {
  constructor(props){
    super(props);
  }

  render(){
    let i = 0;
    const DisplayFundList = this.props.fundList.map((fund, fundNum) => {
      const owner = fund.fundManager;
      const fundNumber = fundNum+1;    
      if(owner === this.props.account){
        i++;
        return(
          <FundTableEntry
            key = {i}
            i = {i}
            fundNumber = {fundNumber}
            name = {fund.fundName}
            virtualBalance = {fund.fundVirtualBalance}
            totalCapital = {fund.fundInvestment}
            capitalDeployed = {fund.fundCapitalDeployed}
            feeRate = {fund.fundFeeRate}
            paymentCycle = {fund.fundPaymentCycle}
            fees = {fund.fundAvailableFees}
            account = {this.props.account}
            contract = {this.props.contract}
            web3 = {this.props.web3}
            setup = {this.props.setup}
          />
        );
      }else{
      }
    })

    return(
      <div>
        <Table striped>
          <thead>
            <tr>
              <th>#</th>
              <th>Name</th>
              <th>My Balance</th>
              <th>Total Capital</th>
              <th>Capital Deployed</th>
              <th>Fee Rate</th>
              <th>Payment Cycle</th>
              <th>Fees</th>
              <th>Orders</th>
            </tr>
          </thead>
          <tbody>
            {DisplayFundList}
          </tbody>
        </Table>
      </div>
    );
  }
}








class FeeModal2 extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      modal: false,
      feesOwed: null,
      cycleComplete: false
    };
    this.toggle = this.toggle.bind(this);
    this.handleClick = this.handleClick.bind(this);
    this.checkFee = this.checkFee.bind(this);
  }

  toggle() {
    this.setState({
      modal: !this.state.modal,
    });
    if(!this.state.modal){
      this.checkFee();
    }
  }

  handleClick = async(event) => {
    event.preventDefault();
    //hardcoded in 12
    await this.props.contract.payFee(
      this.props.fundNumber,
      12,
      { from: this.props.account }
    );
    //Not sure this is correct format but it works
    this.setState(this.props.setup);
  }

  checkFee = async() => {
    const result = await this.props.contract.checkFee(this.props.fundNumber, 12, { from: this.props.account });
    const feesOwed = this.props.web3.utils.fromWei(result[0].toString(), "ether");
    const cycleComplete = result[1];
    this.setState({
      feesOwed: feesOwed,
      cycleComplete: cycleComplete
    });
  }

  render() {
    let FeeButton;
    if(this.state.cycleComplete){
      FeeButton = (
        <Button color="success" onClick={this.handleClick}>Pay Fees</Button>
      );
    } else{
      FeeButton = (
        <Button color="success" onClick={this.handleClick} disabled>Pay Fees</Button>
      );
    }
    return(
      <div>
        <Button color="success" onClick={this.toggle}>Fees Menu</Button>
        <Modal isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Fees Menu</ModalHeader>
          <ModalBody>
            <p>Fees in Escrow: {this.props.fees} ether</p>
            <p>Fees Owed: {this.state.feesOwed} ether</p>
          </ModalBody>
          <ModalFooter>
            {FeeButton}
            <Button color="secondary" onClick={this.toggle}>Cancel</Button>
          </ModalFooter>
        </Modal>
      </div>
    );
  }
}

class InvestmentTableEntry extends React.Component{
  constructor(props){
    super(props);
  }

  render(){
    const fraction = this.props.capitalDeployed/this.props.totalCapital*100;
    const rounded = Math.floor(fraction*100)/100;
    const balanceDeployed = this.props.virtualBalance * (fraction/100);
    return(
      <tr>
        <th scope="row">{this.props.i}</th>
        <td>{this.props.name}</td>
        <td>{this.props.virtualBalance} ether</td>
        <td>{balanceDeployed} ether ({rounded}%)</td>
        <td>
          <FeeModal2
            //Fees available to pay
            fees = {this.props.fees}
            account = {this.props.account}
            contract = {this.props.contract}
            fundNumber = {this.props.fundNumber}
            web3 = {this.props.web3}
            setup = {this.props.setup}
          />
        </td>
        <td>
          <OrderModal
            account = {this.props.account}
            contract = {this.props.contract}
            fundNumber = {this.props.fundNumber}
            web3 = {this.props.web3}
            setup = {this.props.setup}
          />
        </td>
      </tr>
    );
  }
}

class InvestmentsTable extends React.Component {
  constructor(props){
    super(props);
  }

  render(){
    let i = 0;
    const DisplayInvestmentList = this.props.fundList.map((fund, fundNum) => {
      //const result = this.props.contract.getFundDetails2(fundNum, account);   
      const status = fund.fundInvestorStatus;
      const owner = fund.fundManager 
      const fundNumber = fundNum+1;
      if(status && this.props.account !== owner){
        i++;
        return(
          <InvestmentTableEntry
            key = {i}
            i = {i}
            fundNumber = {fundNumber}
            name = {fund.fundName}
            totalCapital = {fund.fundInvestment}
            capitalDeployed = {fund.fundCapitalDeployed}
            virtualBalance = {fund.fundVirtualBalance}
            feeRate = {fund.fundFeeRate}
            paymentCycle = {fund.fundPaymentCycle}
            fees = {fund.fundAvailableFees}
            account = {this.props.account}
            contract = {this.props.contract}
            web3 = {this.props.web3}
            setup = {this.props.setup}
          />
        );
      }else{
      }
    })

    return(
      <div>
        <Table striped>
          <thead>
            <tr>
              <th>#</th>
              <th>Name</th>
              <th>My Balance</th>
              <th>Balance Deployed</th>
              <th>Fees</th>
              <th>Orders</th>
              <th>Withdraw</th>
            </tr>
          </thead>
          <tbody>
            {DisplayInvestmentList}
          </tbody>
        </Table>
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
          fundCapitalDeployed: null,
          fundFeeRate: null,
          fundPaymentCycle: null,
          fundAvailableFees: null,
          fundInvestorStatus: null,
          fundVirtualBalance: null
        }
      ],

      orderList: [
        {
          fundName: null,
          action: null,
          ticker: null,
          quantity: null,
          price: null,
          completed: null,
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
    //const count = await contract.fundCount();
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
        const response2 = await contract.getFundDetails2(i, accounts[0]);
        if(i===1){
          this.setState({
            fundList: [
              {
                fundName: web3.utils.hexToAscii(response[0]), 
                fundManager: response[1], 
                fundInvestment: web3.utils.fromWei(response[2].toString(), "ether"), 
                fundCapitalDeployed: web3.utils.fromWei(response[3].toString(), "ether"),
                fundFeeRate: response[4].toNumber(), 
                fundPaymentCycle: response[5].toNumber(),
                fundInvestorStatus: response2[0],
                fundVirtualBalance: web3.utils.fromWei(response2[1].toString(), "ether"),
                fundAvailableFees: web3.utils.fromWei(response2[2].toString(), "ether")
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
                  fundCapitalDeployed: web3.utils.fromWei(response[3].toString(), "ether"), 
                  fundFeeRate: response[4].toNumber(), 
                  fundPaymentCycle: response[5].toNumber(),
                  fundInvestorStatus: response2[0],
                  fundVirtualBalance: web3.utils.fromWei(response2[1].toString(), "ether"),
                  fundAvailableFees: web3.utils.fromWei(response2[2].toString(), "ether")
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
      if(this.state.fundCount !== 0) {
        return(
          <Fund key = {fundNum}
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
      }
    })

    //Watch for Order Events
    let web3 = this.state.web3;
    let event = this.state.contract.OrderPlaced({
      filter: {fundNum: 1},
      fromBlock: 0
    })
    .on('data', function(event){
      console.log("Fund Number: "+event.args.fundNum);
      console.log("Action: "+web3.utils.hexToAscii(event.args.action));
      console.log("Ticker: "+web3.utils.hexToAscii(event.args.ticker));
      console.log("Quantity: "+event.args.qty.toNumber());
      console.log("Price: "+web3.utils.fromWei(event.args.price.toString(), "ether"));
    })
    .on('error', console.error);

    return (
      <div className="App">
        <div>
          <Jumbotron>
            <h1 className="display-3">Welcome to Mimic</h1>
            <p className="lead">
            Beat the Markets with the World's Best Managers
            </p>
          </Jumbotron>
        </div>
        <div className="funds-table">
          <h4>My Funds</h4>
          <FundsTable
            account = {this.state.accounts[0]}
            contract = {this.state.contract}
            fundList = {this.state.fundList}
            web3 = {this.state.web3}
            setup = {this.setup}
          />
        </div>
        <div className="funds-table">
          <h4>My Investments</h4>
          <InvestmentsTable
            account = {this.state.accounts[0]}
            contract = {this.state.contract}
            fundList = {this.state.fundList}
            web3 = {this.state.web3}
            setup = {this.setup}
          />
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