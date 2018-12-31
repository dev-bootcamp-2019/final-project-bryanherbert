pragma solidity ^0.4.24;

import "../contracts/StructLib.sol";

library OrderLib{
    function placeOrder(StructLib.Data storage self, bytes32 _name, bytes memory _action, uint _price)
    public
    {
        bytes memory buy = "buy";
        bytes memory sell = "sell";
        
        if(compareStrings(_action, buy)){
            require(
                self.list[_name].totalCapital > _price,
                "Cost of trade is greater than balance of fund"
            );
            self.list[_name].capitalDeployed += _price;
        }
        else if(compareStrings(_action, sell)){
            self.list[_name].capitalDeployed -= _price;
        }
        else{
            revert("Not a valid action");
        }
    }

    function compareStrings(bytes memory a, bytes memory b) public pure returns(bool){
        return keccak256(a) == keccak256(b);
    }

    function calcQty(StructLib.Data storage self, bytes32 _name, uint qty) public view returns(uint) {
        //Investor's capital as a percentage of total funds
        //Need to incorporate Safe.Math for more robust solution
        return ((qty * self.list[_name].virtualBalances[msg.sender])/self.list[_name].totalCapital);
    }
}