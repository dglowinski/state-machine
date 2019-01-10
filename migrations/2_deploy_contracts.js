const Order = artifacts.require("./Order.sol");



module.exports = function(deployer) {
  deployer.deploy(Order, 
    [2, 1],
    "state1.state2.transition1.state1.state2",
    [0, 0, 0, 0, 0, 0],
    '.....',
    [false,false,false,false,false,false]

  );
};
