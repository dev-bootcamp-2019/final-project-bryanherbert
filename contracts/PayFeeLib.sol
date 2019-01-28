pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../contracts/Misc.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/** @title Pay Fees Library
  * @author Bryan Herbert
  * @notice Functionality to make state changes when a fee is paid
  */
library PayFeeLib {
    //Modifiers

    /** @dev Modifier that verifies msg.sender is an investor in the fund
      * @param self Data struct that contains information about the funds
      * @param _fundNum Fund Number
      */
    modifier verifyInvestmentStatus(StructLib.Data storage self, uint _fundNum){
        //check that msg.sender is an investor
        require(
            self.list[_fundNum].investors[msg.sender] == true,
            "Message Sender is not an investor"
        );
        _;
    }

    /** @dev Modifier to check that the investor can make the fee payment
      * @param _fundNum Fund Number
      * @param _timePeriod Time period to divide the fee payments over
      */
    modifier checkFeePayment(StructLib.Data storage self, 
    uint _fundNum, 
    uint _timePeriod) {
        //Couldn't use local variables because of a stack too deep error
        //Fees in Escrow > (Virtual Balance / Result from Fee Rate function) / Time Period
        require(
            //Check that msg.sender has enough in fees to make payment installment
            self.list[_fundNum].fees[msg.sender] > SafeMath.div(SafeMath.div(self.list[_fundNum].virtualBalances[msg.sender], Misc.checkFeeRate(self, _fundNum)),_timePeriod),
            "Fee balance is insufficient to make payment or payment cycle is not complete"
        );
        _;
    }

    /** @dev Modifier to check that the Payment cycle is complete
      * @dev This should eventually get upgraded so that the manager is in control of this functionality and not the investor
      * @param self Data struct that contains fund information
      * @param _fundNum Fund Number
      */
    modifier cycleComplete(StructLib.Data storage self, uint _fundNum){
        //uint paymentCycleStart = self.list[_name].paymentCycleStart[msg.sender];
        //uint paymentCycle = self.list[_name].paymentCycle;
        require(
            now >= SafeMath.add(self.list[_fundNum].paymentCycleStart[msg.sender], SafeMath.mul(self.list[_fundNum].paymentCycle, 1 days)),
            "Cycle is not complete, no fee due"
        );
        _;
    }

    /** @dev Returns a value payment that represens the payment due and a boolean representing whether a payment is due
      * @param self Data struct that contains fund information
      * @param _fundNum Fund Number
      * @param _timePeriod Number of time periods to divide payment by
      * @return uint payment due
      * @return bool value that indicates whether a payment is due
      */
    function checkFee(StructLib.Data storage self, uint _fundNum, uint _timePeriod)
    public view
    verifyInvestmentStatus(self, _fundNum)
    returns (uint, bool)
    {
        uint payment = SafeMath.div(SafeMath.div(self.list[_fundNum].virtualBalances[msg.sender],Misc.checkFeeRate(self, _fundNum)),_timePeriod);
        bool paymentDue = (now >= SafeMath.add(self.list[_fundNum].paymentCycleStart[msg.sender], SafeMath.mul(self.list[_fundNum].paymentCycle, 1 days)));
        return (payment, paymentDue);
    }

    /** @dev Makes state changes when an investor pays fees at the end of a cycle
      * @param self Data struct that contains fund information
      * @param _fundNum Fund number
      * @param _timePeriod Number of time periods to divide payment by
      * @dev uses verifyInvestmentStatus, checkFeePayment, and cycleComplete modifiers
      */
    function payFee(StructLib.Data storage self, uint _fundNum, uint _timePeriod) 
    public
    verifyInvestmentStatus(self, _fundNum)
    checkFeePayment(self, _fundNum, _timePeriod)
    cycleComplete(self, _fundNum)
    {
        //Calculate payment
        uint payment = SafeMath.div(SafeMath.div(self.list[_fundNum].virtualBalances[msg.sender],Misc.checkFeeRate(self, _fundNum)),_timePeriod);
        //Subtract paymetn from invstor's fees account
        self.list[_fundNum].fees[msg.sender] -= payment;
        //Transfer fee payment to manager's fees account
        self.list[_fundNum].fees[self.list[_fundNum].fundOwner] += payment;
        //restart cycle
        self.list[_fundNum].paymentCycleStart[msg.sender] = now;
    }
}