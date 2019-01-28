pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library Misc {
    modifier fundExists(StructLib.Data storage self, uint _fundNum) {
        //Verify that fund exists by checking feeRate is not zero
        require(
            self.list[_fundNum].feeRate > 0,
            "Fund does not exist or feeRate is improperly set to 0"
        );
        _;
    }
    //check Fee Rate - read operation from struct
    function checkFeeRate(StructLib.Data storage self, uint _fundNum) 
    public view
    fundExists(self, _fundNum)
    returns (uint) {
        return SafeMath.div(100,self.list[_fundNum].feeRate);
    }
}