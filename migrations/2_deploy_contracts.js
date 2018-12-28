var FundMarketplace = artifacts.require("./FundMarketplace.sol");

module.exports = function(deployer) {
  deployer.deploy(FundMarketplace);
};
