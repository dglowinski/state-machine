# PoA token with timeshare Ðapp


This project is based on a Proof of Asset token concept, where tokens on ethereum blockchain represent an ownership of a physical asset like for example an apartment building. In this project a PoA ERC20 token is implemented. Owners of a property may be entitled to dividends from the revenue of the property. In this project instead of a dividend, the owners of PoA token participate directly - they are entitled to timeshare of the property. PoA tokens generate a timeshare balance for each holder in the form of Timeshare Token TST. For simplicity it is assumed, that the property can be used on a day to day basis. The total supply of PoA generates 1 TST token per day, and holders of PoA are entitled to claim TST token in proportion to their PoA balance over time, such that the sum total will always represent 1 TST per day. Thay can claim and transfer any amount of TST, but only when they own at least 1 TST, they can use it to book the property for 1 day. The TST token tracks the bookings calendar and ensures any given day can only be booked once. When the day is booked, the TST token is burned. 

Additionally TST can be used to control physical access to the property. After the booking is made, the renter signes a timestamp with his private key, and this represents an access key, possibly stored in a mobile application. To access the property he sends his key to a smart lock, which calls the TST contract, which in turn verifies the signature to check that the booking was made for a given address and timestamp and replies to the smart lock to grant or prevent access. 

The economics of this setup are possibly similar to dividends: if the property use is in demand, the price of TST is high, which incentivizes the PoA owners to hold their token, which lowers the supply and drives up the property valuation.

## Ðapp features

The Ðapp part of this project implements the above behaviour: 

* get the details of both tokens: name, symbol, decimals, meta data (description, link to photos etc.)
* check balance of an ethereum address - both tokens
* check balance of current address - MetaMask or local - both tokens
* transfer both tokens
* buy PoA tokens with Ether, the funds are transferred to property seller address
* check available timeshare balance in PoA of current account and claim TST token
* check available days in TST, make a booking, sign timestamp and receive access key
* verify the access key for selected day. This currently only works with local ganache-cli, due to differences in signing algorithm between MetaMask and Truffle. https://github.com/trufflesuite/ganache-cli/issues/243

## Deployed project

The contracts are deployed on Ropsten:
* PoA [0xa5e902084e2106661a5A3130771d58E878b2c86D](https://ropsten.etherscan.io/address/0xa5e902084e2106661a5a3130771d58e878b2c86d)
* TST [0x52549435D38774E290Aea4bE00Bc4B7Eb50A1Ba5](https://ropsten.etherscan.io/address/0x52549435d38774e290aea4be00bc4b7eb50a1ba5)

and docker image is hosted on [Azure](http://137.117.184.38)

## Installation

### To run locally 

Clone this project

```sh
$ git clone git@github.com:dglowinski/poa-timeshare-dapp.git
$ cd poa-timeshare-dapp
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

Run the app

```sh
$ npm start
```

### To deploy to test net and build the app

Edit .env file, provide mnemonic and infura access key, then

```sh
$ npm run ropsten
```

or 

```sh
$ npm run ropsten:reset
```

build the Ðapp

```sh
$ npm run build
```

serve the build folder using eg. http-server

```sh
$ http-server build -p 8000
```

## Tests

To run the tests, launch ganache-cli and then

```sh
$ truffle test
```

To run solidity-coverage tests

```sh
$ npm run coverage
```

## Libraries

The project uses a standard set of libraries. Truffle, Zeppelin, [truffle box with redux](https://truffleframework.com/boxes/react-auth), upgraded to newest React and React Router, Material UI. Additionally [ethereum-datetime](https://github.com/pipermerriam/ethereum-datetime) is used for working with dates and timestamps.

## Linters

Eslint, prettier and solium linters are run at pre-commit hook on staged files.

## Docker

Dockerfile is provided.

## Implementation details

Tracking time on blockchain is problematic. Here for simplicity the passage of time is measured in blocks, assuming that an approximate number of blocks in a year can be calculated. For demonstration purposes, the time in the PoA contract is sped up to 2 blocks per ‘day’. This means that 100% PoA tokens generate 1 TST token every second block. In production a more robust solution would be required, possibly using oracles.

The TST token is generated directly by PoA token in constructor with new TimeShareToken(). With increasing code size, the tokens should be deployed separately, and ownership of TST should be transferred to PoA.

The price of PoA token is set to 1000 tokens (total supply) for 1 Eth.

## Possible improvements
* the project implements single PoA and TST tokens, representing a single physical property. A token factory to generate and manage many properties could be implemented
* the right to use a property could have different value on different days, for example during holidays, festivals etc. Instead of booking a day in TST, a non-fungible token could be generated, which would allow a secondary market for trading access keys to emerge
* as mentioned before, a better time representation could be implemented.
* as mentioned before, due to differences in signing implementations, access key verification currently only works with ganache-cli. Additional research is needed to resolve this problem.
* run vulnerability detection tools such as ConsenSys mythril
* UI

## Donate
¯\_(ツ)_/¯
0x76f04a3a7074A8E721508b14c70DC8cEfb79fe55

