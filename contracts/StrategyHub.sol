pragma solidity ^0.4.24;

contract StrategyHub {
    //State Variables
    address owner;
    //maybe change uint to name of strategy
    mapping(uint => Strategy) public strategies;
    uint stratCount;

    struct Strategy {
        //Name of strategy
        bytes32 name;
        //Quant who initialized the strategy
        address stratOwner;
        //amount of funds the strategy is virtually managing
        uint funds;
        //Add fee that quant can set- in whole number, i.e. 2% is represented as 2
        uint feeRate;
        //maps investors to investment status- current investors return true, non-investors return false
        mapping (address => bool) investors;
        //maps investors to their virtual balances in the strategy
        mapping (address => uint) virtualBalances;
        //maps investors to the actual fee they have stored in the Strategy Hub contract
        //fees are paid into stratOwner fee account and paid from investor fee account
        mapping (address => uint) fees;
        //will need to add IPFS hash eventually to verify code

    }

    //Events
    event StrategyCreated(
        uint stratNum,
        address stratOwner
    );

    //Modifiers
    modifier verifyBalance(uint _stratNum, address _account, uint _investment){
        //Account Balance must be greater than investment + Fees
        //Not sure this correct- want it to represent ~2%
        uint fee = _investment/checkFeeRate(_stratNum);
        require(
            _account.balance > _investment + fee,
            "Sender does not have enough balance to invest"
        );
        _;
    }

    modifier verifyFee(uint _stratNum, uint _investment, uint _proposedFee) {
        //Verify that the msg.value > fee
        require(
            _proposedFee >= _investment/checkFeeRate(_stratNum),
            "Fee is insufficent"
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
        //initialize strategy count to 0
        stratCount = 0;
    }

    function initializeStrat(bytes32 _name, uint _investment, uint _feeRate) public payable {
        //initialize strat name to _name
        strategies[stratCount].name = _name;
        //Strat owner is message sender
        strategies[stratCount].stratOwner =  msg.sender;
        //Initial funds are the msg.value
        strategies[stratCount].funds = _investment;
        //Set fee rate
        strategies[stratCount].feeRate = _feeRate;
        //set stratOwner to also be an investor
        strategies[stratCount].investors[msg.sender] = true;
        //set stratOwner's investor balance to the msg.value
        strategies[stratCount].virtualBalances[msg.sender] = _investment;
        //set stratOwner's fees to zero
        strategies[stratCount].fees[msg.sender] = 0;
        //Emit Event
        emit StrategyCreated(stratCount, msg.sender);
        //Increment stratCount
        stratCount++;

    }

    //Check to see if an account is an investor in a strategy
    function isInvestor(uint _stratNum) public view returns (bool) {
        return strategies[_stratNum].investors[msg.sender];
    }

    //Make investment into particular fund
    //Must have required funds
    function Invest(uint _stratNum, uint _investment) public payable 
    verifyBalance(_stratNum, msg.sender, _investment) 
    verifyFee(_stratNum, _investment, msg.value) 
    returns (bool) {
        strategies[_stratNum].funds += _investment;
        strategies[_stratNum].investors[msg.sender] = true;
        strategies[_stratNum].virtualBalances[msg.sender] = _investment;
        strategies[_stratNum].fees[msg.sender] = msg.value;
        return strategies[_stratNum].investors[msg.sender];
    }

    //check fee rate
    function checkFeeRate(uint _stratNum) public view returns (uint) {
        return 100/strategies[_stratNum].feeRate;
    }

    function withdrawFunds(uint _stratNum) public {
        //Need to make sure this matches up with withdraw philosophy
        //Add event
        //subtract virtual balance from total funds
        strategies[_stratNum].funds -= strategies[_stratNum].virtualBalances[msg.sender];
        //zero out virtual Balance
        strategies[_stratNum].virtualBalances[msg.sender] = 0;
        //transfer fees back to investor
        msg.sender.transfer(strategies[_stratNum].fees[msg.sender]);
        //Zero out fees
        strategies[_stratNum].fees[msg.sender] = 0;
        //set investor status to faslse
        strategies[_stratNum].investors[msg.sender] = false;
    }

    //not a permanent function
    function getStratDetails(uint _stratNum) public view returns (bytes32, address, uint, uint){
        return (strategies[_stratNum].name, 
        strategies[_stratNum].stratOwner, 
        strategies[_stratNum].funds, 
        strategies[_stratNum].feeRate);
    }
    //need two functions because of stack height
    function getStratDetails2(uint _stratNum, address _addr) public view returns (bool, uint, uint){
        return(strategies[_stratNum].investors[_addr], 
        strategies[_stratNum].virtualBalances[_addr],
        strategies[_stratNum].fees[_addr]);
    }
}
