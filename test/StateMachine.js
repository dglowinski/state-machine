const assert = require('assert')
const assertRevert = require('./helpers/assertRevert')
const Web3Js = require('web3');

const Web3 = new Web3Js(new Web3Js.providers.HttpProvider('http://127.0.0.1:8545'))
const Order = artifacts.require('./Order.sol')
const Pricing = artifacts.require('./Pricing.sol')

const YAML = require("yamljs")

const stateMachineConfig = YAML.load("test/orderConfig.yaml")

function getSig(callback, abis) {
  if(!callback) return ''
  const contract = new Web3.eth.Contract(abis[callback.contract], '0x'+'0'.repeat(40))
  return contract.methods[callback.function](...(callback.args || [])).encodeABI();
}

//TODO: abi management
function packStateMachine(stateMachineConfig, abis) {
  const transitions = stateMachineConfig.states.reduce((accu, state) => {
    state.transitions.forEach(transition => transition.fromState = state.name)
    return accu.concat(state.transitions)
  }, [])

  const packed = {
    counts: [stateMachineConfig.states.length, transitions.length],
    names: [],
    addresses: [],
    callData: [],
    isDelegatecall: []
  }

  stateMachineConfig.states.forEach(state => {
    packed.names.push(state.name)
    packed.addresses.push(state.onEnter && state.onEnter.address || 0)
    packed.addresses.push(state.onLeave && state.onLeave.address || 0)
    packed.callData.push(getSig(state.onEnter, abis))
    packed.callData.push(getSig(state.onLeave, abis))
    packed.isDelegatecall.push(state.onEnter && state.onEnter.isDelegatecall || false)
    packed.isDelegatecall.push(state.onLeave && state.onLeave.isDelegatecall || false)
  })

  transitions.forEach(transition => {
    packed.names.push(transition.name)
    packed.addresses.push(transition.guard && transition.guard.address || 0)
    packed.addresses.push(transition.trigger && transition.trigger.address || 0)
    packed.callData.push(getSig(transition.guard, abis))
    packed.callData.push(getSig(transition.trigger, abis))
    packed.isDelegatecall.push(transition.guard && transition.guard.isDelegatecall || false)
    packed.isDelegatecall.push(transition.trigger && transition.trigger.isDelegatecall || false)
  })

  transitions.forEach(transition => {
    packed.names.push(transition.fromState)
    packed.names.push(transition.nextState)
  })

  packed.names = packed.names.join(";")
  packed.callData = packed.callData.join(";")

  return packed
}

contract('Order', () => {

  beforeEach(async () => {

    this.pricing = await Pricing.new()

    const abis = {
      Order: Order.abi,
      Pricing: Pricing.abi
    }
    const packedStateMachine = packStateMachine(stateMachineConfig, abis)
    packedStateMachine.addresses[2] = this.pricing.address;

    console.log('packedStateMachine: ', packedStateMachine);

    this.order = await Order.new(
      packedStateMachine.counts, //[2, 1],
      packedStateMachine.names, //"state1;state2;transition1;state1;state2",
      packedStateMachine.addresses, //[0, 0, 0, 0, 0, 0],
      packedStateMachine.callData, //';;;;;ecf36778000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000046475706100000000000000000000000000000000000000000000000000000000',
      packedStateMachine.isDelegatecall, //[false,false,false,false,false,false]
      this.pricing.address,
      {gas: 900000000}
    ) 

  //  const onTransitionSig = getSig(order, "onTransition", 10, "dupa")
  //  console.log('onTransitionSig: ', onTransitionSig);
  })


  it('can start the game again', async () => {
    assert.ok(true)
    // await this.order.transition("transition1")
    // let res = await this.order.transitionVal();

    // assert.equal(res.toNumber(), 10);

    // res = await this.order.transitionStr();
    // assert.equal(res, "dupa");
  })
})
