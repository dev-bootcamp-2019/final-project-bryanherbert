pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library Misc {
    //check Fee Rate - read operation from struct
    function checkFeeRate(StructLib.Data storage self, bytes32 _name) 
    public view
    returns (uint) {
        return 100/self.list[_name].feeRate;
    }
}