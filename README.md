# State Machine Smart Contract


This project implements a Finite State Machine solidity smart contract, with following features:
* ability to define states with id and name
* ability to define named transitions with conditions and triggered actions
* ability to define automatic transitions

The conditions and triggers are implemented as delegatecall to functions defined in transition by contract address and function signature.

Automatic transitions take precedence over regular transitions. When a transition is called, first we check if the current state has auto transitions defined, and the first one whose condition is met, gets executed. If the next state has auto transitions, these are also executed recursively.


## Installation

Clone this project

```sh
$ git clone git@github.com:dglowinski/state-machine.git
$ cd state-machine
```

Install truffle and ganache-cli

```sh
$ npm i -g truffle
$ npm i -g ganache-cli
```

Start ganache-cli, build and migrate contracts

```sh
$ ganache-cli
$ truffle migrate
```

## Tests

For testing, a state machine for "pass the ball" game is defined.
![pass the ball state machine](https://raw.githubusercontent.com/dglowinski/state-machine/master/FSM.png)

There are 3 players who pass a ball between themselves. Everyone has to play and the game ends after 5 blocks.

Conditions and triggers are implemented in [PassTheBall.sol](https://github.com/dglowinski/state-machine/blob/master/contracts/PassTheBall.sol) contract.

States and transitions:
* state: start
  * transition: startGame[auto] This transition is automatic, so when startGame on end state is executed, this transition is executed automatically
    * condition: none
    * trigger: startGame - set start game time
* state: playerX
  * transition: passToX
    * condition: canPassToX - no one should be excluded from the game, so the difference between the number of passes players received can't be greater than 2
    * trigger: passToX - increase pass counter for the player
  * transition: endGame[auto] - automatically end the game after time runs out
    * condition: timeOut - 5 blocks elapsed from the start
    * trigger: endGame - zero out pass counters
* state: end
  * transition: startGame
    * condition: none
    * trigger: none

To run tests in truffle:

```sh
$ truffle test
```

To run solidity-coverage tests

```sh
$ npm run coverage
```

To set up the states and transitions of the game in Remix, use [scenario.json](https://github.com/dglowinski/state-machine/blob/master/contracts/scenario.json)


## Linters

Solium linter is run at pre-commit hook on staged files.
