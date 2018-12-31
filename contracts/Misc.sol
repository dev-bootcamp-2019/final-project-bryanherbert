pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library Misc {
    //check Fee Rate - read operation from struct
    function checkFeeRate(StructLib.Data storage self, bytes32 _name) 
    public view
    returns (uint) {
        return SafeMath.div(100,self.list[_name].feeRate);
    }
}