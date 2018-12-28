var FundMarketplace = artifacts.require("./FundMarketplace.sol");
var FundList = artifacts.require("./FundList.sol");

module.exports = function(deployer) {
  deployer.deploy(FundMarketplace);
  deployer.deploy(FundList);
};
