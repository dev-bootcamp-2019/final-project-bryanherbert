import React, { Component } from "react";
import FundMarketplace from "./contracts/FundMarketplace.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";
import ipfs from './ipfs';
import { Alert, Button, Jumbotron, Row, Col, Form, FormGroup, Label, Input, FormText, Table, Modal, ModalHeader, ModalFooter, ModalBody, TabContent, TabPane, Nav, NavItem, NavLink} from 'reactstrap';
import classnames from 'classnames';
import "./App.css";
import bs58 from 'bs58';

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
    //Add 1% for rounding
    var fee = 1.01*(investment/feeRate);
    await this.props.contract.Invest(
      this.props.fundNum, 
      investment,
      { from: this.props.accounts[0], value:fee });
    
    //Update state with result - not sure this is correct format
    this.setState(this.props.setup);
  }

  render(){
    const fundraising = this.props.fundraising;
    let investment;
    if(fundraising){
      investment = (
        <Form inline className="invest-button">
          <FormGroup>
            <Label for="investButton" hidden></Label>
            <Input type="text" name="investmentAmount" id="investment" placeholder="Ether" onChange={this.handleChange}/>
          </FormGroup>
          {' '}
          <Button color="success" onClick={this.handleInvestClick}>Invest</Button>
        </Form>
      );
    }else{
      investment = (
      <Alert color="secondary">
        Fundraising Period Ended
      </Alert>
      );
    }
    return(
      <div className="fund">
        <h3>{this.props.name} Fund</h3>
        <p>Manager: {this.props.manager}</p>
        <p>Total Capital: {this.props.capital} ether</p>
        <p>Annual Fee Rate: {this.props.feeRate}%</p>
        <p>Payment Cycle: {this.props.paymentCycle} days</p>
        <div className="ipfs-button">
          <a href={this.props.ipfsURL} className="ipfs-button" target="_blank">View Prospectus</a>
        </div>
        {investment}
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
    //Close Window
    this.toggle();
  }

  render() {
    return(
      <div>
        <Button color="primary" onClick={this.toggle}>Fees Menu</Button>
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

class OrderTableEntry2 extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      newQuantity: null,
    };
    this.calcQty = this.calcQty.bind(this);
  }

  calcQty = async(quantity) => {
    let result = await this.props.contract.calcQty(this.props.fundNumber, quantity, { from: this.props.account });
    let newQty = result.toNumber();
    this.setState({
      newQuantity: newQty
    });
  }

  render(){
    this.calcQty(this.props.quantity);
    return(
      <tr>
        <th scope="row">{this.props.i}</th>
        <td>{this.props.action}</td>
        <td>{this.props.ticker}</td>
        <td>{this.state.newQuantity}</td>
        <td>{this.props.quantity}</td>
        <td>{this.props.price} ether</td>
        <td>{this.props.blockNumber}</td>
      </tr>
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
      price: null,
      activeTab: '1'
    };
    this.toggle = this.toggle.bind(this);
    this.toggleTab = this.toggleTab.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggle() {
    this.setState({
      modal: !this.state.modal
    });
  }

  toggleTab(tab){
    if(this.state.activeTab !== tab){
      this.setState({
        activeTab: tab
      });
    }
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
    let i = 0;
    const DisplayOrderList = this.props.orderList.map((order, orderNum) => { 
      if(order.fundNum==this.state.fundNumber){
        i++;
        return(
          <OrderTableEntry2
            key = {i}
            i = {i}
            fundNumber = {order.fundNum}
            action = {order.action}
            ticker = {order.ticker}
            quantity = {order.quantity}
            price = {order.price}
            blockNumber = {order.blockNumber}
            account = {this.props.account}
            contract = {this.props.contract}
          />
        );
      }else{
      }
    })
    return(
      <div>
        <Button color="success" onClick={this.toggle}>Order Menu</Button>
        <Modal className="modal-lg" isOpen={this.state.modal} toggle={this.state.toggle}>
          <Nav tabs>
            <NavItem>
              <NavLink
                className={classnames({ active: this.state.activeTab === '1'})}
                onClick={() => { this.toggleTab('1'); }}
              >
                New Order
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink
                className={classnames({ active: this.state.activeTab === '2'})}
                onClick={() => { this.toggleTab('2'); }}
              >
                Past Orders
              </NavLink>
            </NavItem>
          </Nav>
          <TabContent activeTab={this.state.activeTab}>
            <TabPane tabId="1">
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
            </TabPane>
            <TabPane tabId="2">
              <ModalHeader toggle={this.toggle}>Received Orders</ModalHeader>
              <div>
                <Table striped>
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Action</th>
                      <th>Ticker</th>
                      <th>My Quantity (shares)</th>
                      <th>Total Quantity (shares)</th>
                      <th>Price (/share)</th>
                      <th>Block Number</th>
                    </tr>
                  </thead>
                  <tbody>
                    {DisplayOrderList}
                  </tbody>
                </Table>
              </div>  
            </TabPane>
          </TabContent>
        </Modal>
      </div>
    );
  }
}

class CloseModal extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      modal: false,
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

    await this.props.contract.closeFund(
      this.props.fundNumber,
      { from: this.props.account }
    );
    //Not sure this is correct format but it works
    this.setState(this.props.setup);
    //Close Window
    this.toggle();
  }

  render() {
    return(
      <div>
        <Button color="danger" onClick={this.toggle}>Close Fund</Button>
        <Modal isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Are you sure you want to close this fund?</ModalHeader>
          <ModalBody>
            <Alert color="danger">
              A fund closure is permanent and will result in a loss of all data and fees!
            </Alert>
          </ModalBody>
          <ModalFooter>
            <Button color="danger" onClick={this.handleClick}>Yes</Button>
            <Button color="secondary" onClick={this.toggle}>No</Button>
          </ModalFooter>
        </Modal>
      </div>
    );
  }
}

class FundModal extends React.Component{
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
    await this.props.contract.endFundraising(
      this.props.fundNumber,
      { from: this.props.account }
    );
    //Not sure this is correct format but it works
    this.setState(this.props.setup);
    //Close Window
    this.toggle();
  }

  render() {
    let status;
    let endFundraising;
    if(this.props.fundraising){
      status = "Active";
      endFundraising = (
        <Button color="danger" onClick={this.handleClick}>End Fundraising Period</Button>
      );
    } else{
      status = "Ended";
    }
    return(
      <div>
        <Button color="info" onClick={this.toggle}>Fund Menu</Button>
        <Modal isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Fund Management Menu</ModalHeader>
          <ModalBody>
            <p>Fee Rate: {this.props.feeRate}%</p>
            <p>Payment Cycle: {this.props.paymentCycle} days</p>
            <div className="ipfs-button">
              <a href={this.props.ipfsURL} class="ipfs-button" target="_blank">View Prospectus</a>
            </div>
            <p>Fundraising Period: {status} </p>
            {endFundraising}
          </ModalBody>
          <ModalFooter>
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
    const capDepRounded = Math.floor(this.props.capitalDeployed*100)/100;
    return(
      <tr>
        <th scope="row">{this.props.i}</th>
        <td>{this.props.name}</td>
        <td>{this.props.virtualBalance} ether</td>
        <td>{this.props.totalCapital} ether</td>
        <td>{capDepRounded} ether ({rounded}%)</td>
        <td>
          <FundModal
            feeRate = {this.props.feeRate}
            paymentCycle = {this.props.paymentCycle}
            contract = {this.props.contract}
            account = {this.props.account}
            fundNumber = {this.props.fundNumber}
            setup = {this.props.setup}
            fundraising = {this.props.fundraising}
            ipfsURL = {this.props.ipfsURL}
          />
        </td>
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
            orderList = {this.props.orderList}
          />
        </td>
        <td>
          <CloseModal
            account = {this.props.account}
            contract = {this.props.contract}
            fundNumber = {this.props.fundNumber}
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
      if(owner === this.props.account && !fund.fundClosed){
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
            fundraising = {fund.fundFundraising}
            ipfsURL = {fund.fundIpfsURL}
            account = {this.props.account}
            contract = {this.props.contract}
            web3 = {this.props.web3}
            setup = {this.props.setup}
            orderList = {this.props.orderList}
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
              <th>Fund Management</th>
              <th>Fees</th>
              <th>Orders</th>
              <th>Closures</th>
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

class WithdrawModal extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      modal: false,
      withdrawAmount: null
    };
    this.toggle = this.toggle.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.handleClick = this.handleClick.bind(this);
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

  handleClick = async(event) => {
    event.preventDefault();
    const amount = this.state.withdrawAmount;
    const withdrawal = this.props.web3.utils.toWei(amount.toString(), "ether");

    await this.props.contract.withdrawFunds(
      this.props.fundNumber,
      withdrawal,
      { from: this.props.account }
    );
    //Not sure this is correct format but it works
    this.setState(this.props.setup);
  }

  render() {
    return(
      <div>
        <Button color="danger" onClick={this.toggle}>Withdraw</Button>
        <Modal isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Are you sure you want to withdraw your funds?</ModalHeader>
          <ModalBody>
            <p>Current Virtual Balance: {this.props.virtualBalance} ether</p>
            <p>Current Unpaid Fees: {this.props.fees} ether</p>
            {/* <Alert color="danger">
              A full withdrawal will result in loss of all unpaid fees!
            </Alert> */}
            <Form inline className="withdraw-button">
              <FormGroup>
                <Label for="withdrawButton" hidden></Label>
                <Input type="text" name="withdrawAmount" id="withdrawal" placeholder="Ether" onChange={this.handleChange}/>
              </FormGroup>
              {' '}
              <Button color="danger" onClick={this.handleClick}>Withdraw</Button>
            </Form>
          </ModalBody>
        </Modal>
      </div>
    );
  }
}

class OrderTableEntry extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      newQuantity: null,
    };
    this.calcQty = this.calcQty.bind(this);
  }

  calcQty = async(quantity) => {
    let result = await this.props.contract.calcQty(this.props.fundNumber, quantity, { from: this.props.account });
    let newQty = result.toNumber();
    this.setState({
      newQuantity: newQty
    });
  }

  render(){
    this.calcQty(this.props.quantity);
    return(
      <tr>
        <th scope="row">{this.props.i}</th>
        <td>{this.props.action}</td>
        <td>{this.props.ticker}</td>
        <td>{this.state.newQuantity}</td>
        <td>{this.props.price} ether</td>
        <td>{this.props.blockNumber}</td>
      </tr>
    );
  }
}

class OrderModal2 extends React.Component{
  constructor(props){
    super(props);
    this.state = {
      modal: false
    };
    this.toggle = this.toggle.bind(this);
  }

  toggle() {
    this.setState({
      modal: !this.state.modal
    });
  }

  render() {
    let i = 0;
    const DisplayOrderList = this.props.orderList.map((order, orderNum) => { 
      if(order.fundNum==this.props.fundNumber){
        i++;
        return(
          <OrderTableEntry
            key = {i}
            i = {i}
            fundNumber = {order.fundNum}
            action = {order.action}
            ticker = {order.ticker}
            quantity = {order.quantity}
            price = {order.price}
            blockNumber = {order.blockNumber}
            account = {this.props.account}
            contract = {this.props.contract}
          />
        );
      }else{
      }
    })

    return(
      <div>
        <Button color="success" onClick={this.toggle}>Order Menu</Button>
        <Modal className="modal-lg" isOpen={this.state.modal} toggle={this.state.toggle}>
          <ModalHeader toggle={this.toggle}>Received Orders</ModalHeader>
          <div>
            <Table striped>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Action</th>
                  <th>Ticker</th>
                  <th>Quantity (shares)</th>
                  <th>Price (/share)</th>
                  <th>Block Number</th>
                </tr>
              </thead>
              <tbody>
                {DisplayOrderList}
              </tbody>
            </Table>
          </div>  
        </Modal>
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
        <Button color="primary" onClick={this.toggle}>Fees Menu</Button>
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
    const balDepRounded = Math.floor(balanceDeployed*100)/100;
    return(
      <tr>
        <th scope="row">{this.props.i}</th>
        <td>{this.props.name}</td>
        <td>{this.props.virtualBalance} ether</td>
        <td>{balDepRounded} ether ({rounded}%)</td>
        <td>
          <div className="ipfs-button">
            <a href={this.props.ipfsURL} class="ipfs-button" target="_blank">View Prospectus</a>
          </div>  
        </td>
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
          <OrderModal2
            account = {this.props.account}
            contract = {this.props.contract}
            fundNumber = {this.props.fundNumber}
            web3 = {this.props.web3}
            setup = {this.props.setup}
            orderList = {this.props.orderList}
          />
        </td>
        <td>
          <WithdrawModal
            fees = {this.props.fees}
            virtualBalance = {this.props.virtualBalance}
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
      const owner = fund.fundManager;
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
            ipfsURL = {fund.fundIpfsURL}
            account = {this.props.account}
            contract = {this.props.contract}
            web3 = {this.props.web3}
            setup = {this.props.setup}
            orderList  = {this.props.orderList}
          />
        );
      }else{
      }
    })

    const DisplayWarningsList = this.props.fundList.map((fund, fundNum) => {
      const closed = fund.fundClosed;
      const status = fund.fundInvestorStatus;
      const owner = fund.fundManager;
      if(closed && status && this.props.account !== owner){
        return(
          <Alert color="danger">
            {fund.fundName} Fund has been closed. 
            Please withdraw your total balance to retrieve your refunded management fee.
          </Alert>
        );
      } else{
      }
    })

    return(
      <div>
        {DisplayWarningsList}
        <Table striped>
          <thead>
            <tr>
              <th>#</th>
              <th>Name</th>
              <th>My Balance</th>
              <th>Balance Deployed</th>
              <th>Prospectus</th>
              <th>Fees</th>
              <th>Orders</th>
              <th>Withdrawals</th>
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
          fundVirtualBalance: null,
          fundFundraising: null,
          fundClosed: null,
          fundInvestorList: null,
          fundIpfsURL: null
        }
      ],

      orderList: [
        {
          fundNum: null,
          action: null,
          ticker: null,
          quantity: null,
          price: null,
          blockNumber: null,
        }
      ],
      
      inputName: null, 
      
      inputManager: null,
      
      inputInvestment: null,  
      
      inputFeeRate: null, 
      
      inputPaymentCycle: null, 
      
      fundCount: null, 

      ipfsHash: null,

      formErrors: {
          name: '',
          investment: '',
          fee: '',
          paymentCycle: '',
          file: '',
      },

      nameValid: false,
      investmentValid: false,
      feeValid: false,
      paymentCycleValid: false,
      fileValid: false,
      formValid: false,
      
      web3: null, 
      accounts: null, 
      contract: null,
    };
    
    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.multiHashBreakdown = this.multiHashBreakdown.bind(this);
    this.bytes2multihash = this.bytes2multihash.bind(this);
    this.validateField = this.validateField.bind(this);
    this.validateForm = this.validateForm.bind(this);
    this.validateFile = this.validateFile.bind(this);
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

  //turns file into a buffer
  captureFile = (event) => {
    event.stopPropagation();
    event.preventDefault();
    const file = event.target.files[0];
    let reader = new window.FileReader();
    reader.readAsArrayBuffer(file)
    reader.onloadend = () => this.convertToBuffer(reader);
  };
  //helper function
  convertToBuffer = async(reader) => {
    const buffer = await Buffer.from(reader.result);
    this.setState({buffer});
  };

  //sends buffer to ipfs node and sends ipfs to ui
  onIPFSSubmit = async (event) => {
    event.preventDefault();
    await ipfs.add(this.state.buffer, (err, ipfsHash) => {
      console.log(err, ipfsHash);
      this.setState({ ipfsHash: ipfsHash[0].hash }, this.validateFile());
    })
  };


  handleChange(event) {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value
    },
    () => {this.validateField(name, value)}
    );
  }

  multiHashBreakdown(str){
    const decoded = bs58.decode(str);

    return {
      IPFSHash: `0x${decoded.slice(2).toString('hex')}`,
      hash_function: decoded[0],
      size: decoded[1]
    }
  }

  handleSubmit = async (event) => {
    event.preventDefault();
    const { web3, accounts, contract, inputName, inputInvestment, inputFeeRate, inputPaymentCycle, ipfsHash } = this.state;
    const name = web3.utils.asciiToHex(inputName);
    const manager = accounts[0];
    let amount = inputInvestment;
    let investment = web3.utils.toWei(amount.toString(), "ether");
    let feeRate = inputFeeRate;
    let paymentCycle = inputPaymentCycle;
    let result = await this.multiHashBreakdown(ipfsHash);
    let hash_function = result.hash_function;
    let size = result.size;
    let IPFSHash = result.IPFSHash;

    await contract.initializeFund(name, 
      manager, 
      investment, 
      feeRate, 
      paymentCycle,
      IPFSHash,
      hash_function,
      size,
      { from: manager });
    
    //Update state with result
    this.setState(this.setup);
  }

  /** @dev Encodes the three parts of the multihash structure into a base58 encoded multihash string
   * @param {ipfsHash} ipfsHash 32-byte hexadecimal representation of ipfsHash digest
   * @param {hash_function} type of hash_function used for encoding
   * @param {size} of the length of the digest
   * @returns {multihash} encoded multihash string 
   */
  bytes2multihash(ipfsHash, hash_function, size){
    if(size === 0){
      return null;
    }

    //Chop off 0x
    const hBytes = Buffer.from(ipfsHash.slice(2), "hex");

    //construct multihash
    const mhBytes = new (hBytes.constructor)(2+hBytes.length);
    mhBytes[0] = hash_function;
    mhBytes[1] = size;
    mhBytes.set(hBytes,2);

    return bs58.encode(mhBytes);
  }

  validateField(fieldName, value) {
    let fieldValidationErrors = this.state.formErrors;
    let nameValid = this.state.nameValid;
    let investmentValid = this.state.investmentValid;
    let feeValid = this.state.feeValid;
    let paymentCycleValid = this.state.paymentCycleValid;
    let fileValid = this.state.fileValid;

    switch(fieldName) {
      case 'inputName':
        //Name must be more than zero characters
        nameValid = value.length >= 1;
        fieldValidationErrors.name = nameValid ? '' : ' is invalid';
        break;
      case 'inputInvestment':
        //Only accept integers
        investmentValid = value.match(/^[0-9]+$/) && !isNaN(value);
        fieldValidationErrors.investment = investmentValid ? '' : ' is invalid';
        break;
      case 'inputFeeRate':
        //Only accepts integers less than or equal to 20
        feeValid = value.match(/^[0-9]+$/) && !isNaN(value) && value <= 20;
        fieldValidationErrors.fee = feeValid ? '' : ' is invalid';
        break;
      case 'inputPaymentCycle':
        //Only accepts integers less than or equal to 365
        paymentCycleValid = value.match(/^[0-9]+$/) && !isNaN(value) && value <= 365;
        fieldValidationErrors.paymentCycle = paymentCycleValid ? '' : ' is invalid';
        break;
      default:
        break;
    }

    //Make sure ipfsHash exists
    if(this.state.ipfsHash){
      fileValid = true;
    }

    this.setState({
      formErrors: fieldValidationErrors,
      nameValid: nameValid,
      investmentValid: investmentValid,
      feeValid: feeValid,
      paymentCycleValid: paymentCycleValid,
      fileValid: fileValid
    }, this.validateForm);
  }

  validateFile() {
    this.setState({
      formValid: true
    }, this.validateForm);
  }

  validateForm() {
    this.setState({formValid: 
      this.state.nameValid 
      && this.state.investmentValid 
      && this.state.feeValid 
      && this.state.paymentCycleValid 
      && this.state.ipfsHash});
  }

  setup = async () => {
    //Add web3 here
    const { web3, accounts, contract } = this.state;

    //Test for getting the fundCount
    let fundCount = await contract.fundCount()
    fundCount = fundCount.toNumber();
    let lifetimeCount = await contract.lifetimeCount();
    lifetimeCount = lifetimeCount.toNumber();

    //Update state with result
    this.setState({ 
      fundCount: fundCount
    })

    //Populate fundList Array
    if(fundCount > 0){
      for(let i=1; i<=lifetimeCount; i++){
        const response = await contract.getFundDetails(i);
        const response2 = await contract.getFundDetails2(i, accounts[0]);
        const response3 = await contract.checkFundStatus(i);
        const response4 = await contract.getIpfsHash(i);

        //Encode  Multihash structure
        let multihash = this.bytes2multihash(response4[0], response4[1], response4[2]);
        let investProspURL = "https://gateway.ipfs.io/ipfs/"+multihash;

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
                fundAvailableFees: web3.utils.fromWei(response2[2].toString(), "ether"),
                fundFundraising: response3[0],
                fundClosed: response3[1],
                fundInvestorList: response3[2],
                fundIpfsURL: investProspURL
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
                  fundAvailableFees: web3.utils.fromWei(response2[2].toString(), "ether"),
                  fundFundraising: response3[0],
                  fundClosed: response3[1],
                  fundInvestorList: response3[2],
                  fundIpfsURL: investProspURL
                }
              ])
            });
          }
      };
    };

    //Watch for Order Events
    let i = 0;

    let updateState = (event) => {

      const tempOrderList = this.state.orderList;
      if(i===0){
        i++;
        this.setState({
          orderList: [
            {
              fundNum: event.args.fundNum,
              action: web3.utils.hexToAscii(event.args.action),
              ticker: web3.utils.hexToAscii(event.args.ticker),
              quantity: event.args.qty.toNumber(),
              price: web3.utils.fromWei(event.args.price.toString(), "ether"),
              blockNumber: event.blockNumber
            }
          ]
        });
      } else{
        this.setState({
          orderList: tempOrderList.concat([
            {
              fundNum: event.args.fundNum,
              action: web3.utils.hexToAscii(event.args.action),
              ticker: web3.utils.hexToAscii(event.args.ticker),
              quantity: event.args.qty.toNumber(),
              price: web3.utils.fromWei(event.args.price.toString(), "ether"),
              blockNumber: event.blockNumber
            }
          ])
        });
      }
    }

    let event = this.state.contract.OrderPlaced({
      //Want all the orders
      //filter: {fundNum: 1},
      fromBlock: 0
    })
    .on('data', function(event){
      updateState(event);
    })
    .on('error', console.error);
  };

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    const fundList = this.state.fundList;
    const funds = fundList.map((fund, fundNum) => {
      if(this.state.fundCount !== 0 && !fund.fundClosed) {
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
            fundraising = {fund.fundFundraising}
            ipfsURL = {fund.fundIpfsURL}
            //handleChange = {(event) => this.handleChange(event)}
            //handleInvestClick = {(event) => this.handleInvestClick(event)}
          />
        );
      }
    })

    const fE = this.state.formErrors;
    const fEArr = [fE.name, fE.investment, fE.fee, fE.paymentCycle, fE.file];
    const displayFormErrors = fEArr.map((fieldErrors, i) => {
      let fieldLabel = null;
      switch(i){
        case 0:
          fieldLabel = "Fund Name";
          break;
        case 1:
          fieldLabel = "Investment";
          break;
        case 2:
          fieldLabel = "Fee Rate";
          break;
        case 3:
          fieldLabel = "Payment Cycle";
          break;
        default:
          fieldLabel = "File";
      }
      if(fEArr[i].length > 0){
        return(
          <p key={i} className="error-message"><strong>{fieldLabel} {fieldErrors}</strong></p>
        )
      } else {
        return '';
      }
    });

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
        <div>
          <p>Current Account is <strong>{this.state.accounts[0]}</strong></p>
        </div>
        <div className="funds-table">
          <h4>My Funds</h4>
          <FundsTable
            account = {this.state.accounts[0]}
            contract = {this.state.contract}
            fundList = {this.state.fundList}
            web3 = {this.state.web3}
            setup = {this.setup}
            orderList = {this.state.orderList}
          />
        </div>
        <div className="funds-table">
          <h4>My Investments</h4>
          <InvestmentsTable
            account = {this.state.accounts[0]}
            contract = {this.state.contract}
            fundList = {this.state.fundList}
            orderList = {this.state.orderList}
            web3 = {this.state.web3}
            setup = {this.setup}
          />
        </div>
        <div>
          <Row>
              <Col sm="12" md={{ size: 6, offset: 3}}>
                <Form className="fundform" onSubmit={this.handleSubmit}>
                  <h3>Launch a Fund with the form below:</h3>          
                  {displayFormErrors}
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
                      <Label for ="ipfsSubmission">Investment Prospectus</Label>
                      <Input type="file" onChange={this.captureFile}/>
                  </FormGroup>

                  <Button color="secondary" onClick={this.onIPFSSubmit}>Upload Prospectus</Button>

                  <p className='ipfs-result'>The IPFS hash is {this.state.ipfsHash}</p>

                  <FormGroup>
                    <Button type="submit" color="primary" disabled={!this.state.formValid}>Submit</Button>
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