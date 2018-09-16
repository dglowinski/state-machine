const assert = require('assert')
const assertRevert = require('./helpers/assertRevert')
const Web3Js = require('web3');

const Web3 = new Web3Js(new Web3Js.providers.HttpProvider('http://127.0.0.1:8545'))
const StateMachine = artifacts.require('./StateMachine.sol')
const PassTheBall = artifacts.require('./PassTheBall.sol')


function getSig(instance, method) {
  return instance.methods[method]().encodeABI();
}

contract('StateMachine', () => {

  beforeEach(async () => {
    this.stateMachine = await StateMachine.new()
    this.ptb = await PassTheBall.new()

    const addr = this.ptb.address

    const ptb = new Web3.eth.Contract(PassTheBall.abi, addr)

    await this.stateMachine.addState(1, "start");
    await this.stateMachine.addState(2, "playerA");
    await this.stateMachine.addState(3, "playerB");
    await this.stateMachine.addState(4, "playerC");
    await this.stateMachine.addState(5, "end");

    await this.stateMachine.addTransition(1, "startGame", 0, "", addr, getSig(ptb, "startGame"), 2, true);
      
    //player transitions
    for(let player = 2; player <= 4; player++) {
      await this.stateMachine.addTransition(player, "endGame", 
        addr, getSig(ptb, "timeOut"), addr, getSig(ptb, "endGame"), 5, true);
      await this.stateMachine.addTransition(player, "passToA", 
        addr, getSig(ptb, "canPassToA"), addr, getSig(ptb, "passToA"), 2, false);
      await this.stateMachine.addTransition(player, "passToB", 
        addr, getSig(ptb, "canPassToB"), addr, getSig(ptb, "passToB"), 3, false);
      await this.stateMachine.addTransition(player, "passToC", 
        addr, getSig(ptb, "canPassToC"), addr, getSig(ptb, "passToC"), 4, false);
    }

    await this.stateMachine.addTransition(5, "startGame", 0, "", 0, "", 1, false);
  })

  it('can delete state', async () => {
    await this.stateMachine.deleteState(5)
    const state = await this.stateMachine.states(5)
    assert.equal(state.name, undefined)
  })

  it('can delete transition', async () => {
    await this.stateMachine.deleteTransition(1, "startGame")
    assertRevert(this.stateMachine.transition("startGame"))
  })

  it('is in starting state', async () => {
    const state = await this.stateMachine.getCurrentStateName()
    assert.equal(state, "start")
  })

  it('can\'t perform unknown transition', async () => {
    assertRevert(this.stateMachine.transition("unknownTransition"))
  })

  it('can start the game', async () => {
    await this.stateMachine.transition("startGame")
    const state = await this.stateMachine.getCurrentStateName()

    assert.equal(state, "playerA")
  })

  it('can\'t end too soon', async () => {
    await this.stateMachine.transition("startGame")
    await this.stateMachine.transition("endGame")

    const state = await this.stateMachine.getCurrentStateName()
    assert.equal(state, "playerA")
  })

  it('has to allow everybody play', async () => {
    await this.stateMachine.transition("startGame")
    await this.stateMachine.transition("passToB")
    await this.stateMachine.transition("passToB")
    await this.stateMachine.transition("passToA")
    await this.stateMachine.transition("passToB")

    const state = await this.stateMachine.getCurrentStateName()
    assert.equal(state, "playerA")
  })

  it('will end after time runs out', async () => {
    await this.stateMachine.transition("startGame")
    await this.stateMachine.transition("passToB")
    await this.stateMachine.transition("passToC")
    await this.stateMachine.transition("passToA")
    await this.stateMachine.transition("passToB")
    await this.stateMachine.transition("passToC")

    //this ends game automatically 
    await this.stateMachine.transition("passToA")
    const state = await this.stateMachine.getCurrentStateName()
    assert.equal(state, "end")
  })

  it('can start the game again', async () => {
    await this.stateMachine.transition("startGame")
    await this.stateMachine.transition("passToB")
    await this.stateMachine.transition("passToC")
    await this.stateMachine.transition("passToA")
    await this.stateMachine.transition("passToB")
    await this.stateMachine.transition("passToC")
    //this ends game automatically 
    await this.stateMachine.transition("passToA")

    await this.stateMachine.transition("startGame")

    //startGame in state 'start' is an auto transition
    const state = await this.stateMachine.getCurrentStateName()
    assert.equal(state, "playerA")
  })
})
