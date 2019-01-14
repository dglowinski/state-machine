const assert = require('assert')
const assertRevert = require('./helpers/assertRevert')
const Web3Js = require('web3');
const YAML = require("yamljs")
const fs   = require('fs');

const Web3 = new Web3Js(new Web3Js.providers.HttpProvider())
const Order = artifacts.require('./Order.sol')
const Pricing = artifacts.require('./Pricing.sol')

Order.defaults({gas: 10000000})
Pricing.defaults({gas: 10000000})



function loadAndParseConfig(path, contracts) {
  let configFile = fs.readFileSync(path, 'utf8')

  Object.entries(contracts).forEach(([contract, address]) => {
    const regex = new RegExp(`<<${contract}>>`, "g")
    configFile = configFile.replace(regex, address)
  })

  return YAML.parse(configFile)
}

function getSig(callback, abis) {
  if(!callback) return ''
  const contract = new Web3.eth.Contract(abis[callback.contract], '0x'+'0'.repeat(40))
  return contract.methods[callback.function](...(callback.args || [])).encodeABI().substr(2);
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

  before(async () => {

    this.pricing = await Pricing.new()

    const abis = {
      Order: Order.abi,
      Pricing: Pricing.abi
    }

    const addresses = {
      Pricing: this.pricing.address
    }

    const stateMachineConfig = loadAndParseConfig("test/orderConfig.yaml", addresses)
    const packedStateMachine = packStateMachine(stateMachineConfig, abis)

    this.order = await Order.new(
      packedStateMachine.counts, 
      packedStateMachine.names, 
      packedStateMachine.addresses, 
      packedStateMachine.callData,
      packedStateMachine.isDelegatecall, 
      this.pricing.address,
    ) 
  })

  it('can transition to deployed', async () => {
    await this.order.transition("ordered_to_deployed")

    const state = await this.order.getCurrentState();
    assert.equal(state, "Deployed and operational", "State is incorrect")

    const checkVal = await this.order.onLeaveOrderedVal();
    assert.equal(checkVal.toNumber(), 1, "onLeave value incorrect")

    const lastTransitionFrom = await this.order.lastTransitionFrom()
    const lastTransitionTo = await this.order.lastTransitionTo()

    assert.equal(lastTransitionFrom, "Ordered")
    assert.equal(lastTransitionTo, "Deployed")

    const installationsCount = await this.pricing.installationsCount()
    assert.equal(installationsCount.toNumber(), 1, "Incorrect number of installations")

    const operationalCount = await this.pricing.operationalCount()
    assert.equal(operationalCount.toNumber(), 1, "Incorrect number of operational orders")
  })

  it('can transition to deployed', async () => {
    await this.order.transition("deployed_to_disputed")

    const state = await this.order.getCurrentState();
    assert.equal(state, "Disputed", "State is incorrect")

    const operationalCount = await this.pricing.operationalCount()
    assert.equal(operationalCount.toNumber(), 0, "Incorrect number of operational orders") 
    
    const isDisputed = await this.order.isDisputed()
    assert.ok(isDisputed, "Order should be disputed")
  })

})
