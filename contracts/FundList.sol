pragma solidity ^0.4.24;

library Init {
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
}

contract FundList {
    //State Variables
    address internal admin;
    mapping(bytes32 => Init.Fund) internal funds;
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

    //Administrative control
    //Any write functions must be completed by the administrator
    modifier isAdmin{
        require(
            msg.sender == admin,
            "Message Sender is not Administrator"
        );
        _;
    }

    constructor() public {
        admin = msg.sender;
        //initialize strategy count to 0
        fundCount = 0;
    }

    function initializeFund(bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) 
    external payable
    isAdmin()
    {
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
        emit FundCreated(_name, fundCount, _fundOwner);
    }

    //Check to see if an account is an investor in a strategy
    //eventually change to only one parameter and use delegate call instead
    function isInvestor(bytes32 _name, address _investor) external view returns (bool) {
        bool result;
        (,result,,) = getFundDetails2(_name, _investor);
        return result;
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(bytes32 _name, uint _investment, address _investor) external payable
    isAdmin()
    {
        funds[_name].totalBalance += _investment;
        funds[_name].investors[_investor] = true;
        funds[_name].virtualBalances[_investor] = _investment;
        funds[_name].fees[_investor] = msg.value;
        funds[_name].paymentCycleStart[_investor] = now;
        emit Investment(_name, _investor, _investment);
    }
    
    //check Fee Rate - read operation from struct
    function checkFeeRate(bytes32 _name) public view returns (uint) {
        return 100/funds[_name].feeRate;
    }

    //One-time pay fee function
    function payFee(bytes32 _name, uint _timePeriod, address _investor) external
    isAdmin()
    {
        //Calculate payment
        uint payment = (funds[_name].virtualBalances[_investor]/checkFeeRate(_name))/_timePeriod;
        //Owner fees account
        address fundOwner = funds[_name].fundOwner;
        //Subtract payment from investor fees
        funds[_name].fees[_investor] -= payment;
        funds[_name].fees[fundOwner] += payment;
        funds[_name].paymentCycleStart[_investor] = now;
        emit FeesPaid (_name, _investor, payment);
    }

    function checkPaymentCycleStart(bytes32 _name, address _investor) external view
    returns (uint)
    {
        return funds[_name].paymentCycleStart[_investor];
    }

    //Owner of Strategy Collects Fees
    function collectFees(bytes32 _name, address fundOwner) external
    isAdmin()
    {
        uint feesCollected = funds[_name].fees[fundOwner];
        funds[_name].fees[fundOwner] = 0;
        fundOwner.transfer(feesCollected);
        emit FeesCollected(_name, feesCollected);
    }

    function withdrawFunds(bytes32 _name, address _investor) external
    isAdmin() 
    {
        //Need to make sure this matches up with withdraw philosophy
        //Temporary Balance and Fees
        uint bal = funds[_name].virtualBalances[_investor];
        uint fees = funds[_name].fees[_investor];
        //subtract virtual balance from total funds
        funds[_name].totalBalance -= bal;
        //zero out virtual Balance
        funds[_name].virtualBalances[_investor] = 0;
        //transfer fees back to investor
        _investor.transfer(fees);
        //Zero out fees
        funds[_name].fees[_investor] = 0;
        //set investor status to faslse
        funds[_name].investors[_investor] = false;
        emit FundsWithdrawn(_name, _investor, bal, fees);
    }

    //Get fund information (for testing/verification purposes)
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