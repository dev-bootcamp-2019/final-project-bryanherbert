pragma solidity ^0.5.0;

/** @title Struct Library
  * @author Bryan Herbert
  * @notice Defines data structures for the projects
  */
library StructLib{
    struct Data { mapping(uint => Fund) list; }

    struct Fund {
        //Fund Number
        uint fundNum;
        //Name of fund
        bytes32 name;
        //Partner who Initialized the strategy
        //Could be a multisig wallet
        address fundOwner;
        //amount of funds the strategy is virtually managing
        uint totalCapital;
        //Keep track of available capital
        uint capitalDeployed;
        //Add fee that quant can set- in whole number, i.e. 2% is represented as 2
        uint feeRate;
        //Number of days in Payment Cycle
        uint paymentCycle;
        //maps investors to investment status- current investors return true, non-investors return false
        mapping (address => bool) investors;
        //maps investors to their virtual balances in the strategy
        mapping (address => uint) virtualBalances;
        //maps investors to the actual fee they have stored in the FundMarketplace contract
        //fees are paid into fundOwner fee account and paid from investor fee account
        mapping (address => uint) fees;
        //Adoption Times for each investor
        mapping(address => uint) paymentCycleStart;
        //Boolean representing whether fund is in fundraising period
        bool fundraising;
        //Boolean representing whether fund is closed
        bool closed;
        //IPFS Multihash for Investment Prospectus
        Multihash investHash;
    }

    //IPFS multihash
    struct Multihash{
        bytes32 ipfsHash;
        uint8 hash_function;
        uint8 size;
    }
}