pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StrategyHub.sol";

contract TestStrategyHub {

    //State Variables
    StrategyHub s;
    Quant quant;
    Investor investor;
    address quantAddr;
    address investorAddr;
    uint public initialBalance = 10 ether;
    bytes32 a;
    address b;
    uint c;
    uint d;
    uint e;
    bool f;
    uint g;
    uint h;

    function beforeAll(){
        //Deploy StrategyHub contracts
        s = new StrategyHub();
        //Deploy Quant and Investor contracts
        quant = new Quant();
        //Give the quant some ether
        address(quant).transfer(2 ether);
        investor = new Investor();
        address(investor).transfer(3 ether);
        quantAddr = address(quant);
        investorAddr = address(investor);
    }
  
    function testInitializeStrategy(){
        //Quant initializes new strategy
        bytes32 name = "alpha";
        uint initialFund = 1 ether;
        //feeRate is 2%
        uint feeRate = 2;
        //paymentCycle is in days
        uint paymentCycle = 0;
        quant.initializeStrategy(s, name, initialFund, feeRate, paymentCycle);

        (a,b,c,d) = s.getStratDetails(name);
        (e,f,g,h) = s. getStratDetails2(name, quantAddr);

        //Tests
        Assert.equal(a, name, "Strategy name does not match test name");
        Assert.equal(b, quantAddr, "Quant is not owner of strategy");
        Assert.equal(c, initialFund, "Strategy funds do not match test funds");
        Assert.equal(d, feeRate, "Fee Rate does not match test rate");
        Assert.equal(e, paymentCycle, "Payment Cycle does not match test cycle");
        Assert.equal(f, true, "Quant is not listed as investor");
        Assert.equal(g, initialFund, "Quant's funds are not listed");
        Assert.equal(h, 0, "Quant's fees deposited are not zero");
    }

    function testIsInvestor(){
        //Check to see if account is an investor in a certain strategy
        bytes32 name = "alpha";
        bool isInvestor = investor.checkInvestmentStatus(s, name);
        uint investment = 2 ether;

        (,,c,) = s.getStratDetails(name);
        (,f,g,h) = s.getStratDetails2(name, investorAddr);

        //Tests
        Assert.equal(isInvestor, false, "Account is incorrectly listed as investor");
        Assert.equal(c, 1 ether, "Initial account fund does not match initial balance");
        Assert.equal(f, false, "Account is incorrectly listed as investor");
        Assert.equal(g, 0, "Investor's virtual balance is not zero");
        Assert.equal(h, 0, "Investor's fees are not zero");

        //Make an actual investment
        investor.makeInvestment(s, name, investment);

        //Tests
        (,,c,) = s.getStratDetails(name);
        (,f,g,h) = s.getStratDetails2(name, investorAddr);

        //Tests
        Assert.equal(c, 3 ether, "Funds do not match sum of virtual balances");
        Assert.equal(f, true, "Account is not listed as investor");
        Assert.equal(g, 2 ether, "Investor's virtual balance does not match investment");
        Assert.equal(h, (investment/s.checkFeeRate(name)+1), "Investor's fees were not valid");
    }

    function testPayFees(){
        bytes32 name = "alpha";
        //Paid monthly; 12 times in a year
        uint timePeriod = 12;
        uint investment = 2 ether;
        uint fee = (investment/s.checkFeeRate(name)+1);

        //Pre Fee Tests
        //Quant
        (,,,h) = s.getStratDetails2(name, quantAddr);
        Assert.equal(h, 0, "Quant's fees were not zero");
        //Investor
        (,,,h) = s.getStratDetails2(name, investorAddr);
        Assert.equal(h, fee, "Investor's fees are not valid");

        investor.payFee(s, name, timePeriod);

        //Post Fee Tests
        //Quant
        (,,,h) = s.getStratDetails2(name, quantAddr);
        Assert.equal(h, fee/timePeriod, "Quant did not receive fee");
        //Investor
        (,,,h) = s.getStratDetails2(name, investorAddr);
        Assert.equal(h, fee - (fee/timePeriod), "Investor did not pay fee");
    }

    function testCollectFees(){
        bytes32 name = "alpha";
        uint quantBalance = 2 ether;
        uint investment = 2 ether;
        uint timePeriod = 12;
        uint feePayment = (investment/s.checkFeeRate(name)+1)/timePeriod;
        //Pre-collection tests
        Assert.equal(quantAddr.balance, quantBalance, "Quant account pre-balance is incorrect");

        //Collect Fees
        quant.collectFees(s, name);

        //Post-collection tests
        Assert.equal(quantAddr.balance, quantBalance + feePayment, "Quant account post-balance is incorrect");
    }


    function testWithdrawFunds(){
        bytes32 name = "alpha";
        uint preBalance = investorAddr.balance;
        //investor withdraws funds
        investor.withdrawFunds(s, name);
        uint postBalance = investorAddr.balance;

        //Tests
        (,,c,) = s.getStratDetails(name);
        (,f,g,h) = s.getStratDetails2(name, investorAddr);

        //Tests
        Assert.equal(c, 1 ether, "Funds do not match sum of virtual balances");
        Assert.equal(f, false, "Account falsely remain an investor");
        Assert.equal(g, 0, "Investor's virtual balance is not zeroed out");
        Assert.equal(h, 0, "Investor's fees are not zeroed out");
        //confirm fees were refunded
        Assert.isAbove(postBalance, preBalance, "Investor's fees were not transferred back successfully");
    }

}

contract Quant {

    function initializeStrategy(StrategyHub strategyHub, bytes32 _name, uint _initalFund, uint _feeRate, uint _paymentCycle) public {
        strategyHub.initializeStrat(_name, _initalFund, _feeRate, _paymentCycle);
    }

    function collectFees(StrategyHub strategyHub, bytes32 _name) public {
        strategyHub.collectFees(_name);
    }

    //Fallback function, accepts ether
    function() public payable {

    }
}

contract Investor {

    function checkInvestmentStatus(StrategyHub s, bytes32 _name) public view returns (bool) {
        return s.isInvestor(_name);
    }

    function makeInvestment(StrategyHub s, bytes32 _name, uint _investment) public {
        uint fee = _investment/s.checkFeeRate(_name) + 1;
        s.Invest.value(fee)(_name, _investment);
    }

    function payFee(StrategyHub s, bytes32 _name, uint _timePeriod) public {
        s.payFee(_name, _timePeriod);
    }

    function withdrawFunds(StrategyHub s, bytes32 _name) public {
        s.withdrawFunds(_name);
    }

    //Fallback function, accepts ether
    function() public payable{

    }

}
