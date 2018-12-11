var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var StrategyHub = artifacts.require("./StrategyHub.sol");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(StrategyHub);
};
