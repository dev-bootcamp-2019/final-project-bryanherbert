pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library WithdrawFundsLib {

    function withdrawFunds(StructLib.Data storage self, bytes32 _name, address _investor)
    public
    returns (uint, uint)
    {
        //Need to make sure this matches up with withdraw philosophy
        //Temporary Balance and Fees
        uint bal = self.list[_name].virtualBalances[_investor];
        uint fees = self.list[_name].fees[_investor];
        //subtract virtual balance from total funds
        self.list[_name].totalCapital -= bal;
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