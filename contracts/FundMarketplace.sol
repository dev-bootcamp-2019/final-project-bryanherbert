pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../contracts/InitLib.sol";
import "../contracts/InvestLib.sol";
import "../contracts/Misc.sol";
import "../contracts/PayFeeLib.sol";
import "../contracts/CollectFeesLib.sol";
import "../contracts/WithdrawFundsLib.sol";

contract FundMarketplace {
    //State Variables
    address internal admin;
    StructLib.Data funds;
    uint fundCount;

    //Events
    event FundCreated(
        bytes32 name,
        uint fundCount,
        address fundOwner
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

    event FundsWithdrawn(
        bytes32 name,
        address investor,
        uint investment,
        uint fees
    );

    constructor() public {
        admin = msg.sender;
    }

    //Modifiers

    // //Can replace this with ethpm code
    // modifier isOwner(bytes32 _name){
    //     address _fundOwner;
    //     (,_fundOwner,,) = getFundDetails(_name);
    //     require(
    //         _fundOwner == msg.sender,
    //         "Message Sender does not own strategy"
    //     );
    //     _;
    // }

    function initializeFund(bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) 
    external payable {
        InitLib.initializeFund(funds, _name, _fundOwner, _investment, _feeRate, _paymentCycle);
        //Increment fundCount
        fundCount++;
        emit FundCreated(_name, fundCount, _fundOwner);
    }

    //Check to see if an account is an investor in a strategy
    //eventually change to only one parameter and use delegate call instead
    function isInvestor(bytes32 _name, address _investor) public view returns (bool) {
        bool result;
        (,result,,) = getFundDetails2(_name, _investor);
        return result;
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(bytes32 _name, uint _investment) 
    external payable  
    {
        InvestLib.Invest(funds, _name, _investment, msg.sender, msg.value);
        emit Investment(_name, msg.sender, _investment);
    }

    //check Fee Rate - read operation from struct
    //was originally "public view" when not in library
    function checkFeeRate(bytes32 _name) public view returns (uint) {
        return Misc.checkFeeRate(funds, _name);
    }

    //One-time pay fee function
    function payFee(bytes32 _name, uint _timePeriod) external
    {
        PayFeeLib.payFee(funds, _name, _timePeriod);
        uint payment = (funds.list[_name].virtualBalances[msg.sender]/checkFeeRate(_name))/_timePeriod;
        emit FeesPaid (_name, msg.sender, payment);
    }

    function checkPaymentCycleStart(bytes32 _name, address _investor) public view
    returns (uint)
    {
        return funds.list[_name].paymentCycleStart[_investor];
    }

    //Owner of Strategy Collects Fees
    function collectFees(bytes32 _name) external
    //isOwner(_name)
    {
        uint fees = CollectFeesLib.collectFees(funds, _name, msg.sender);
        emit FeesCollected(_name, fees);
    }

    function withdrawFunds(bytes32 _name) public
    //verifyInvestmentStatus(_name) 
    {
        //Need to make sure this matches up with withdraw philosophy
        uint investment;
        uint fees;
        (investment, fees) = WithdrawFundsLib.withdrawFunds(funds, _name, msg.sender);
        emit FundsWithdrawn(_name, msg.sender, investment, fees);
    }

    //Get fund information (for testing/verification purposes)
    function getFundDetails(bytes32 _name) public view returns (bytes32, address, uint, uint){
        return (funds.list[_name].name, 
        funds.list[_name].fundOwner, 
        funds.list[_name].totalBalance, 
        funds.list[_name].feeRate);
    }
    //need two functions because of stack height
    function getFundDetails2(bytes32 _name, address _addr) public view returns (uint, bool, uint, uint){
        return(funds.list[_name].paymentCycle,
        funds.list[_name].investors[_addr], 
        funds.list[_name].virtualBalances[_addr],
        funds.list[_name].fees[_addr]);
    }
}