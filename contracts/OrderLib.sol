pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library OrderLib{
    modifier verifyOwnership(StructLib.Data storage self, uint _fundNum, address sender) {
        //Verify that fund exists by checking feeRate is not zero
        require(
            self.list[_fundNum].fundOwner == sender,
            "A non-owner is trying to submit an order to the fund"
        );
        _;
    }

    function placeOrder(StructLib.Data storage self, uint _fundNum, bytes32 _action, uint _qty, uint _price)
    verifyOwnership(self, _fundNum, msg.sender)
    public
    {
        bytes32 buy = "buy";
        bytes32 sell = "sell";
        
        if(compareStrings(_action, buy)){
            require(
                //Cost of trade is price * qty
                self.list[_fundNum].totalCapital > SafeMath.mul(_price,_qty),
                "Cost of trade is greater than balance of fund"
            );
            self.list[_fundNum].capitalDeployed += SafeMath.mul(_price, _qty);
        }
        else if(compareStrings(_action, sell)){
            self.list[_fundNum].capitalDeployed -= SafeMath.mul(_price, _qty);
        }
        else{
            revert("Not a valid action");
        }
    }

    function compareStrings(bytes32 a, bytes32  b) public pure returns(bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function calcQty(StructLib.Data storage self, uint _fundNum, uint qty) public view returns(uint) {
        //Investor's capital as a percentage of total funds
        //Need to incorporate Safe.Math for more robust solution
        return(SafeMath.div(SafeMath.mul(qty, self.list[_fundNum].virtualBalances[msg.sender]), self.list[_fundNum].totalCapital));
    }
}