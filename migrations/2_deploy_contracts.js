var StrategyHub = artifacts.require("./StrategyHub.sol");

module.exports = function(deployer) {
  deployer.deploy(StrategyHub);
};
