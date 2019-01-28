pragma solidity ^0.5.0;

import "../contracts/StructLib.sol";

/** @title Init Library
  * @author Bryan Herbert
  * @notice Functionality to make state changes to initialize a fund
  */
library InitLib {
    
    //Modifiers
    
    /**@dev Modifier to make sure there are no funds with the same name
      *@param self Data Struct with fund information
      *@param _fundCount # of funds
      *@param _name Proposed fund name
     */
    modifier noDupName(StructLib.Data storage self, 
    uint _fundCount, 
    bytes32 _name) {
        for(uint i = _fundCount; i > 0; i--){
            require(
                //no duplicate names in any contract
                self.list[_fundCount].name != _name,
                "Fund already exists with that name, please try another"
            );
        }
        _;
    }

    /**@dev Makes state changes to add the associated Multihash struct to Fund struct
      *@param self Data struct with fund information
      *@param ipfsHash Digest portion of ipfs hash
      *@param hash_function Hash function portion of ipfs hash
      *@param size Size of ipfs hash function
      *@param _fundCount Current number of funds
     */
    function addHash(StructLib.Data storage self, 
    bytes32 ipfsHash, 
    uint8 hash_function, 
    uint8 size, 
    uint _fundCount)
    internal
    {
        self.list[_fundCount].investHash.ipfsHash = ipfsHash;
        self.list[_fundCount].investHash.hash_function = hash_function;
        self.list[_fundCount].investHash.size = size;

    }
    
    /**@dev Initializes a new Fund Struct and sets member values to the funcion arguments
      *@param self Data struct with fund information
      *@param _fundCount Current Number of Funds
      *@param _name Fund name
      *@param _fundOwner Fund owner
      *@param _investment Virtual Capital committed to the fund
      *@param _feeRate Annual fee rate
      *@param _paymentCycle Payment cycle in days
      *@param ipfsHash digest porition of ipfs hash
      *@param hash_function hash function of ipfs hash
      *@param size size of ipfs hash function
      *@dev Uses noDupName modifer and has a require() statement that the message sender is the declared fundOwner
    */
    function initializeFund(
        StructLib.Data storage self, 
        uint _fundCount, 
        bytes32 _name, 
        address _fundOwner, 
        uint _investment, 
        uint _feeRate, 
        uint _paymentCycle,
        bytes32 ipfsHash,
        uint8 hash_function,
        uint8 size) 
    public
    noDupName(self, _fundCount, _name)
    {
        //Make sure that Message Sender is the same as the declared fund Owner
        require(
            _fundOwner == msg.sender,
            "Message Sender has not listed themselves as fund owner"
        );
        uint count = _fundCount + 1;
        //initialize fund num to fundCount
        self.list[count].fundNum = count;
        //initialize strat name to _name
        self.list[count].name = _name;
        //Fund owner is message sender
        self.list[count].fundOwner = _fundOwner;
        //Initial funds are the msg.value
        self.list[count].totalCapital = _investment;
        //Set fee rate
        self.list[count].feeRate = _feeRate;
        //Set payment cycle
        self.list[count].paymentCycle = _paymentCycle;
        //set fundOwner to also be an investor
        self.list[count].investors[_fundOwner] = true;
        //set fundOwner's investor balance to the msg.value
        self.list[count].virtualBalances[_fundOwner] = _investment;
        //set fundOwner's fees to zero
        self.list[count].fees[_fundOwner] = 0;
        //set fundraising to 1
        self.list[count].fundraising = true;
        //set closed to 0
        self.list[count].closed = false;
        addHash(self, ipfsHash, hash_function, size, count);
    }
}