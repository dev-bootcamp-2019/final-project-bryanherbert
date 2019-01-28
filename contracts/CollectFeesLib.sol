pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";

library CollectFeesLib {
    modifier verifyOwnership(StructLib.Data storage self, uint _fundNum, address sender) {
        //Verify that fund exists by checking feeRate is not zero
        require(
            self.list[_fundNum].fundOwner == sender,
            "A non-owner is trying to submit an order to the fund"
        );
        _;
    }

    function collectFees(StructLib.Data storage self, uint _fundNum, address payable fundOwner)
    public
    verifyOwnership(self, _fundNum, msg.sender)
    returns (uint)
    {
        //Calculate fees
        uint feesCollected = self.list[_fundNum].fees[fundOwner];
        self.list[_fundNum].fees[fundOwner] = 0;
        fundOwner.transfer(feesCollected);
        return feesCollected;
    }
}