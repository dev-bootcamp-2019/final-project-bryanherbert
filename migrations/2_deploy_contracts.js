var FundMarketplace = artifacts.require("./FundMarketplace.sol");
var StructLib = artifacts.require("./StructLib.sol");
var InitLib = artifacts.require("./InitLib.sol");
var Misc = artifacts.require("./Misc.sol");
var InvestLib = artifacts.require("./InvestLib.sol");
var PayFeeLib = artifacts.require("./PayFeeLib.sol");

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
  //FundMarketplace and Links
  deployer.link(StructLib, FundMarketplace);
  deployer.link(InitLib, FundMarketplace);
  deployer.link(Misc, FundMarketplace);
  deployer.link(InvestLib, FundMarketplace);
  deployer.link(PayFeeLib, FundMarketplace);
  deployer.deploy(FundMarketplace);
};
