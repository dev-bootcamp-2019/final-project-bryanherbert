pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../contracts/Misc.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library InvestLib {
    //Modifiers
    modifier verifyBalance(StructLib.Data storage self, uint _fundNum, uint _investment) {
        //Account Balance must be greater than investment + Fees
        //Not sure this correct- want it to represent ~2%
        uint fee = _investment/Misc.checkFeeRate(self, _fundNum);
        require(
            msg.sender.balance > SafeMath.add(_investment,fee),
            "Sender does not have enough balance to invest"
        );
        _;
    }

    modifier verifyFee(StructLib.Data storage self, uint _fundNum, uint _investment, uint _proposedFee) {
        //Verify that the msg.value > fee
        require(
            _proposedFee >= SafeMath.div(_investment,Misc.checkFeeRate(self, _fundNum)),
            "Fee is insufficient"
        );
        _;
    }
    function Invest(StructLib.Data storage self, uint _fundNum, uint _investment, address _investor, uint _value) 
    public
    verifyBalance(self, _fundNum, _investment)
    verifyFee(self, _fundNum, _investment, _value)
    {
        self.list[_fundNum].totalCapital += _investment;
        self.list[_fundNum].investors[_investor] = true;
        //might need to adjust for re-invest
        self.list[_fundNum].virtualBalances[_investor] += _investment;
        //might need to adjust for re-invest
        self.list[_fundNum].fees[_investor] += _value;
        self.list[_fundNum].paymentCycleStart[_investor] = now;
    }
}