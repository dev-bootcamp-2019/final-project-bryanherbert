pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/FundMarketplace.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract TestFundMarketplace {

    //State Variables
    //FundMarketplace contract
    FundMarketplace fm;
    //Manager contract (at bottom)
    Manager manager;
    //Investor contract (at bottom)
    Investor investor;
    address managerAddr;
    address investorAddr;
    uint public initialBalance = 10 ether;
    uint fundNum;
    bytes32 a; //name
    address b; //fundOwner
    uint c; //totalCapital
    uint d; //capitalDeployed
    uint e; //Fee Rate
    uint f; //Payment Cycle
    bool g; //Investor Status
    uint h; //Virtual Balance
    uint i; //Investor Fees
    bytes32 j; //digest of ipfs hash
    uint8 k; //hashfunction
    uint8 l; //hash function size

    function beforeAll() public {
        //Deploy FundMarketplace contracts
        fm = FundMarketplace(DeployedAddresses.FundMarketplace());
        //Deploy Manager and Investor contracts
        manager = new Manager();
        //Give the manager some ether
        address(manager).transfer(2 ether);
        investor = new Investor();
        //Give the investor some ether
        address(investor).transfer(3 ether);
        managerAddr = address(manager);
        investorAddr = address(investor);
    }
  
    function testInitializeFund() public{
        //Manager initializes new fund
        fundNum = 1;
        bytes32 name = "alpha";
        uint initialFund = 1 ether;
        //feeRate is 2%
        uint feeRate = 2;
        //paymentCycle is in unit of days
        //made it zero days for testing purposes
        uint paymentCycle = 30;
        //Multihash
        bytes32 digest = 0x7D5A99F603F231D53A4F39D1521F98D2E8BB279CF29BEBFD0687DC98458E7F89;
        uint8 hash_function = 0x12;
        uint8 size = 0x20;

        manager.initializeFund(fm, name, initialFund, feeRate, paymentCycle, digest, hash_function, size);

        (a,b,c,d,e,f) = fm.getFundDetails(fundNum);
        (g,h,i) = fm. getFundDetails2(fundNum, managerAddr);
        (j,k,l) = fm.getIpfsHash(fundNum);

        //Tests
        Assert.equal(a, name, "Strategy name does not match test name");
        Assert.equal(b, managerAddr, "Manager is not owner of strategy");
        Assert.equal(c, initialFund, "Strategy funds do not match test funds");
        Assert.equal(d, 0, "Deployed Capital is not equal to zero");
        Assert.equal(e, feeRate, "Fee Rate does not match test rate");
        Assert.equal(f, paymentCycle, "Payment Cycle does not match test cycle");
        Assert.equal(g, true, "Manager is not listed as investor");
        Assert.equal(h, initialFund, "Manager's funds are not listed");
        Assert.equal(i, 0, "Manager's fees deposited are not zero");
        Assert.equal(j, digest, "digest of ipfs hash does not match test value");
        Assert.equal(uint(k), uint(hash_function), "hash_function of ipfs hash does not match test value");
        Assert.equal(uint(l), uint(size), "size of ipfs hash does not match test value");
    }

    function testInvestment() public{
        //Investor account will invest 2 ether into Fund Number 1
        uint investment = 2 ether;

        (,,c,,,) = fm.getFundDetails(fundNum);
        (g,h,i) = fm.getFundDetails2(fundNum, investorAddr);

        //Tests
        Assert.equal(c, 1 ether, "Initial account fund does not match initial balance");
        Assert.equal(g, false, "Account is incorrectly listed as investor");
        Assert.equal(h, 0, "Investor's virtual balance is not zero");
        Assert.equal(i, 0, "Investor's fees are not zero");

        //Make an actual investment
        investor.makeInvestment(fm, fundNum, investment);

        //Tests
        (,,c,,,) = fm.getFundDetails(fundNum);
        (g,h,i) = fm.getFundDetails2(fundNum, investorAddr);

        //Tests
        Assert.equal(c, 3 ether, "Funds do not match sum of virtual balances");
        Assert.equal(g, true, "Account is not listed as investor");
        Assert.equal(h, 2 ether, "Investor's virtual balance does not match investment");
        Assert.equal(i, SafeMath.add(SafeMath.div(investment, fm.checkFeeRate(fundNum)), 1), "Investor's fees were not valid");
    }
    
    function testPlaceOrder() public {
        //Manager will place an order for the following "Buy 3 PLNT at an execution price of 100 finney"
        bytes32 action = "buy";
        bytes32 ticker = "PLNT";
        uint qty = 3;
        //Price of individual security
        uint price = 100 finney; //0.0001 ether

        //Test to make sure deployed capital is zero
        uint capDeploy;
        (,,,capDeploy,,) = fm.getFundDetails(fundNum);
        Assert.equal(capDeploy, 0, "Capital Deployed is not 0");

        manager.placeOrder(fm, fundNum, action, ticker, qty, price);

        //Read Capital Deployed
        (,,,capDeploy,,) = fm.getFundDetails(fundNum);
        //Check to make sure capital was deployed
        Assert.equal(capDeploy, SafeMath.mul(price,qty), "Capital was not successfully deployed");
    }

    function testReceiveOrder() public {
        //Orders are received by listening for events
        //Therefore cannot test for receiving the actual order
        
        //Test for calculating correct quantity of shares for investor order based on share of capital in fund
        uint qty = 3;
        uint actual = 2;

        uint test = investor.calcQty(fm, fundNum, qty);

        Assert.equal(test, actual, "Wrong quantity returned");
    }


    function testWithdrawFunds() public {
        //Test for both a partial and a full withdrawal
        //Investor's pre-withdrawal balance
        uint preBalance = investorAddr.balance;
        //Partial withdrawal amount
        uint amount = 1 ether;
        uint currentFees;
        (,,currentFees) = fm.getFundDetails2(fundNum, investorAddr);

        //investor withdraw a portion of his funds
        investor.withdrawFunds(fm, fundNum, amount);
        uint midBalance = investorAddr.balance;

        //Tests
        (,,c,,,) = fm.getFundDetails(fundNum);
        (g,h,i) = fm.getFundDetails2(fundNum, investorAddr);

        Assert.equal(c, 2 ether, "Funds do not match sum of virtual balances");
        Assert.equal(g, true, "Account should still be listed as an investor");
        Assert.equal(h, 1 ether, "Investor's should not be zeroed out");
        Assert.equal(i, currentFees, "Investor's fees should not change");
        Assert.equal(midBalance, preBalance, "Midbalance should be equal to preBalance");

        //investor withdraws remainder of funds
        investor.withdrawFunds(fm, fundNum, amount);
        uint postBalance = investorAddr.balance;

        //Tests
        (,,c,,,) = fm.getFundDetails(fundNum);
        (g,h,i) = fm.getFundDetails2(fundNum, investorAddr);

        //Tests
        Assert.equal(c, 1 ether, "Funds do not match sum of virtual balances");
        Assert.equal(g, false, "Account falsely remain an investor");
        Assert.equal(h, 0, "Investor's virtual balance is not zeroed out");
        Assert.equal(i, 0, "Investor's fees are not zeroed out");
        //confirm fees were refunded
        Assert.isAbove(postBalance, preBalance, "Investor's fees were not transferred back successfully");
    }

    function testCloseFund() public {
        //Test to verify a manager can close a fund and that the fundCount decreases
        
        //Tests
        (,g) = fm.checkFundStatus(fundNum);
        uint fundCount_old = fm.fundCount();
        Assert.equal(g, false, "Fund Details were incorrect");
        
        //Delete Fund
        manager.closeFund(fm, fundNum);

        //Tests
        (,g) = fm.checkFundStatus(fundNum);
        uint fundCount_new = fm.fundCount();
        Assert.equal(g, true, "Fund Details were incorrect");
        Assert.equal(fundCount_new, fundCount_old-1, "Fund count was not correctly updated");
    }

}

contract Manager {

    //All functions call functions in FundMarketplace.sol from manager address

    function initializeFund(FundMarketplace fm, bytes32 _name, uint _initalFund, uint _feeRate, uint _paymentCycle, bytes32 _digest, uint8 _hash_function, uint8 _size) 
    external 
    {
        fm.initializeFund(_name, address(this), _initalFund, _feeRate, _paymentCycle, _digest, _hash_function, _size);
    }


    function placeOrder(FundMarketplace fm, uint _fundNum, bytes32 _action, bytes32 _ticker, uint _qty, uint _price)
    external
    {
        fm.placeOrder(_fundNum, _action, _ticker, _qty, _price);
    }

    function closeFund(FundMarketplace fm, uint _fundNum)
    external
    {
        fm.closeFund(_fundNum);
    }

    //Fallback function, accepts ether
    function() external payable {
    }
}

contract Investor {

    //All functions call functions in FundMarketplace.sol from investor address
    function makeInvestment(FundMarketplace fm, uint _fundNum, uint _investment) 
    external 
    {
        //Fee calculated by dividing investment by the result from checkFeeRate() and adding 1 to round
        uint fee = SafeMath.add(SafeMath.div(_investment, fm.checkFeeRate(_fundNum)), 1);
        fm.Invest.value(fee)(_fundNum, _investment);
    }

    function withdrawFunds(FundMarketplace fm, uint _fundNum, uint _amount) 
    external 
    {
        fm.withdrawFunds(_fundNum, _amount);
    }

    //Calculates the quantity of shares an investor will receive in their customized order
    function calcQty(FundMarketplace fm, uint _fundNum, uint qty) 
    external view returns (uint) 
    {
        return fm.calcQty(_fundNum, qty);
    }

    //Fallback function, accepts ether
    function() external payable{

    }
}