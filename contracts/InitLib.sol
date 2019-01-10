pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library InitLib {
    
    //Modifiers
    //Make sure there are no funds with the same name
    modifier noDupName(StructLib.Data storage self, uint _fundCount, bytes32 _name) {
        require(
            self.list[_fundCount].name != _name,
            "Fund already exists with that name, please try another"
        );
        _;
    }
    
    function initializeFund(StructLib.Data storage self, uint _fundCount, bytes32 _name, address _fundOwner, uint _investment, uint _feeRate, uint _paymentCycle) 
    public
    noDupName(self, _fundCount, _name)
    {
        //initialize fund num to fundCount
        self.list[_fundCount].fundNum = _fundCount;
        //initialize strat name to _name
        self.list[_fundCount].name = _name;
        //Fund owner is message sender
        self.list[_fundCount].fundOwner = _fundOwner;
        //Initial funds are the msg.value
        self.list[_fundCount].totalCapital = _investment;
        //Set fee rate
        self.list[_fundCount].feeRate = _feeRate;
        //Set payment cycle
        self.list[_fundCount].paymentCycle = _paymentCycle;
        //set fundOwner to also be an investor
        self.list[_fundCount].investors[_fundOwner] = true;
        //set fundOwner's investor balance to the msg.value
        self.list[_fundCount].virtualBalances[_fundOwner] = _investment;
        //set fundOwner's fees to zero
        self.list[_fundCount].fees[_fundOwner] = 0;
    }
}