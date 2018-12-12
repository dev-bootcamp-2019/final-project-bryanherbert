pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StrategyHub.sol";

contract TestStrategyHub {

    //State Variables
    StrategyHub s;
    Quant quant;
    Investor investor;
    uint public initialBalance = 10 ether;
    bytes32 a;
    address b;
    uint c;
    bool d;
    uint e;

  function beforeAll(){
    //Deploy StrategyHub contracts
    s = new StrategyHub();
    //Deploy Quant and Investor contracts
    quant = new Quant();
    //Give the quant some ether
    address(quant).transfer(2 ether);
    investor = new Investor();
    address(investor).transfer(3 ether);
  }
  
  function testInitializeStrategy(){
    //Quant initializes new strategy
    bytes32 name = "alpha";
    address quantAddress = address(quant);
    uint initialFund = 1 ether;
    uint count = 0;
    quant.initializeStrategy(s, name, initialFund);

    (a,b,c,d,e) = s.getStratDetails(count, quantAddress);

    //Tests
    Assert.equal(a, name, "Strategy name does not match test name");
    Assert.equal(b, quantAddress, "Quant is not owner of strategy");
    Assert.equal(c, initialFund, "Strategy funds do not match test funds");
    Assert.equal(d, true, "Quant is not listed as investor");
    Assert.equal(e, initialFund, "Quant's funds are not listed");
  }

  function testIsInvestor(){
    //Check to see if account is an investor in a certain strategy
    address investorAddr = address(investor);
    uint stratNum = 0;
    investor.checkInvestmentStatus(s, stratNum);
    uint investment = 2 ether;

    (,,,d,e) = s.getStratDetails(stratNum, investorAddr);

    //Tests
    Assert.equal(d, false, "Account is incorrectly listed as investor");
    Assert.equal(e, 0, "Account balance should be empty");

    //Make an actual investment
    investor.makeInvestment(s, stratNum, investment);

    (,,,d,e) = s.getStratDetails(stratNum, investorAddr);

    //Tests
    Assert.equal(d, true, "Account is incorrectly listed as not an investor");
    Assert.equal(e, investment, "Account balance is not empty");
  }

}

contract Quant {

    function initializeStrategy(StrategyHub strategyHub, bytes32 _name, uint _fund) public {
        strategyHub.initializeStrat.value(_fund)(_name);
    }

    //Fallback function, accepts ether
    function() public payable {

    }

}

contract Investor {

    function checkInvestmentStatus(StrategyHub s, uint _stratNum) public {
        s.isInvestor(_stratNum);
    }

    function makeInvestment(StrategyHub s, uint _stratNum, uint _investment) public {
        //2% fee
        uint fee = _investment/50 + 1;
        s.Invest.value(fee)(_stratNum, _investment);
    }

    //Fallback function, accepts ether
    function() public payable{

    }

}
