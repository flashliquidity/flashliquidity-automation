# FlashLiquidity Automation

Automation station provides a single entry point for managing multiple upkeeps in the [Chainlink Automation Network](https://chain.link/automation).
It supports programmatic registration, unregistration, pausing/unpausing and migration of upkeeps and enables automated funding to ensure all managed upkeeps maintain the required minimum balance for continued operation.


## Requirements

- [foundry](https://book.getfoundry.sh/getting-started/installation)

## Install Dependencies

`yarn setup`

## Quickstart

### Deployment

The first step is deploying the AutomationStation contract to a Chainlink Automation supported network. In order to deploy the contract, you will need to edit the required constructor arguments inside the script file `deploy/deployStation.ts` based on the network chosen for deployment. The required constructor arguments are the following:

- `linkToken`: The address of the ERC-677 compatible LINK token (depending on the network chosen, you might need to use [pegswap](https://pegswap.chain.link/) to convert Chainlink tokens to be ERC-677 compatible when funding the station).
- `registrar`: The address of the Chainlink Automation Registrar for the selected network (https://docs.chain.link/chainlink-automation/overview/supported-networks).
- `registerUpkeepSelector`: The Chainlink Automation Registrar 4-byte function selector of `registerUpkeep`.
- `refuelAmount`: The amount of LINK tokens that will be added to an upkeep balance when it will be underfunded.
- `stationUpkeepMinBalance`: The minimum balance of LINK tokens for the main station upkeep after which it will be considered underfunded (more on the main station upkeep in the initialization section).
- `minDelayNextRefuel`: The minimum delay between consecutive refuels of the same upkeep (main station upkeep excluded).
- `approveAmountLINK`: The initial allowance of LINK tokens to the Chainlink Automation Registrar.

When the arguments have been set, you can run the deployment script with:

```
npx hardhat deploy --network sepolia
```
You can view the supported network for the deployment scripts inside hardhat.config.ts and add any required network if missing.

### Initialization

After deploying the AutomationStation, you need to transfer enough LINK tokens to the station before initializing it. During the initialization process, the main station upkeep will be registered. This upkeep will automate monitoring all the other registered upkeeps to ensure they are not underfunded; if they are, it will add funds to their balance. 
To initialize the station run the hardhat task `initialize.
Available arguments are all optional, if the registry address parameter is non-zero, the Automation forwarder of the station will be automatically set during initialization. Otherwise, you must set the forwarder before registering other upkeeps:

- `registry`: The address of the Chainlink Automation Registry for the selected network, default is zero address (https://docs.chain.link/chainlink-automation/overview/supported-networks).
- `amount`: The amount of LINK tokens to fund the main station upkeep, default is 10 LINK tokens (18 decimals)
- `gasLimit`: The maximum gas limit that will be used for txns by the station upkeep, default is 750000

Examples:

```
npx hardhat initialize --network sepolia
```

```
npx hardhat initialize --registry 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad --amount 5000000000000000000 --gasLimit 500000 --network sepolia
```

### Upkeep Registration

Once initialized, the station’s `registerUpkeep` function can be used to register a new Chainlink Automation upkeep. The newly registered upkeep will be monitored by the station to ensure it meets the minimum LINK token balance required for execution. If the balance falls below this threshold, the station will automatically use its own LINK token balance to increase the upkeep balance until it meets the required minimum.

To register a new upkeep run the hardhat task `registerUpkeep`.
Available arguments:

-`name`: The name of the upkeep displayed in the Chainlink Automation UI
-`contract`: The address of your Automation-compatible contract
-`gasLimit`: The maximum gas limit that will be used for txns by this upkeep
-`triggerType`: 0 is Conditional upkeep, 1 is Log trigger upkeep, default: 0
-`checkData`: checkData is a static input that you can specify now which will be sent into your checkUpkeep or checkLog, see interface, default: 0x
-`triggerConfig`: The configuration for your upkeep. 0x for conditional upkeeps, default: 0x
-`offchainConfig`: Leave as 0x, or use this field to set a gas price threshold for your upkeep, defualt: 0x
-`amount`: The LINK token amount to fund the upkeep, default: 5 LINK tokens (18 decimals)

The station must hold an amount of LINK tokens greater than or equal to the `amount` argument and the allowance of LINK tokens to the Chainlink Automation Registrar must also be greater than or equal to this amount.

Examples: 

```
npx hardhat registerUpkeep --name test --contract 0x0dd...c0d3 --gasLimit 1000000 --network sepolia
```

```
npx hardhat registerUpkeep --name test --contract 0x0dd...c0d3 --gasLimit 1000000 --triggerType 0 --checkData 0xbad...cod3 --amount 1000000000000000000 --network sepolia
```

## Compile Contract

`yarn compile`

## Run Full Test Suite

`yarn test`

## Run Unit Tests

`yarn unit-test`

## Run Invariant Tests

`yarn integration-test`

## Run Coverage

`yarn coverage`

## Gas Report

`yarn gas-report`

## Run Slither

`yarn slither`

