const FundMarketplace = artifacts.require("./FundMarketplace.sol");

//SimpleStorage model
contract('FundMarketplace', function(accounts) {
    const owner = accounts[0]
    const manager = accounts[1]
    const investor = accounts[2]

    var fundName
    const name = "alpha"
    //Read results from getFundDetails
    var result
    var result2

    function hex2string(hexx) {
        var hex = hexx.toString(16);
        var str = '';
        for (var i = 0; (i < hex.length && hex.substr(i,2) !== '00'); i += 2)
            str += String.fromCharCode(parseInt(hex.substr(i,2), 16));
        //Get rid of null characters
        str = str.replace('\0', '')
        return str;
    }

    // function compareStrings(string_1, string_2) {
    //     for (var c=0; c<string_1.length; c++) {
    //         if (string_1.charCodeAt(c) != string_2.charCodeAt(c)){
    //             console.log('c:'+c+' '+string_1.charCodeAt(c)+'!='+string_2.charCodeAt(c));
    //         }
    //     }
    // }

    //Price equals 1 ether
    //const price = web3.toWei(1, "ether")

    it("should initialize a fund on the marketplace", async() => {
        const fundMarketplace = await FundMarketplace.deployed()

        //Manager's Balance to measure Gas Costs
        var managerBalanceBefore = await web3.eth.getBalance(manager).toNumber()

        var eventEmitted = false
        //constants for comparison here
        const initialFund = web3.toWei(1, "ether")
        const feeRate = 2
        const paymentCycle = 0
        //Transaction from Manager account
        const tx = await fundMarketplace.initializeFund(name, manager, initialFund, feeRate, paymentCycle, {from: manager})
        if (tx.logs[0].event === "FundCreated") {
            fundName = tx.logs[0].args.name
            fundCount = tx.logs[0].args.fundCount
            managerAddr = tx.logs[0].args.fundOwner
            eventEmitted = true;
        }

        //Manager Account Balance Afterwards
        var managerBalanceAfter = await web3.eth.getBalance(manager).toNumber()
        //Test for Gas Costs
        assert.isBelow(managerBalanceAfter, managerBalanceBefore, "Manager's Account should be decreased by gas costs")

        //Event Testing
        fundName = hex2string(fundName);
        //Confirm fundName is accurately broadcast in event
        assert.equal(fundName, name, "Fund Name does not match test name")
        //Confirm fundCount is accurately broadcast in event
        assert.equal(fundCount, 1, "Fund Count does not match test")
        //Confirm manager address is accurately broadcast in event
        assert.equal(managerAddr, manager, "Manager is not listed as owner in event")
        assert.equal(eventEmitted, true, 'Initiating a fund should emit an event')

        //Retrieve Fund Details
        result = await fundMarketplace.getFundDetails.call(name)
        result2 = await fundMarketplace.getFundDetails2.call(name, manager)

        //Result Testing
        //Want to be able to remove hex2string- JavaScript converting string to hex at some point in process
        assert.equal(hex2string(result[0]), name, "Fund name from getter function does not match test name")
        assert.equal(result[1], manager, "Manager is not owner of Fund");
        assert.equal(result[2], initialFund, "total capital in fund do not match test amount");
        assert.equal(result[3], 0, "Deployed Capital is not equal to zero");
        assert.equal(result[4], feeRate, "Fee Rate does not match test rate");
        assert.equal(result[5], paymentCycle, "Payment Cycle does not match test cycle");
        assert.equal(result2[0], true, "Manager is not listed as investor");
        assert.equal(result2[1], initialFund, "Manager's funds are not listed");
        assert.equal(result2[2], 0, "Manager's fees deposited are not zero");

    })

    it("should allow an investor to deposit capital into a fund", async() => {
        const fundMarketplace = await FundMarketplace.deployed()

        //Set event emitted to be false
        var eventEmitted = false

        //Investor's Balance
        var investorBalanceBefore = await web3.eth.getBalance(investor).toNumber()

        //local variables
        var investment = web3.toWei(2, "ether")
        const initialFund = web3.toWei(1, "ether")

        //Pre-transaction testing
        result = await fundMarketplace.getFundDetails.call(name)
        result2 = await fundMarketplace.getFundDetails2.call(name, investor)
        //Tests
        assert.equal(result[2], initialFund, "Initial total capital does not match initial balance")
        assert.equal(result2[0], false, "Account is incorrectly listed as investor")
        assert.equal(result2[1], 0, "Investor's virtual balance is not zero")
        assert.equal(result2[2], 0, "Investor's fees are not zero")

        //Calculate Fee
        var feeRate = await fundMarketplace.checkFeeRate.call(name)
        var fee = (investment/feeRate) + 1

        //Make Investment
        const tx = await fundMarketplace.Invest(name, investment, {from: investor, value: fee})
        //Check for Event
        if (tx.logs[0].event === "Investment"){
            //name, investor, investment
            fundName = tx.logs[0].args.name
            investorAddr = tx.logs[0].args.investor
            newInvestment = tx.logs[0].args.investment
            eventEmitted = true;
        }

        //Event Testing
        fundName = hex2string(fundName);
        //Confirm fundName is accurately broadcast in event
        assert.equal(fundName, name, "Fund Name does not match test name")
        //Confirm fundCount is accurately broadcast in event
        assert.equal(investorAddr, investor, "Fund Count does not match test")
        //Confirm manager address is accurately broadcast in event
        assert.equal(newInvestment, investment, "Manager is not listed as owner in event")
        assert.equal(eventEmitted, true, 'Initiating a fund should emit an event')

        //Investor's Balance
        var investorBalanceAfter = await web3.eth.getBalance(investor).toNumber()
        //Account Balance Testing
        assert.isBelow(investorBalanceAfter, investorBalanceBefore-fee, "Investor's Balance should be less than the initial balance minus the fee, due to gas costs")

        //Post-transaction testing
        result = await fundMarketplace.getFundDetails.call(name)
        result2 = await fundMarketplace.getFundDetails2.call(name, investor)
        //Tests
        assert.equal(result[2].toNumber(), web3.toWei(3, "ether"), "Total Capital does not match sum of initial fund and new investment")
        assert.equal(result2[0], true, "Account is not listed as investor")
        assert.equal(result2[1], investment, "Investor's virtual balance does not match investment")
        assert.equal(result2[2], fee, "Investor's fees were not valid")

    })

    it("should allow a fund manager to place and an investor to receive an order", async() => {
        //Deployed fundMarketplace
        const fundMarketplace = await FundMarketplace.deployed()

        //Set event emitted to be false
        var eventEmitted = false

        //Account Balances
        var managerBalanceBefore = await web3.eth.getBalance(manager).toNumber()
        var investorBalanceBefore = await web3.eth.getBalance(investor).toNumber()

        //local variables
        const _name = "alpha"
        const action = "buy"
        const ticker = "PLNT"
        const qty = 3
        const price = web3.toWei(100, "szabo") //0.0001 ether

        //Pre-transaction Testing
        result = await fundMarketplace.getFundDetails.call(_name)
        //Make sure Capital Deployed is 0
        assert.equal(result[3], 0, "capital deployed is not zero")

        //Define event that investor watches
        //Only watch for events filtered by fund
        let event = fundMarketplace.OrderPlaced({name: _name})

        //Place Order
        const tx = await fundMarketplace.placeOrder(_name, action, ticker, qty, price, {from: manager})
        //Check for Event
        if(tx.logs[0].event === "OrderPlaced"){
            //name, action, ticker, qty, price
            fundName = tx.logs[0].args.name
            fundAction = tx.logs[0].args.action
            fundTicker = tx.logs[0].args.ticker
            fundQty = tx.logs[0].args.qty
            fundPrice = tx.logs[0].args.price            
            eventEmitted = true
        }

        //How does the investor receive the event information - check contracts documentation

        //Event Testing- verify investor can receive information
        fundName = hex2string(fundName) //Convert to string format
        fundAction = hex2string(fundAction)
        fundTicker = hex2string(fundTicker)
        fundQty = fundQty.toNumber()
        assert.equal(fundName, _name, "Fund name does not match test name")
        assert.equal(fundAction, action, "fund action does not match test action")
        assert.equal(fundTicker, ticker, "fund ticker does not match test ticker")
        assert.equal(fundQty, qty, "fund quantity does not match test quantity")
        assert.equal(fundPrice, price, "fund price does not match test price")
        assert.equal(eventEmitted, true, "Placing an Order should emit an event")

        //Investor account reads event information
        event.watch(function(error, result){
            if(!error){
                //What should the error be, if any
                //console.log(result)
                let eventName = hex2string(result.args.name)
                let eventQty = result.args.qty.toNumber()
                // console.log("Event Name: "+eventName)
                // console.log("Event Quantity: "+eventQty)
                //Code works, but takes time into next test to work, try to make sure this executes before this specific test finishes
                let outcome = fundMarketplace.calcQty.call(eventName, eventQty, {from: investor})
                outcome.then(function (result){
                        //Can change test value to 2, when the code is working
                        assert.equal(result.toNumber(), 2, "Quantity in order is not proportional to investor's share of capital in the fund")
                    }, function (error){
                        console.error("Something went wrong", error)
                    }
                )
            } else {
                console.log(error)
            }
            event.stopWatching()
        })

        //Account Balance Testing
        var managerBalanceAfter = await web3.eth.getBalance(manager).toNumber()
        var investorBalanceAfter = await web3.eth.getBalance(investor).toNumber()
        assert.isBelow(managerBalanceAfter, managerBalanceBefore, "Manager's Balance should be less than the initial balance due to gas costs")
        assert.equal(investorBalanceAfter, investorBalanceBefore, "Investor's Balance should not change")

        //Post-transaction Testing
        result = await fundMarketplace.getFundDetails.call(name)
        //Make sure Capital Deployed is equal to cost of trade (price * quantity)
        assert.equal(result[3], web3.toWei(300, "szabo"), "capital was not successfully deployed")
    })

    it("should allow investors to pay fees", async() => {
        //Deployed fundMarketplace
        const fundMarketplace = await FundMarketplace.deployed()

        //Set event emitted to be false
        var eventEmitted = false

        //Account Balances
        var managerBalanceBefore = await web3.eth.getBalance(manager).toNumber()
        var investorBalanceBefore = await web3.eth.getBalance(investor).toNumber()

        //local variables
        const _name = "alpha"
        const _timePeriod = 12
        const investment = web3.toWei(2, "ether")
        const feeRate = await fundMarketplace.checkFeeRate.call(name)
        const fee = (investment/feeRate) + 1

        //Pre-transaction testing
        resultMan = await fundMarketplace.getFundDetails2.call(name, manager)
        resultInv = await fundMarketplace.getFundDetails2.call(name, investor)
        assert.equal(resultMan[2], 0, "Manager's fees received were not zero")
        assert.equal(resultInv[2], fee, "Investor's fees are not valid")

    })
});

// function testPayFees() public {
//     bytes32 name = "alpha";
//     //Paid monthly; 12 times in a year
//     uint timePeriod = 12;
//     uint investment = 2 ether;
//     uint fee = SafeMath.add(SafeMath.div(investment, fm.checkFeeRate(name)),1);

//     //Pre Fee Tests
//     //Manager
//     (,,i) = fm.getFundDetails2(name, managerAddr);
//     Assert.equal(i, 0, "Manager's fees were not zero");
//     //Investor
//     (,,i) = fm.getFundDetails2(name, investorAddr);
//     Assert.equal(i, fee, "Investor's fees are not valid");

//     investor.payFee(fm, name, timePeriod);

//     //Post Fee Tests
//     //Manager
//     (,,i) = fm.getFundDetails2(name, managerAddr);
//     Assert.equal(i, SafeMath.div(fee,timePeriod), "Manager did not receive fee");
//     //Investor
//     (,,i) = fm.getFundDetails2(name, investorAddr);
//     Assert.equal(i, SafeMath.sub(fee, SafeMath.div(fee, timePeriod)), "Investor did not pay fee");
// }