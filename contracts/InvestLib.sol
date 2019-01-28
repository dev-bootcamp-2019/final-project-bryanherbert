pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../contracts/Misc.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/** @title Invest Library
  * @author Bryan Herbert
  * @notice Functionality to make state changes upon a new investment
  */
library InvestLib {
    //Modifiers
    /** @dev Modifier that verifies the investor has enough ether balance to commit to fund
      * @dev There is a bug in this methodology because it doesn't check across all funds the investor is committed too. Doesn't matter though because these funds aren't actually transferred.
      * @param self Data struct with fund information
      * @param _fundNum Fund Number
      * @param _investment Virtual capital committed to fund
      * @dev The balance of the sender must be greater than the sum of the proposed virtual balance and fee payment
      */
    modifier verifyBalance(StructLib.Data storage self, 
    uint _fundNum, 
    uint _investment) {
        uint fee = _investment/Misc.checkFeeRate(self, _fundNum);
        require(
            msg.sender.balance > SafeMath.add(_investment,fee),
            "Sender does not have enough balance to invest"
        );
        _;
    }

    /** @dev Modifier that verifies the value in the transaction is sufficient to pay the annual fee
      * @param self Data struct that contains fund information
      * @param _fundNum Fund number
      * @param _investment Virtual capital committed to fund
      * @param _proposedFee msg.value
      */
    modifier verifyFee(StructLib.Data storage self,
     uint _fundNum, 
     uint _investment,
     uint _proposedFee) {
        require(
            _proposedFee >= SafeMath.div(_investment,Misc.checkFeeRate(self, _fundNum)),
            "Fee is insufficient"
        );
        _;
    }

    /** @dev Makes state changes for a new investment
      * @param self Data struct that contains fund information
      * @param _fundNum Fund number
      * @param _investment Virtual capital committed
      * @param _investor New investor address
      * @param _value msg.value that represents fees
      * @dev Uses verifyBalance() and verifyFee() modifier
      */
    function Invest(StructLib.Data storage self, 
    uint _fundNum, 
    uint _investment, 
    address _investor, 
    uint _value) 
    public
    verifyBalance(self, _fundNum, _investment)
    verifyFee(self, _fundNum, _investment, _value)
    {
        self.list[_fundNum].totalCapital += _investment;
        self.list[_fundNum].investors[_investor] = true;
        self.list[_fundNum].virtualBalances[_investor] += _investment;
        self.list[_fundNum].fees[_investor] += _value;
        self.list[_fundNum].paymentCycleStart[_investor] = now;
    }
}