pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library WithdrawFundsLib {

    modifier maxWithdraw(StructLib.Data storage self, bytes32 _name, address _investor, uint _amount){
        require(
            //amount to withdraw is not more than balance in account
            _amount <= self.list[_name].virtualBalances[_investor],
            "Error: Investor is trying to withdraw more than account balance"
        );
        _;
    }

    function withdrawFunds(StructLib.Data storage self, bytes32 _name, address _investor, uint _amount)
    public
    maxWithdraw(self, _name, _investor, _amount)
    returns (uint, uint)
    {
        uint bal;
        uint fees;
        //Check for total or partial withdrawal
        //total withdrawal
        if(_amount == self.list[_name].virtualBalances[_investor]){
            //Need to make sure this matches up with withdraw philosophy
            //Temporary Balance and Fees
            bal = self.list[_name].virtualBalances[_investor];
            fees = self.list[_name].fees[_investor];
            //set investor status to faslse
            self.list[_name].investors[_investor] = false;
        } else{
            //partial withdrawal
            bal = _amount;
            //Need to think about how to handle fees in this case
            //Right now fees will not be withdrawn unless in the case of total withdrawal
            fees = 0;
        }
        //subtract virtual balance from total funds
        self.list[_name].totalCapital -= bal;
        //Subtract out balance
        self.list[_name].virtualBalances[_investor] -= bal;
        //transfer fees back to investor
        _investor.transfer(fees);
        //Substract out fees
        self.list[_name].fees[_investor] -= fees;
        return (bal, fees);
    }
}