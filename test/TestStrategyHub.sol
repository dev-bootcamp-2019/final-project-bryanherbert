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
    uint d;
    bool e;
    uint f;
    uint g;

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
    uint feeRate = 2;
    quant.initializeStrategy(s, name, initialFund, feeRate);

    (a,b,c,d) = s.getStratDetails(count);
    (e,f,g) = s. getStratDetails2(count, quantAddress);

    //Tests
    Assert.equal(a, name, "Strategy name does not match test name");
    Assert.equal(b, quantAddress, "Quant is not owner of strategy");
    Assert.equal(c, initialFund, "Strategy funds do not match test funds");
    Assert.equal(d, feeRate, "Fee Rate does not match test rate");
    Assert.equal(e, true, "Quant is not listed as investor");
    Assert.equal(f, initialFund, "Quant's funds are not listed");
    Assert.equal(g, 0, "Quant's fees deposited are not zero");
  }

  function testIsInvestor(){
    //Check to see if account is an investor in a certain strategy
    address investorAddr = address(investor);
    uint stratNum = 0;
    bool isInvestor = investor.checkInvestmentStatus(s, stratNum);
    uint investment = 2 ether;

    (,,c,) = s.getStratDetails(stratNum);
    (e,f,g) = s.getStratDetails2(stratNum, investorAddr);

    //Tests
    Assert.equal(isInvestor, false, "Account is incorrectly listed as investor");
    Assert.equal(c, 1 ether, "Initial account fund does not match initial balance");
    Assert.equal(e, false, "Account is incorrectly listed as investor");
    Assert.equal(f, 0, "Investor's virtual balance is not zero");
    Assert.equal(g, 0, "Investor's fees are not zero");

    //Make an actual investment
    investor.makeInvestment(s, stratNum, investment);

    //Tests
    (,,c,) = s.getStratDetails(stratNum);
    (e,f,g) = s.getStratDetails2(stratNum, investorAddr);

    //Tests
    Assert.equal(c, 3 ether, "Funds do not match sum of virtual balances");
    Assert.equal(e, true, "Account is not listed as investor");
    Assert.equal(f, 2 ether, "Investor's virtual balance does not match investment");
    Assert.equal(g, (investment/s.checkFeeRate(stratNum)+1), "Investor's fees were not valid");
  }

}

contract Quant {

    function initializeStrategy(StrategyHub strategyHub, bytes32 _name, uint _initalFund, uint _feeRate) public {
        strategyHub.initializeStrat(_name, _initalFund, _feeRate);
    }

    //Fallback function, accepts ether
    function() public payable {

    }

}

contract Investor {

    function checkInvestmentStatus(StrategyHub s, uint _stratNum) public view returns (bool) {
        return s.isInvestor(_stratNum);
    }

    function makeInvestment(StrategyHub s, uint _stratNum, uint _investment) public {
        uint fee = _investment/s.checkFeeRate(_stratNum) + 1;
        s.Invest.value(fee)(_stratNum, _investment);
    }

    //Fallback function, accepts ether
    function() public payable{

    }

}
