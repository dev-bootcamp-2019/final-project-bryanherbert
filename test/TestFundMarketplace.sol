pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/FundMarketplace.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract TestFundMarketplace {

    //State Variables
    FundMarketplace fm;
    Manager manager;
    Investor investor;
    address managerAddr;
    address investorAddr;
    uint public initialBalance = 10 ether;
    uint fundNum;
    bytes32 a;
    address b;
    uint c;
    uint d;
    uint e;
    uint f;
    bool g;
    uint h;
    uint i;

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
  
    // function testInitializeFund() public{
    //     //Manager initializes new strategy
    //     fundNum = 1;
    //     bytes32 name = "alpha";
    //     uint initialFund = 1 ether;
    //     //feeRate is 2%
    //     uint feeRate = 2;
    //     //paymentCycle is in unit of days
    //     uint paymentCycle = 0;
    //     manager.initializeFund(fm, name, initialFund, feeRate, paymentCycle);

    //     (a,b,c,d,e,f) = fm.getFundDetails(fundNum);
    //     (g,h,i) = fm. getFundDetails2(fundNum, managerAddr);

    //     //Tests
    //     Assert.equal(a, name, "Strategy name does not match test name");
    //     Assert.equal(b, managerAddr, "Manager is not owner of strategy");
    //     Assert.equal(c, initialFund, "Strategy funds do not match test funds");
    //     Assert.equal(d, 0, "Deployed Capital is not equal to zero");
    //     Assert.equal(e, feeRate, "Fee Rate does not match test rate");
    //     Assert.equal(f, paymentCycle, "Payment Cycle does not match test cycle");
    //     Assert.equal(g, true, "Manager is not listed as investor");
    //     Assert.equal(h, initialFund, "Manager's funds are not listed");
    //     Assert.equal(i, 0, "Manager's fees deposited are not zero");
    // }

    function testInvestment() public{
        //Check to see if account is an investor in a certain strategy
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
        //bytes used for string comparison in OrderLib compareStrings()
        bytes32 action = "buy";
        bytes32 ticker = "PLNT";
        uint qty = 3;
        //Price of individual security
        uint price = 100 szabo; //0.0001 ether

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
        uint qty = 3;
        uint actual = 2;

        uint test = investor.calcQty(fm, fundNum, qty);

        Assert.equal(test, actual, "Wrong quantity returned");
    }

    function testPayFees() public {
        //Paid monthly; 12 times in a year
        uint timePeriod = 12;
        uint investment = 2 ether;
        uint fee = SafeMath.add(SafeMath.div(investment, fm.checkFeeRate(fundNum)),1);

        //Pre Fee Tests
        //Manager
        (,,i) = fm.getFundDetails2(fundNum, managerAddr);
        Assert.equal(i, 0, "Manager's fees were not zero");
        //Investor
        (,,i) = fm.getFundDetails2(fundNum, investorAddr);
        Assert.equal(i, fee, "Investor's fees are not valid");

        investor.payFee(fm, fundNum, timePeriod);

        //Post Fee Tests
        //Manager
        (,,i) = fm.getFundDetails2(fundNum, managerAddr);
        Assert.equal(i, SafeMath.div(fee,timePeriod), "Manager did not receive fee");
        //Investor
        (,,i) = fm.getFundDetails2(fundNum, investorAddr);
        Assert.equal(i, SafeMath.sub(fee, SafeMath.div(fee, timePeriod)), "Investor did not pay fee");
    }

    function testCollectFees() public {
        uint managerBalance = 2 ether;
        uint investment = 2 ether;
        uint timePeriod = 12;
        uint feePayment = SafeMath.div(SafeMath.add(SafeMath.div(investment, fm.checkFeeRate(fundNum)), 1), timePeriod);
        //Pre-collection tests
        Assert.equal(managerAddr.balance, managerBalance, "manager account pre-balance is incorrect");

        //Collect Fees
        manager.collectFees(fm, fundNum);

        //Post-collection tests
        Assert.equal(managerAddr.balance, SafeMath.add(managerBalance, feePayment), "Manager account post-balance is incorrect");
    }

    function testWithdrawFunds() public {
        uint preBalance = investorAddr.balance;
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
        //Not sure why gas costs aren't lowering midBalance compared to preBalance
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

    // function initializeFund(FundMarketplace fm, bytes32 _name, uint _initalFund, uint _feeRate, uint _paymentCycle) 
    // external 
    // {
    //     fm.initializeFund(_name, address(this), _initalFund, _feeRate, _paymentCycle);
    // }

    function collectFees(FundMarketplace fm, uint _fundNum) 
    external 
    {
        fm.collectFees(_fundNum);
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

    function setStopped(FundMarketplace fm)
    external{
        fm.setStopped();
    }

    //Fallback function, accepts ether
    function() external payable {
    }
}

contract Investor {

    function makeInvestment(FundMarketplace fm, uint _fundNum, uint _investment) 
    external 
    {
        uint fee = SafeMath.add(SafeMath.div(_investment, fm.checkFeeRate(_fundNum)), 1);
        fm.Invest.value(fee)(_fundNum, _investment);
    }

    function payFee(FundMarketplace fm, uint _fundNum, uint _timePeriod) 
    external 
    {
        fm.payFee(_fundNum, _timePeriod);
    }

    function withdrawFunds(FundMarketplace fm, uint _fundNum, uint _amount) 
    external 
    {
        fm.withdrawFunds(_fundNum, _amount);
    }

    function calcQty(FundMarketplace fm, uint _fundNum, uint qty) 
    external view returns (uint) 
    {
        return fm.calcQty(_fundNum, qty);
    }

    //Fallback function, accepts ether
    function() external payable{

    }
}