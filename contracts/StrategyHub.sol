pragma solidity ^0.4.24;

contract StrategyHub {
    //State Variables
    address owner;
    mapping(uint => Strategy) public strategies;
    uint stratCount;

    struct Strategy {
        //Name of strategy
        bytes32 name;
        //Quant who initialized the strategy
        address stratOwner;
        //amount of funds the strategy is virtually managing
        uint funds;
        //maps investors to investment status- current investors return true, non-investors return false
        mapping (address => bool) investors;
        //maps investors to their virtual balances in the strategy
        mapping (address => uint) balances;
        //will need to add IPFS hash eventually to verify code

    }

    //Events
    event StrategyCreated(
        uint stratNum,
        address stratOwner
    );

    constructor() public {
        owner = msg.sender;
        //initialize strategy count to 0
        stratCount = 0;
    }

    function initializeStrat(bytes32 _name) public payable {
        //initialize strat name to _name
        strategies[stratCount].name = _name;
        //Strat owner is message sender
        strategies[stratCount].stratOwner =  msg.sender;
        //Initial funds are the msg.value
        strategies[stratCount].funds = msg.value;
        //set stratOwner to also be an investor
        strategies[stratCount].investors[msg.sender] = true;
        //set stratOwner's investor balance to the msg. value
        strategies[stratCount].balances[msg.sender] = msg.value;
        //Emit Event
        emit StrategyCreated(stratCount, msg.sender);
        //Increment stratCount
        stratCount++;

    }

    //not a permanent function
    function getStratDetails(uint _stratNum, address stratOwner) public view returns (bytes32, address, uint, bool, uint){
        return (strategies[_stratNum].name, 
        strategies[0].stratOwner, 
        strategies[0].funds, 
        strategies[0].investors[stratOwner], 
        strategies[0].balances[stratOwner]);
    }
  
}
