pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../contracts/InitLib.sol";

library InvestLib {
    //Modifiers
    modifier verifyBalance(StructLib.Data storage self, bytes32 _name, uint _investment){
        //Account Balance must be greater than investment + Fees
        //Not sure this correct- want it to represent ~2%
        uint fee = _investment/Misc.checkFeeRate(self, _name);
        require(
            msg.sender.balance > _investment + fee,
            "Sender does not have enough balance to invest"
        );
        _;
    }

    modifier verifyFee(StructLib.Data storage self, bytes32 _name, uint _investment, uint _proposedFee) {
        //Verify that the msg.value > fee
        require(
            _proposedFee >= _investment/Misc.checkFeeRate(self, _name),
            "Fee is insufficent"
        );
        _;
    }
    function Invest(StructLib.Data storage self, bytes32 _name, uint _investment, address _investor, uint _value) 
    internal
    verifyBalance(self, _name, _investment)
    verifyFee(self, _name, _investment, _value)
    {
        self.list[_name].totalBalance += _investment;
        self.list[_name].investors[_investor] = true;
        self.list[_name].virtualBalances[_investor] = _investment;
        self.list[_name].fees[_investor] = _value;
        self.list[_name].paymentCycleStart[_investor] = now;
    }
}

library PayFeeLib {
    //Modifiers
    // modifier verifyInvestmentStatus(StructLib.Data storage self, bytes32 _name){
    //     //check that msg.sender is an investor
    //     require(
    //         //isInvestor(_name, msg.sender) == true,
    //         self.list[_name].investors[msg.sender] == true,
    //         "Message Sender is not an investor"
    //     );
    //     _;
    // }

    // modifier checkFeePayment(StructLib.Data storage self, bytes32 _name, uint _timePeriod) {
    //     //uint virtualBalance = self.list[_name].virtualBalances[msg.sender];
    //     //uint fees = self.list[_name].fees[msg.sender];
    //     //Get investor's virtual balance and fees deposited
    //     //(,,virtualBalance,fees) = getFundDetails2(_name, msg.sender);
    //     //uint payment = (self.list[_name].virtualBalances[msg.sender]/checkFeeRate(self, _name))/_timePeriod;
    //     require(
    //         //Check that msg.sender has enough in fees to make payment installment
    //         self.list[_name].fees[msg.sender] > (self.list[_name].virtualBalances[msg.sender]/Misc.checkFeeRate(self, _name))/_timePeriod,
    //         "Fee balance is insufficient to make payment or payment cycle is not complete"
    //     );
    //     _;
    // }

    // modifier cycleComplete(StructLib.Data storage self, bytes32 _name){
    //     //uint paymentCycleStart = self.list[_name].paymentCycleStart[msg.sender];
    //     //uint paymentCycle = self.list[_name].paymentCycle;
    //     require(
    //         now >= self.list[_name].paymentCycleStart[msg.sender] + self.list[_name].paymentCycle * 1 days,
    //         "Cycle is not complete, no fee due"
    //     );
    //     _;
    // }

    function payFee(StructLib.Data storage self, bytes32 _name, uint _timePeriod) 
    internal
    // verifyInvestmentStatus(self, _name)
    // checkFeePayment(self, _name, _timePeriod)
    // cycleComplete(self, _name)
    {
        //Calculate payment
        uint payment = (self.list[_name].virtualBalances[msg.sender]/Misc.checkFeeRate(self, _name))/_timePeriod;
        //Owner fees account
        address fundOwner = self.list[_name].fundOwner;
        //Subtract payment from investor fees
        self.list[_name].fees[msg.sender] -= payment;
        self.list[_name].fees[fundOwner] += payment;
        self.list[_name].paymentCycleStart[msg.sender] = now;
    }
}

library Misc {
    //check Fee Rate - read operation from struct
    function checkFeeRate(StructLib.Data storage self, bytes32 _name) 
    internal view
    returns (uint) {
        return 100/self.list[_name].feeRate;
    }
}

library Init {
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

    function collectFees(StructLib.Data storage self, bytes32 _name, address fundOwner)
    internal
    returns (uint)
    {
        //Calculate fees
        uint feesCollected = self.list[_name].fees[fundOwner];
        self.list[_name].fees[fundOwner] = 0;
        fundOwner.transfer(feesCollected);
        return feesCollected;
    }

    function withdrawFunds(StructLib.Data storage self, bytes32 _name, address _investor)
    internal
    returns (uint, uint)
    {
        //Need to make sure this matches up with withdraw philosophy
        //Temporary Balance and Fees
        uint bal = self.list[_name].virtualBalances[_investor];
        uint fees = self.list[_name].fees[_investor];
        //subtract virtual balance from total funds
        self.list[_name].totalBalance -= bal;
        //zero out virtual Balance
        self.list[_name].virtualBalances[_investor] = 0;
        //transfer fees back to investor
        _investor.transfer(fees);
        //Zero out fees
        self.list[_name].fees[_investor] = 0;
        //set investor status to faslse
        self.list[_name].investors[_investor] = false;
        return (bal, fees);
    }
}



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
        uint fees = Init.collectFees(funds, _name, msg.sender);
        emit FeesCollected(_name, fees);
    }

    function withdrawFunds(bytes32 _name) public
    //verifyInvestmentStatus(_name) 
    {
        //Need to make sure this matches up with withdraw philosophy
        uint investment;
        uint fees;
        (investment, fees) = Init.withdrawFunds(funds, _name, msg.sender);
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