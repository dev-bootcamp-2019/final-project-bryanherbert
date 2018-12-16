pragma solidity ^0.4.24;

contract StrategyHub {
    //State Variables
    address owner;
    //maybe change uint to name of strategy
    mapping(bytes32 => Strategy) public strategies;
    uint stratCount;

    struct Strategy {
        //Name of strategy
        bytes32 name;
        //Quant who initialized the strategy
        address stratOwner;
        //amount of funds the strategy is virtually managing
        uint funds;
        //Add fee that quant can set- in whole number, i.e. 2% is represented as 2
        uint feeRate;
        //maps investors to investment status- current investors return true, non-investors return false
        mapping (address => bool) investors;
        //maps investors to their virtual balances in the strategy
        mapping (address => uint) virtualBalances;
        //maps investors to the actual fee they have stored in the Strategy Hub contract
        //fees are paid into stratOwner fee account and paid from investor fee account
        mapping (address => uint) fees;
        //will need to add IPFS hash eventually to verify code

    }

    //Events
    event StrategyCreated(
        bytes32 name,
        uint stratNum,
        address stratOwner
    );

    //Modifiers
    modifier verifyBalance(bytes32 _name, address _account, uint _investment){
        //Account Balance must be greater than investment + Fees
        //Not sure this correct- want it to represent ~2%
        uint fee = _investment/checkFeeRate(_name);
        require(
            _account.balance > _investment + fee,
            "Sender does not have enough balance to invest"
        );
        _;
    }

    modifier verifyFee(bytes32 _name, uint _investment, uint _proposedFee) {
        //Verify that the msg.value > fee
        require(
            _proposedFee >= _investment/checkFeeRate(_name),
            "Fee is insufficent"
        );
        _;
    }

    modifier checkFeePayment(bytes32 _name, address _account, uint _timePeriod) {
        //Verify that msg.sender has enough in fees to make payment installment
        //payment = 1/12th of fee
        uint payment = (strategies[_name].virtualBalances[_account]/checkFeeRate(_name))/_timePeriod;
        require(
            strategies[_name].fees[_account] > payment,
            "Fee balance is insufficient to make payment"
        );
        _;
    }

    modifier verifyInvestmentStatus(bytes32 _name, address _account){
        //check that msg.sender is an investor
        require(
            strategies[_name].investors[_account] = true,
            "Message Sender is not an investor"
        );
        _;
    }

    //Can replace this with ethpm code
    modifier isOwner(bytes32 _name, address _account){
        require(
            strategies[_name].stratOwner == _account,
            "Message Sender does not own strategy"
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
        //initialize strategy count to 0
        stratCount = 0;
    }

    function initializeStrat(bytes32 _name, uint _investment, uint _feeRate) public payable {
        //initialize strat name to _name
        strategies[_name].name = _name;
        //Strat owner is message sender
        strategies[_name].stratOwner = msg.sender;
        //Initial funds are the msg.value
        strategies[_name].funds = _investment;
        //Set fee rate
        strategies[_name].feeRate = _feeRate;
        //set stratOwner to also be an investor
        strategies[_name].investors[msg.sender] = true;
        //set stratOwner's investor balance to the msg.value
        strategies[_name].virtualBalances[msg.sender] = _investment;
        //set stratOwner's fees to zero
        strategies[_name].fees[msg.sender] = 0;
        //Emit Event
        emit StrategyCreated(_name, stratCount, msg.sender);
        //Increment stratCount
        stratCount++;

    }

    //Check to see if an account is an investor in a strategy
    function isInvestor(bytes32 _name) public view returns (bool) {
        return strategies[_name].investors[msg.sender];
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(bytes32 _name, uint _investment) public payable 
    verifyBalance(_name, msg.sender, _investment) 
    verifyFee(_name, _investment, msg.value) 
    returns (bool) {
        strategies[_name].funds += _investment;
        strategies[_name].investors[msg.sender] = true;
        strategies[_name].virtualBalances[msg.sender] = _investment;
        strategies[_name].fees[msg.sender] = msg.value;
        return strategies[_name].investors[msg.sender];
    }

    //check fee rate
    function checkFeeRate(bytes32 _name) public view returns (uint) {
        return 100/strategies[_name].feeRate;
    }

    //One-time pay fee function
    function payFee(bytes32 _name, uint _timePeriod) public
    verifyInvestmentStatus(_name, msg.sender)
    checkFeePayment(_name, msg.sender, _timePeriod)
    {
        //Calculate payment
        uint payment = (strategies[_name].virtualBalances[msg.sender]/checkFeeRate(_name))/_timePeriod;
        //Owner fees account
        address stratOwner = strategies[_name].stratOwner;
        //Subtract payment from investor fees
        strategies[_name].fees[msg.sender] -= payment;
        strategies[_name].fees[stratOwner] += payment;
    }

    //Owner of Strategy Collects Fees
    function collectFees(bytes32 _name) public
    isOwner(_name, msg.sender)
    {
        uint feesCollected = strategies[_name].fees[msg.sender];
        strategies[_name].fees[msg.sender] = 0;
        msg.sender.transfer(feesCollected);
    }

    function withdrawFunds(bytes32 _name) public
    verifyInvestmentStatus(_name, msg.sender) 
    {
        //Need to make sure this matches up with withdraw philosophy
        //Add event
        //subtract virtual balance from total funds
        strategies[_name].funds -= strategies[_name].virtualBalances[msg.sender];
        //zero out virtual Balance
        strategies[_name].virtualBalances[msg.sender] = 0;
        //transfer fees back to investor
        msg.sender.transfer(strategies[_name].fees[msg.sender]);
        //Zero out fees
        strategies[_name].fees[msg.sender] = 0;
        //set investor status to faslse
        strategies[_name].investors[msg.sender] = false;
    }

    //not a permanent function
    function getStratDetails(bytes32 _name) public view returns (bytes32, address, uint, uint){
        return (strategies[_name].name, 
        strategies[_name].stratOwner, 
        strategies[_name].funds, 
        strategies[_name].feeRate);
    }
    //need two functions because of stack height
    function getStratDetails2(bytes32 _name, address _addr) public view returns (bool, uint, uint){
        return(strategies[_name].investors[_addr], 
        strategies[_name].virtualBalances[_addr],
        strategies[_name].fees[_addr]);
    }
}
