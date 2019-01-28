pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/** @title Order Library
  * @author Bryan Herbert
  * @notice Functionality to make state changes when a new order is placed
  */
library OrderLib{

    /** @dev Modifier that verifies ownership of the fund
      * @param self Data struct that contains fund information
      * @param _fundNum Fund number
      * @param sender placeholder for msg.sender
      */
    modifier verifyOwnership(StructLib.Data storage self, 
    uint _fundNum, 
    address sender) {
        require(
            self.list[_fundNum].fundOwner == sender,
            "A non-owner is trying to submit an order to the fund"
        );
        _;
    }

    /** @dev Handlees error checking for order placement
      * @dev Order is broadcast via the emission of the event in FundMarketplace.sol
      * @param self Data struct that contains fund information
      * @param _fundNum Fund number
      * @param _action Order action: buy or sell
      * @param _qty Number of shares
      * @param _price price per share (in finney
      * @dev uses verifyOwnership() modifier
      */
    function placeOrder(StructLib.Data storage self, 
    uint _fundNum, 
    bytes32 _action, 
    uint _qty, 
    uint _price)
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

    /** @dev Verifies two strings are the same using keccak256 hash of each string
      * @param a string to compare
      * @param b string to compare
      * @return bool Equality test of string
      */
    function compareStrings(bytes32 a, bytes32  b) public pure returns(bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /** @dev Calculates the quantity of shares for an investor's order based on their share of capital in the fund
      * @param self Data struct with information about funds
      * @param _fundNum Fund Number
      * @param qty Total number of shares
      * @return uint Number of shares for investor's order
      */
    function calcQty(StructLib.Data storage self,
     uint _fundNum, 
     uint qty
     ) 
     public view returns(uint) {
        //Couldn't use local variables because of stack too deep error
        //(Qty * Virtual Balance) / Total Capital
        return(SafeMath.div(SafeMath.mul(qty, self.list[_fundNum].virtualBalances[msg.sender]), self.list[_fundNum].totalCapital));
    }
}