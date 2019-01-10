pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../contracts/InitLib.sol";
import "../contracts/InvestLib.sol";
import "../contracts/Misc.sol";
import "../contracts/PayFeeLib.sol";
import "../contracts/CollectFeesLib.sol";
import "../contracts/WithdrawFundsLib.sol";
import "../contracts/OrderLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FundMarketplace {
    //State Variables
    address internal admin;
    StructLib.Data funds;
    uint public fundCount;

    //Events
    event FundCreated(
        uint indexed fundNum,
        bytes32 name,
        //have to think about how to search for value vs. how to see it
        //Probably can still index name, just can't check for it in JS
        //bytes32 name,
        address fundOwner
    );

    event Investment(
        uint indexed fundNum,
        address indexed investor,
        // uint fundNum,
        // address investor,
        uint investment
    );
    
    event FeesPaid(
        uint indexed fundNum,
        address indexed investor,
        // uint fundNum,
        // address investor,
        uint fee
    );

    event FeesCollected(
        uint indexed fundNum,
        uint fee
    );

    event FundsWithdrawn(
        //uint fundNum,,
        uint indexed fundNum,
        address investor,
        uint investment,
        uint fees
    );

    event OrderPlaced(
        uint indexed fundNum,
        bytes action,
        bytes32 ticker,
        uint qty,
        uint price
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
        InitLib.initializeFund(funds, fundCount, _name, _fundOwner, _investment, _feeRate, _paymentCycle);
        //Increment fundCount
        fundCount++;
        emit FundCreated(fundCount, _name, _fundOwner);
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(uint _fundNum, uint _investment) 
    external payable  
    {
        InvestLib.Invest(funds, _fundNum, _investment, msg.sender, msg.value);
        emit Investment(_fundNum, msg.sender, _investment);
    }

    //Place order for a trade
    //Not sure what calldata is exactly for _action
    function placeOrder(uint _fundNum, bytes _action, bytes32 _ticker, uint _qty, uint _price)
    external 
    {
        OrderLib.placeOrder(funds, _fundNum, _action, _qty, _price);
        emit OrderPlaced(_fundNum, _action, _ticker, _qty, _price);
    }

    //Calculate quantity of shares to buy based on investor's % of fund
    //Could we have investor directly access this
    function calcQty(uint _fundNum, uint _qty) 
    external view
    returns (uint) {
        return OrderLib.calcQty(funds, _fundNum, _qty);
    }

    //check Fee Rate - read operation from struct
    //was originally "public view" when not in library
    function checkFeeRate(uint _fundNum) public view returns (uint) {
        return Misc.checkFeeRate(funds, _fundNum);
    }

    //One-time pay fee function
    function payFee(uint _fundNum, uint _timePeriod) external
    {
        PayFeeLib.payFee(funds, _fundNum, _timePeriod);
        uint payment = SafeMath.div(SafeMath.div(funds.list[_fundNum].virtualBalances[msg.sender], checkFeeRate(_fundNum)), _timePeriod);
        emit FeesPaid (_fundNum, msg.sender, payment);
    }

    //Owner of Strategy Collects Fees
    function collectFees(uint _fundNum) external
    //isOwner(_name)
    {
        uint fees = CollectFeesLib.collectFees(funds, _fundNum, msg.sender);
        emit FeesCollected(_fundNum, fees);
    }

    function withdrawFunds(uint _fundNum, uint _amount) public
    //verifyInvestmentStatus(_name) 
    {
        //Need to make sure this matches up with withdraw philosophy
        uint investment;
        uint fees;
        (investment, fees) = WithdrawFundsLib.withdrawFunds(funds, _fundNum, msg.sender, _amount);
        emit FundsWithdrawn(_fundNum, msg.sender, investment, fees);
    }

    //Get fund information (for testing/verification purposes)
    
    function getFundDetails(uint _fundNum) external view returns (bytes32, address, uint, uint, uint, uint){
        return (funds.list[_fundNum].name, 
        funds.list[_fundNum].fundOwner, 
        funds.list[_fundNum].totalCapital,
        funds.list[_fundNum].capitalDeployed,
        funds.list[_fundNum].feeRate,
        funds.list[_fundNum].paymentCycle);
    }

    //need two functions because of stack height
    function getFundDetails2(uint _fundNum, address _addr) external view returns (bool, uint, uint){
        return(funds.list[_fundNum].investors[_addr], 
        funds.list[_fundNum].virtualBalances[_addr],
        funds.list[_fundNum].fees[_addr]);
    }
}