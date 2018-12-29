pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library CollectFeesLib {

    function collectFees(StructLib.Data storage self, bytes32 _name, address fundOwner)
    public
    returns (uint)
    {
        //Calculate fees
        uint feesCollected = self.list[_name].fees[fundOwner];
        self.list[_name].fees[fundOwner] = 0;
        fundOwner.transfer(feesCollected);
        return feesCollected;
    }
}