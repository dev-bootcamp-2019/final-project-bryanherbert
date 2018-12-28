var FundMarketplace = artifacts.require("./FundMarketplace.sol");
var StructLib = artifacts.require("./StructLib.sol");
var InitLib = artifacts.require("./InitLib.sol");

module.exports = function(deployer) {
  deployer.deploy(StructLib);
  deployer.link(StructLib, InitLib);
  deployer.deploy(InitLib);
  deployer.link(StructLib, FundMarketplace);
  deployer.link(InitLib, FundMarketplace);
  deployer.deploy(FundMarketplace);
};
