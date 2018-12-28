pragma solidity ^0.4.24;

import "../contracts/FundList.sol";

contract FundMarketplace {
    //State Variables
    address internal admin;
    //FundList Contract
    FundList fl;

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
        fl = new FundList();
    }

    //Both initializes and returns address of a new Fundlist()- for gas purposes
    function getFundList() external view returns (FundList) {
        return fl;
    }

    function initializeFund(bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) 
    external payable {
        fl.initializeFund(_name, _fundOwner, _investment, _feeRate, _paymentCycle);
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(bytes32 _name, uint _investment) 
    external payable 
    verifyBalance(_name, _investment) 
    verifyFee(_name, _investment, msg.value) 
    {
        fl.Invest.value(msg.value)(_name, _investment, msg.sender);
    }

    //One-time pay fee function
    function payFee(bytes32 _name, uint _timePeriod) external
    verifyInvestmentStatus(_name)
    checkFeePayment(_name, _timePeriod)
    cycleComplete(_name)
    {
        fl.payFee(_name, _timePeriod, msg.sender);
    }

    //Owner of Strategy Collects Fees
    function collectFees(bytes32 _name) external
    isOwner(_name)
    {
        fl.collectFees(_name, msg.sender);
    }

    function withdrawFunds(bytes32 _name) public
    verifyInvestmentStatus(_name) 
    {
        //Need to make sure this matches up with withdraw philosophy
        fl.withdrawFunds(_name, msg.sender);
    }
}