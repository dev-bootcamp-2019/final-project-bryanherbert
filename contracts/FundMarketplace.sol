pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../contracts/InitLib.sol";
import "../contracts/InvestLib.sol";
import "../contracts/Misc.sol";
import "../contracts/PayFeeLib.sol";
import "../contracts/CollectFeesLib.sol";
import "../contracts/WithdrawFundsLib.sol";
import "../contracts/OrderLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/** @title Fund Marketplace
  * @author Bryan Herbert
  * @notice Executes functionality for Mimic dApp 
  */
contract FundMarketplace {
    //State Variables
    //Administrator of contract, can call setStopped()
    address internal admin;
    //Data struct that stores information about the funds
    StructLib.Data funds;
    //Active Fund Count
    uint public fundCount;
    //Total funds to have existed during lifetime of contract 
    uint public lifetimeCount;
    //Circuit breaker variable
    bool public stopped = false;

    //Events

    /**@dev Event that emits that a fund has been created */
    event FundCreated(
        uint indexed fundNum,
        bytes32 name,
        address fundOwner
    );

    /**@dev Event that emits that an investment has been made */
    event Investment(
        uint indexed fundNum,
        address indexed investor,
        uint investment
    );
    
    /**@dev Event that emits when the state has changed and fees have been credited from an investor's account */
    event FeesPaid(
        uint indexed fundNum,
        address indexed investor,
        uint fee
    );

    /**@dev Events that emits when that the manager has collected fees */
    event FeesCollected(
        uint indexed fundNum,
        uint fee
    );

    /**@dev Event that emits when an investor has withdrawn capital from a fund */
    event FundsWithdrawn(
        uint indexed fundNum,
        address investor,
        uint investment,
        uint fees
    );

    /**@dev Event that emits when a manager has placed an order for the fund */
    event OrderPlaced(
        uint indexed fundNum,
        bytes32 action,
        bytes32 ticker,
        uint qty,
        uint price
    );

    /**@dev Event that emits a manager has closed a fund */
    event FundClosed(
        uint indexed fundNum,
        address manager
    );

    /**@dev Event that emits when a manager ends a fundraising period */
    event FundraisingOver(
        uint indexed fundNum,
        address manager
    );

    /**@dev Constructor for the contract
      *@dev sets the admin variable equal to the address that initialized the contract
     */
    constructor() public {
        admin = msg.sender;
    }

    //Modifiers

    /**@dev Modifier that checks if msg.sender is the owner of the fund
      *@param _fundNum Fund Number
      *@param _account Parameter for msg.sender
     */
    modifier isOwner(uint _fundNum, address _account){
        address fundOwner;
        (,fundOwner,,,,) = getFundDetails(_fundNum);
        require(
            fundOwner == msg.sender,
            "Message Sender does not own fund"
        );
        _;
    }

    /**@dev Modifier that checks if the msg.sender is the admin
     */
    modifier isAdmin () {
        require(
            msg.sender == admin,
            "Message Sender is not administrator"
        );
        _;
    }

    /**@dev Modifier that checks if the circuit breaker bool is false
     */
    modifier stopInEmergency () {
        require(
            !stopped,
            "Emergency State: Vulnerability Detected"
        );
        _;
    }

    /**@dev Toggles the stopped state variable
     */
    function setStopped ()
    public 
    isAdmin()
    {
        stopped = !stopped;
    }
    
    /**@dev Initializes a fund with the given arguments and stores it in a Fund Struct within a Data Struct
      *@param _name Fund name
      *@param _fundOwner Fund owner
      *@param _investment Initial investment committed
      *@param _feeRate Annual fee rate
      *@param _paymentCycle Payment Cycle (in days)
      *@param _ipfsHash Digest of ipfs hash
      *@param _hash_function Hash function of ipfs hash
      *@param _size size of ipfs hash
      *@dev uses stopInEmergency() modifier
      *@dev lifetimeCount is used in InitLib.initializeFund because current implementation makes it difficult to delete and replace fund data
     */
    function initializeFund(bytes32 _name, 
    address _fundOwner, 
    uint _investment, 
    uint _feeRate, 
    uint _paymentCycle,
    bytes32 _ipfsHash,
    uint8 _hash_function,
    uint8 _size) 
    external payable 
    stopInEmergency()
    {
        InitLib.initializeFund(funds, 
        lifetimeCount, 
        _name, 
        _fundOwner, 
        _investment, 
        _feeRate,
        _paymentCycle,
        _ipfsHash,
        _hash_function,
        _size);
        fundCount++;
        lifetimeCount++;
        emit FundCreated(fundCount, _name, _fundOwner);
    }

    /**@dev Allows an investor to commit an amount of virtual capital to the fund
      *@dev Also takes care of fee payment up front
      *@param _fundNum Fund number
      *@param _investment Virtual capital committed
      *@dev Uses stopInEmergency() modifier
     */
    function Invest(uint _fundNum, 
    uint _investment) 
    external payable 
    stopInEmergency() 
    {
        InvestLib.Invest(funds, _fundNum, _investment, msg.sender, msg.value);
        emit Investment(_fundNum, msg.sender, _investment);
    }

    /**@dev Takes order information and passes it to OrderLib.placeOrder() for error checking
      *@param _fundNum Fund number
      *@param _action Type of order: buy or sell
      *@param _ticker String representation of stock ticker
      *@param _qty Quantity of shares
      *@param _price Price per share in wei
      *@dev Uses stopInEmergency modifier
      *@dev Emits OrderPlaced event
     */
    function placeOrder(uint _fundNum, 
    bytes32 _action, 
    bytes32 _ticker, 
    uint _qty, 
    uint _price)
    external 
    stopInEmergency()
    {
        OrderLib.placeOrder(funds, _fundNum, _action, _qty, _price);
        emit OrderPlaced(_fundNum, _action, _ticker, _qty, _price);
    }

    /**@dev Calculates the quantity of shares for an investor's order
      *@param _fundNum Fund number
      *@param _qty Quantity of shares
      *@return uint Number of shares
     */
    function calcQty(uint _fundNum, uint _qty) 
    external view
    returns (uint) {
        return OrderLib.calcQty(funds, _fundNum, _qty);
    }

    /**@dev Passes arguments to checkFeeRate() in Misc.sol
      *@param _fundNum Fund Number
      *@return uint Fee Rate
     */
    function checkFeeRate(uint _fundNum) public view returns (uint) {
        return Misc.checkFeeRate(funds, _fundNum);
    }

    /**@dev One-time pay fee function
      *@param _fundNum Fund number
      *@param _timePeriod Time period to divide payments
      *@dev Uses stopInEmergency modifier
     */
    function payFee(uint _fundNum, uint _timePeriod) 
    external
    stopInEmergency()
    {
        PayFeeLib.payFee(funds, _fundNum, _timePeriod);
        uint payment = SafeMath.div(SafeMath.div(funds.list[_fundNum].virtualBalances[msg.sender], checkFeeRate(_fundNum)), _timePeriod);
        emit FeesPaid (_fundNum, msg.sender, payment);
    }

    /**@dev Checks whether a payment is due and how much
      *@param  _fundNun Fund number
      *@param _timePeriod Time period to divide payments
      *@return payment uint that returns the payment due
      *@return paymentDue bool that represents whether a payment is due
     */
    function checkFee(uint _fundNum, uint _timePeriod) external view returns (uint, bool) {
        uint payment;
        bool paymentDue;
        (payment, paymentDue) = PayFeeLib.checkFee(funds, _fundNum, _timePeriod);
        return (payment, paymentDue);
    }

    /**@dev Owner of fund collects fees from smart contract
      *@param _fundNum FundNumber
     */
    function collectFees(uint _fundNum) 
    external
    {
        uint fees = CollectFeesLib.collectFees(funds, _fundNum, msg.sender);
        emit FeesCollected(_fundNum, fees);
    }

    /**@dev Allows an investor to withdraw virtual balance and unearned fees
      *@param _fundNum Fund Number
      *@param _amound Amount to be withdrawn
     */
    function withdrawFunds(uint _fundNum, uint _amount) 
    public 
    {
        uint investment;
        uint fees;
        (investment, fees) = WithdrawFundsLib.withdrawFunds(funds, _fundNum, msg.sender, _amount);
        emit FundsWithdrawn(_fundNum, msg.sender, investment, fees);
    }

    /**@dev Allows manager to shut down a fund's operations
      *@param  _fundNum Fund Number
      *@dev Uses isOwner() and stopInEmergency modifiers
     */
    function closeFund(uint _fundNum) public
    isOwner(_fundNum, msg.sender)
    stopInEmergency()
    {
        uint refund = funds.list[_fundNum].fees[msg.sender];
        msg.sender.transfer(refund);
        funds.list[_fundNum].closed = true;
        fundCount--;
        emit FundClosed(_fundNum, msg.sender);
    }

    /**@dev Allows manager to end the fundraising period
      *@param _fundNum Fund number
      *@dev Uses isOwner() and stopinEmergency() modifiers
     */
    function endFundraising(uint _fundNum) 
    public
    isOwner(_fundNum, msg.sender)
    stopInEmergency()
    {
        funds.list[_fundNum].fundraising = false;
        emit FundraisingOver(_fundNum, msg.sender);
    }
    
    /**@dev Get non-user specific fund Information
      *@param _fundNum Fund number
      *@return bytes32 Fund name
      *@return address Fund owner
      *@return uint Total Capital
      *@return uint Capital Deployed
      *@return uint Fee Rate
      *@return uint Payment Cycle
     */
    function getFundDetails(uint _fundNum) public view 
    returns (bytes32, 
    address, 
    uint, 
    uint, 
    uint, 
    uint){
        return (funds.list[_fundNum].name, 
        funds.list[_fundNum].fundOwner, 
        funds.list[_fundNum].totalCapital,
        funds.list[_fundNum].capitalDeployed,
        funds.list[_fundNum].feeRate,
        funds.list[_fundNum].paymentCycle);
    }

    /**@dev Get user specific fund information
      *@param _fundNum Fund number
      *@param _addr Address of interest
      *@return bool Investor Status
      *@return uint Virtual balance
      *@return uint Fees in Escrow
     */
    function getFundDetails2(uint _fundNum, address _addr) 
    public view 
    returns (bool, 
    uint, 
    uint){
        return(funds.list[_fundNum].investors[_addr], 
        funds.list[_fundNum].virtualBalances[_addr],
        funds.list[_fundNum].fees[_addr]);
    }

    function checkFundStatus(uint _fundNum) external view returns (bool, bool){
        return(funds.list[_fundNum].fundraising,
        funds.list[_fundNum].closed
        );
    }

    /** @dev Returns the members of the Multihash struct
      * @param _fundNum Fund Number
      * @return ipfsHash 32-byte hexadecimal representation of ipfsHash digest
      * @return hash_function type of hash_function used for encoding
      * @return size of the length of the digest
      */
    function getIpfsHash (uint _fundNum) public view returns (bytes32 ipfsHash, uint8 hash_function, uint8 size){
        return(funds.list[_fundNum].investHash.ipfsHash,
        funds.list[_fundNum].investHash.hash_function,
        funds.list[_fundNum].investHash.size
        );
    }
}