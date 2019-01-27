pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library Misc {
    //check Fee Rate - read operation from struct
    function checkFeeRate(StructLib.Data storage self, uint _fundNum) 
    public view
    returns (uint) {
        return SafeMath.div(100,self.list[_fundNum].feeRate);
    }
}