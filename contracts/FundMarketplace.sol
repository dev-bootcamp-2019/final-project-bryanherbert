pragma solidity ^0.4.24;

import "../contracts/FundList.sol";

contract FundMarketplace {
    //State Variables
    address admin;
    //FundList Contract
    FundList fl;

    //Events
    event FundCreated(
        bytes32 name,
        uint fundCount,
        address stratOwner
    );

    event Investment(
        bytes32 name,
        address investor,
        uint investment
    );
    
    event FeesPaid(
        bytes32 name,
        address investor,
        uint fee
    );

    event FeesCollected(
        bytes32 name,
        uint fee
    );

    // event FundsWithdrawn(
    //     bytes32 name,
    //     address investor,
    //     uint investment,
    //     uint fees
    // );

    //Modifiers
    modifier verifyBalance(bytes32 _name, uint _investment){
        //Account Balance must be greater than investment + Fees
        //Not sure this correct- want it to represent ~2%
        uint fee = _investment/fl.checkFeeRate(_name);
        require(
            msg.sender.balance > _investment + fee,
            "Sender does not have enough balance to invest"
        );
        _;
    }

    modifier verifyFee(bytes32 _name, uint _investment, uint _proposedFee) {
        //Verify that the msg.value > fee
        require(
            _proposedFee >= _investment/fl.checkFeeRate(_name),
            "Fee is insufficent"
        );
        _;
    }

    modifier checkFeePayment(bytes32 _name, uint _timePeriod) {
        uint virtualBalance;
        uint fees;
        //Get investor's virtual balance and fees deposited
        (,,virtualBalance,fees) = fl.getFundDetails2(_name, msg.sender);
        uint payment = (virtualBalance/fl.checkFeeRate(_name))/_timePeriod;
        require(
            //Check that msg.sender has enough in fees to make payment installment
            fees > payment,
            "Fee balance is insufficient to make payment or payment cycle is not complete"
        );
        _;
    }

    modifier verifyInvestmentStatus(bytes32 _name){
        //check that msg.sender is an investor
        require(
            fl.isInvestor(_name, msg.sender) == true,
            "Message Sender is not an investor"
        );
        _;
    }

    //Can replace this with ethpm code
    modifier isOwner(bytes32 _name){
        address _fundOwner;
        (,_fundOwner,,) = fl.getFundDetails(_name);
        require(
            _fundOwner == msg.sender,
            "Message Sender does not own strategy"
        );
        _;
    }

    modifier cycleComplete(bytes32 _name){
        uint paymentCycleStart = fl.checkPaymentCycleStart(_name, msg.sender);
        uint paymentCycle;
        (paymentCycle,,,) = fl.getFundDetails2(_name, msg.sender);

        require(
            now >= paymentCycleStart + paymentCycle * 1 days,
            "Cycle is not complete, no fee due"
        );
        _;
    }

    constructor() public {
        admin = msg.sender;
        //Need to initialize a new contract instance of FundList
        //Attempt may be wrong
        fl = new FundList();
    }

    function getFundList() public view returns (FundList) {
        return fl;
    }

    function initializeFund(bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) public payable {
        bytes32 fundName;
        uint fundCount;
        address fundOwner;
        (fundName, fundCount, fundOwner) = fl.initializeFund(_name, _fundOwner, _investment, _feeRate, _paymentCycle);
        //Emit Event
        emit FundCreated(fundName, fundCount, fundOwner);
    }


    //Make investment into particular fund
    //Must have required funds
    function Invest(bytes32 _name, uint _investment) public payable 
    verifyBalance(_name, _investment) 
    verifyFee(_name, _investment, msg.value) {
        bytes32 fundName;
        address newInvestor;
        uint newInvestment;
        (fundName, newInvestor, newInvestment) = fl.Invest.value(msg.value)(_name, _investment, msg.sender);
        //Emit event
        emit Investment(_name, msg.sender, _investment);
    }


    //One-time pay fee function
    function payFee(bytes32 _name, uint _timePeriod) public
    verifyInvestmentStatus(_name)
    checkFeePayment(_name, _timePeriod)
    cycleComplete(_name)
    {
        bytes32 fundName;
        address investor;
        uint feePayment;
        (fundName, investor, feePayment) = fl.payFee(_name, _timePeriod, msg.sender);
        emit FeesPaid(fundName, investor, feePayment);
    }

    //Owner of Strategy Collects Fees
    function collectFees(bytes32 _name) public
    isOwner(_name)
    {
        uint feesCollected = fl.collectFees(_name, msg.sender);
        emit FeesCollected(_name, feesCollected);
    }
/*
    function withdrawFunds(bytes32 _name) public
    verifyInvestmentStatus(_name) 
    {
        //Need to make sure this matches up with withdraw philosophy
        //Temporary Balance and Fees
        uint bal = strategies[_name].virtualBalances[msg.sender];
        uint fees = strategies[_name].fees[msg.sender];
        //subtract virtual balance from total funds
        strategies[_name].funds -= bal;
        //zero out virtual Balance
        strategies[_name].virtualBalances[msg.sender] = 0;
        //transfer fees back to investor
        msg.sender.transfer(fees);
        //Zero out fees
        strategies[_name].fees[msg.sender] = 0;
        //set investor status to faslse
        strategies[_name].investors[msg.sender] = false;
        emit FundsWithdrawn(_name, msg.sender, bal, fees);
    }
*/
}