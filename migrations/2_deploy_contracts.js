const StateMachine = artifacts.require("./StateMachine.sol");
const PassTheBall = artifacts.require("./PassTheBall.sol");

module.exports = function(deployer) {
  deployer.deploy([StateMachine, PassTheBall]);
};
