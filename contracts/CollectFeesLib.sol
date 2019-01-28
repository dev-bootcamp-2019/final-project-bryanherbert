pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";

/** @title CollectFeesLib
  * @author Bryan Herbert
  * @notice Library for collect fees functionality including verifying ownership and transfering fees
  */
library CollectFeesLib {
    /**@dev Modifier to verify ownership of the fund that the user is requesting to collect fees from
      *@param self Data struct that contains all of the fund information
      *@param _fundNum Fund number
      *@param sender Placeholder for message sender
     */
    modifier verifyOwnership(StructLib.Data storage self, 
    uint _fundNum, 
    address sender) {
        //Verify that fund exists by checking feeRate is not zero
        require(
            self.list[_fundNum].fundOwner == sender,
            "A non-owner is trying to submit an order to the fund"
        );
        _;
    }

    /**@dev Allows manager of fund to make a state changes that empties his fees balance and transfer it to his account
      *@param self Data struct with fund information
      *@param _fundNum Fund number
      *@param fundOwner Fund owner
      *@return uint Fees Collected 
     */
    function collectFees(StructLib.Data storage self, 
    uint _fundNum, 
    address payable fundOwner)
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