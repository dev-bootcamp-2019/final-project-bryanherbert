pragma solidity ^0.4.24;

library StructLib{
    struct Data { mapping(bytes32 => Fund) list; }

    struct Fund {
        //Name of fund
        bytes32 name;
        //Partner who Initialized the strategy
        //Could be a multisig wallet
        address fundOwner;
        //amount of funds the strategy is virtually managing
        uint totalBalance;
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
        //maps investors to the actual fee they have stored in the Strategy Hub contract
        //fees are paid into stratOwner fee account and paid from investor fee account
        mapping (address => uint) fees;
        //Adoption Times for each investor
        mapping(address => uint) paymentCycleStart;
        //will need to add IPFS hash eventually to verify code
    }
}