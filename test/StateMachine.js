const assert = require('assert')
const assertRevert = require('./helpers/assertRevert')
const Web3Js = require('web3');

const Web3 = new Web3Js(new Web3Js.providers.HttpProvider('http://127.0.0.1:8545'))
const Order = artifacts.require('./Order.sol')


function getSig(instance, method, ...args) {
  return instance.methods[method](10).encodeABI();
}

contract('Order', () => {

  beforeEach(async () => {
   this.order = await Order.deployed()

   const addr = this.order.address
   console.log('addr: ', addr);

   const order = new Web3.eth.Contract(Order.abi, addr)

   const onTransitionSig = getSig(order, "onTransition", 10)
   console.log('onTransitionSig: ', onTransitionSig);

  })


  it('can start the game again', async () => {
    await this.order.transition("transition1")
    let res = await this.order.transitionVal();
    console.log('res: ', res.toNumber());
    assert.equal(res.toNumber(), 10);
  })
})
