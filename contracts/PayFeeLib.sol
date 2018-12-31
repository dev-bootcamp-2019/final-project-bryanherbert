pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../contracts/Misc.sol";

library PayFeeLib {
    //Modifiers
    modifier verifyInvestmentStatus(StructLib.Data storage self, bytes32 _name){
        //check that msg.sender is an investor
        require(
            self.list[_name].investors[msg.sender] == true,
            "Message Sender is not an investor"
        );
        _;
    }

    modifier checkFeePayment(StructLib.Data storage self, bytes32 _name, uint _timePeriod) {
        //uint virtualBalance = self.list[_name].virtualBalances[msg.sender];
        //uint fees = self.list[_name].fees[msg.sender];
        //Get investor's virtual balance and fees deposited
        //(,virtualBalance,fees) = getFundDetails2(_name, msg.sender);
        //uint payment = (self.list[_name].virtualBalances[msg.sender]/checkFeeRate(self, _name))/_timePeriod;
        require(
            //Check that msg.sender has enough in fees to make payment installment
            self.list[_name].fees[msg.sender] > (self.list[_name].virtualBalances[msg.sender]/Misc.checkFeeRate(self, _name))/_timePeriod,
            "Fee balance is insufficient to make payment or payment cycle is not complete"
        );
        _;
    }

    modifier cycleComplete(StructLib.Data storage self, bytes32 _name){
        //uint paymentCycleStart = self.list[_name].paymentCycleStart[msg.sender];
        //uint paymentCycle = self.list[_name].paymentCycle;
        require(
            now >= self.list[_name].paymentCycleStart[msg.sender] + self.list[_name].paymentCycle * 1 days,
            "Cycle is not complete, no fee due"
        );
        _;
    }

    function payFee(StructLib.Data storage self, bytes32 _name, uint _timePeriod) 
    public
    verifyInvestmentStatus(self, _name)
    checkFeePayment(self, _name, _timePeriod)
    cycleComplete(self, _name)
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