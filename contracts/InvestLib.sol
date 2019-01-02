pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../contracts/Misc.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library InvestLib {
    //Modifiers
    modifier verifyBalance(StructLib.Data storage self, bytes32 _name, uint _investment) {
        //Account Balance must be greater than investment + Fees
        //Not sure this correct- want it to represent ~2%
        uint fee = _investment/Misc.checkFeeRate(self, _name);
        require(
            msg.sender.balance > SafeMath.add(_investment,fee),
            "Sender does not have enough balance to invest"
        );
        _;
    }

    modifier verifyFee(StructLib.Data storage self, bytes32 _name, uint _investment, uint _proposedFee) {
        //Verify that the msg.value > fee
        require(
            _proposedFee >= SafeMath.div(_investment,Misc.checkFeeRate(self, _name)),
            "Fee is insufficient"
        );
        _;
    }
    function Invest(StructLib.Data storage self, bytes32 _name, uint _investment, address _investor, uint _value) 
    public
    verifyBalance(self, _name, _investment)
    verifyFee(self, _name, _investment, _value)
    {
        self.list[_name].totalCapital += _investment;
        self.list[_name].investors[_investor] = true;
        self.list[_name].virtualBalances[_investor] = _investment;
        self.list[_name].fees[_investor] = _value;
        self.list[_name].paymentCycleStart[_investor] = now;
    }
}