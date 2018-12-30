var FundMarketplace = artifacts.require("./FundMarketplace.sol");
var StructLib = artifacts.require("./StructLib.sol");
var InitLib = artifacts.require("./InitLib.sol");
var Misc = artifacts.require("./Misc.sol");
var InvestLib = artifacts.require("./InvestLib.sol");
var PayFeeLib = artifacts.require("./PayFeeLib.sol");
var CollectFeesLib = artifacts.require("./CollectFeesLib.sol");
var WithdrawFundsLib = artifacts.require("./WithdrawFundsLib.sol");
var OrderLib = artifacts.require("./OrderLib.sol");

module.exports = function(deployer) {
  //StructLib
  deployer.deploy(StructLib);
  //InitLib and Links
  deployer.link(StructLib, InitLib);
  deployer.deploy(InitLib);
  //MiscLib and Links
  deployer.link(StructLib, Misc);
  deployer.deploy(Misc);
  //InvestLib and Links
  deployer.link(StructLib, InvestLib);
  deployer.link(Misc, InvestLib);
  deployer.deploy(InvestLib);
  //PayFeeLib and Links
  deployer.link(StructLib, PayFeeLib);
  deployer.link(Misc, PayFeeLib);
  deployer.deploy(PayFeeLib);
  //CollectFeesLib and Links
  deployer.link(StructLib, CollectFeesLib);
  deployer.deploy(CollectFeesLib);
  //WithdrawFundsLib and Links
  deployer.link(StructLib, WithdrawFundsLib);
  deployer.deploy(WithdrawFundsLib);
  //OrderLib and Links
  deployer.link(StructLib, OrderLib);
  deployer.deploy(OrderLib);
  //FundMarketplace and Links
  deployer.link(StructLib, FundMarketplace);
  deployer.link(InitLib, FundMarketplace);
  deployer.link(Misc, FundMarketplace);
  deployer.link(InvestLib, FundMarketplace);
  deployer.link(PayFeeLib, FundMarketplace);
  deployer.link(CollectFeesLib, FundMarketplace);
  deployer.link(WithdrawFundsLib, FundMarketplace);
  deployer.link(OrderLib, FundMarketplace);
  deployer.deploy(FundMarketplace);
};
