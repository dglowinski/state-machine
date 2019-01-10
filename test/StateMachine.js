const assert = require('assert')
const assertRevert = require('./helpers/assertRevert')
const Web3Js = require('web3');

const Web3 = new Web3Js(new Web3Js.providers.HttpProvider('http://127.0.0.1:8545'))
const Order = artifacts.require('./Order.sol')


function getSig(instance, method) {
  return instance.methods[method]().encodeABI();
}

contract('Order', () => {

  beforeEach(async () => {
   // this.order = await Order.deployed()

   // const addr = this.ptb.order

   // const ptb = new Web3.eth.Contract(PassTheBall.abi, addr)

  })


  it('can start the game again', async () => {
    assert.ok(true);
  })
})
