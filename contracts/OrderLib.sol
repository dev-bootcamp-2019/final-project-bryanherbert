pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

library OrderLib{
    function placeOrder(StructLib.Data storage self, uint _fundNum, bytes memory _action, uint _qty, uint _price)
    public
    {
        bytes memory buy = "buy";
        bytes memory sell = "sell";
        
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

    function compareStrings(bytes memory a, bytes memory b) public pure returns(bool){
        return keccak256(a) == keccak256(b);
    }

    function calcQty(StructLib.Data storage self, uint _fundNum, uint qty) public view returns(uint) {
        //Investor's capital as a percentage of total funds
        //Need to incorporate Safe.Math for more robust solution
        return(SafeMath.div(SafeMath.mul(qty, self.list[_fundNum].virtualBalances[msg.sender]), self.list[_fundNum].totalCapital));
    }
}