pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library InitLib {
    
    //Modifiers
    //Make sure there are no funds with the same name
    modifier noDupName(StructLib.Data storage self, bytes32 _name) {
        require(
            self.list[_name].name != _name,
            "Fund already exists with that name, please try another"
        );
        _;
    }
    
    function initializeFund(StructLib.Data storage self, bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) 
    public
    noDupName(self, _name)
    {
        //initialize strat name to _name
        self.list[_name].name = _name;
        //Strat owner is message sender
        //Be careful of message sender here - might be the Fund Marketplace contract - might have to use delegatecall
        self.list[_name].fundOwner = _fundOwner;
        //Initial funds are the msg.value
        self.list[_name].totalCapital = _investment;
        //Set fee rate
        self.list[_name].feeRate = _feeRate;
        //Set payment cycle
        self.list[_name].paymentCycle = _paymentCycle;
        //set fundOwner to also be an investor
        self.list[_name].investors[_fundOwner] = true;
        //set fundOwner's investor balance to the msg.value
        self.list[_name].virtualBalances[_fundOwner] = _investment;
        //set fundOwner's fees to zero
        self.list[_name].fees[_fundOwner] = 0;
    }
}