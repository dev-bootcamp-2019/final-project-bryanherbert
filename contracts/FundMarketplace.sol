pragma solidity ^0.4.24;

contract FundMarketplace {
    //State Variables
    address admin;
    //FundList Contract
    FundList f;

    //Events
    event FundCreated(
        bytes32 name,
        uint fundCount,
        address stratOwner
    );

    // event Investment(
    //     bytes32 name,
    //     address investor,
    //     uint investment
    // );
    
    // event FeesPaid(
    //     bytes32 name,
    //     address investor,
    //     uint fee
    // );

    // event FeesCollected(
    //     bytes32 name,
    //     uint fee
    // );

    // event FundsWithdrawn(
    //     bytes32 name,
    //     address investor,
    //     uint investment,
    //     uint fees
    // );

    // //Modifiers
    // modifier verifyBalance(bytes32 _name, uint _investment){
    //     //Account Balance must be greater than investment + Fees
    //     //Not sure this correct- want it to represent ~2%
    //     uint fee = _investment/checkFeeRate(_name);
    //     require(
    //         msg.sender.balance > _investment + fee,
    //         "Sender does not have enough balance to invest"
    //     );
    //     _;
    // }

    // modifier verifyFee(bytes32 _name, uint _investment, uint _proposedFee) {
    //     //Verify that the msg.value > fee
    //     require(
    //         _proposedFee >= _investment/checkFeeRate(_name),
    //         "Fee is insufficent"
    //     );
    //     _;
    // }

    // modifier checkFeePayment(bytes32 _name, uint _timePeriod) {
    //     uint payment = (strategies[_name].virtualBalances[msg.sender]/checkFeeRate(_name))/_timePeriod;
    //     require(
    //         //Check that msg.sender has enough in fees to make payment installment
    //         strategies[_name].fees[msg.sender] > payment,
    //         "Fee balance is insufficient to make payment or payment cycle is not complete"
    //     );
    //     _;
    // }

    // modifier verifyInvestmentStatus(bytes32 _name){
    //     //check that msg.sender is an investor
    //     require(
    //         strategies[_name].investors[msg.sender] = true,
    //         "Message Sender is not an investor"
    //     );
    //     _;
    // }

    // //Can replace this with ethpm code
    // modifier isOwner(bytes32 _name){
    //     require(
    //         strategies[_name].stratOwner == msg.sender,
    //         "Message Sender does not own strategy"
    //     );
    //     _;
    // }

    // modifier cycleComplete(bytes32 _name){
    //     require(
    //         now >= strategies[_name].paymentCycleStart[msg.sender] + strategies[_name].paymentCycle * 1 days,
    //         "Cycle is not complete, no fee due"
    //     );
    //     _;
    // }

    constructor() public {
        admin = msg.sender;
        //Need to initialize a new contract instance of FundList
        //Attempt may be wrong
        f = new FundList();
    }

    function initializeStrat(bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) public payable {
        bytes32 fundName;
        uint fundCount;
        address fundOwner;
        (fundName, fundCount, fundOwner) = f.initializeFund(_name, _fundOwner, _investment, _feeRate, _paymentCycle);
        //Emit Event
        emit FundCreated(fundName, fundCount, fundOwner);
    }
/*
    //Check to see if an account is an investor in a strategy
    function isInvestor(bytes32 _name) public view returns (bool) {
        return strategies[_name].investors[msg.sender];
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(bytes32 _name, uint _investment) public payable 
    verifyBalance(_name, _investment) 
    verifyFee(_name, _investment, msg.value) 
    returns (bool) {
        strategies[_name].funds += _investment;
        strategies[_name].investors[msg.sender] = true;
        strategies[_name].virtualBalances[msg.sender] = _investment;
        strategies[_name].fees[msg.sender] = msg.value;
        strategies[_name].paymentCycleStart[msg.sender] = now;
        //Emit event
        emit Investment(_name, msg.sender, _investment);
        return strategies[_name].investors[msg.sender];
    }

    //check fee rate
    function checkFeeRate(bytes32 _name) public view returns (uint) {
        return 100/strategies[_name].feeRate;
    }

    //One-time pay fee function
    function payFee(bytes32 _name, uint _timePeriod) public
    verifyInvestmentStatus(_name)
    checkFeePayment(_name, _timePeriod)
    cycleComplete(_name)
    {
        //Calculate payment
        uint payment = (strategies[_name].virtualBalances[msg.sender]/checkFeeRate(_name))/_timePeriod;
        //Owner fees account
        address stratOwner = strategies[_name].stratOwner;
        //Subtract payment from investor fees
        strategies[_name].fees[msg.sender] -= payment;
        strategies[_name].fees[stratOwner] += payment;
        strategies[_name].paymentCycleStart[msg.sender] = now;
        emit FeesPaid(_name, msg.sender, payment);
    }

    //Owner of Strategy Collects Fees
    function collectFees(bytes32 _name) public
    isOwner(_name)
    {
        uint feesCollected = strategies[_name].fees[msg.sender];
        strategies[_name].fees[msg.sender] = 0;
        msg.sender.transfer(feesCollected);
        emit FeesCollected(_name, feesCollected);
    }

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
    //Get fund information (for testing purposes)
    function getFundDetails(bytes32 _name) public view returns (bytes32, address, uint, uint){
        bytes32 a;
        address b;
        uint c;
        uint d;
        (a,b,c,d) = f.getFundDetails(_name);
        return (a,b,c,d);
    }
    //need two functions because of stack height
    function getFundDetails2(bytes32 _name, address _addr) public view returns (uint, bool, uint, uint){
        uint a;
        bool b;
        uint c;
        uint d;
        (a,b,c,d) = f.getFundDetails2(_name, _addr);
        return (a,b,c,d);
    }
}

contract FundList {
    //State Variables
    address admin;
    mapping(bytes32 => Fund) public funds;
    uint fundCount;

    struct Fund {
        //Name of fund
        bytes32 name;
        //Partner who initialized the strategy
        //Could be a multisig wallet
        address fundOwner;
        //amount of funds the strategy is virtually managing
        uint totalBalance;
        //Add fee that quant can set- in whole number, i.e. 2% is represented as 2
        uint feeRate;
        //Number of days in Payment Cycle
        uint paymentCycle;
        //maps investors to investment status- current investors return true, non-investors return false
        mapping (address => bool) investors;
        //maps investors to their virtual balances in the strategy
        mapping (address => uint) virtualBalances;
        //maps investors to the actual fee they have stored in the Strategy Hub contract
        //fees are paid into stratOwner fee account and paid from investor fee account
        mapping (address => uint) fees;
        //Adoption Times for each investor
        mapping(address => uint) paymentCycleStart;
        //will need to add IPFS hash eventually to verify code
    }

    constructor() public {
        admin = msg.sender;
        //initialize strategy count to 0
        fundCount = 0;
    }

    function initializeFund(bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) public payable returns(bytes32, uint, address) {
        //initialize strat name to _name
        funds[_name].name = _name;
        //Strat owner is message sender
        //Be careful of message sender here - might be the Fund Marketplace contract - might have to use delegatecall
        funds[_name].fundOwner = _fundOwner;
        //Initial funds are the msg.value
        funds[_name].totalBalance = _investment;
        //Set fee rate
        funds[_name].feeRate = _feeRate;
        //Set payment cycle
        funds[_name].paymentCycle = _paymentCycle;
        //set fundOwner to also be an investor
        funds[_name].investors[_fundOwner] = true;
        //set fundOwner's investor balance to the msg.value
        funds[_name].virtualBalances[_fundOwner] = _investment;
        //set fundOwner's fees to zero
        funds[_name].fees[_fundOwner] = 0;
        //Increment fundCount
        fundCount++;
        return (funds[_name].name, fundCount-1, funds[_name].fundOwner);
    }

    //Get fund information (for testing purposes)
    function getFundDetails(bytes32 _name) public view returns (bytes32, address, uint, uint){
        return (funds[_name].name, 
        funds[_name].fundOwner, 
        funds[_name].totalBalance, 
        funds[_name].feeRate);
    }
    //need two functions because of stack height
    function getFundDetails2(bytes32 _name, address _addr) public view returns (uint, bool, uint, uint){
        return(funds[_name].paymentCycle,
        funds[_name].investors[_addr], 
        funds[_name].virtualBalances[_addr],
        funds[_name].fees[_addr]);
    }
}