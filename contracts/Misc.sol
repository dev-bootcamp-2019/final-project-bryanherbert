pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/** @title Misc
  * @author Bryan Herbert
  * @notice Handles miscellaneous functionality including checking the fee rate and checking if a fundExists
  */
library Misc {
    //Modifiers

    /** @dev Modifier that confirms a fund exists to prevent a user from subscribing to a fund that doesn't exist yet 
      * @param self Data struct that contains fund information
      * @param _fundNum Fund number
      */
    modifier fundExists(StructLib.Data storage self, uint _fundNum) {
        //Verify that fund exists by checking feeRate is not zero
        require(
            self.list[_fundNum].feeRate > 0,
            "Fund does not exist or feeRate is improperly set to 0"
        );
        _;
    }
    
    /** @dev Uses fee rate to calculate result that will be used in payment calculation
      * @param self Data struct with fund information
      * @param _fundNum Fund Number
      */
    function checkFeeRate(StructLib.Data storage self, uint _fundNum) 
    public view
    fundExists(self, _fundNum)
    returns (uint) {
        return SafeMath.div(100,self.list[_fundNum].feeRate);
    }
}