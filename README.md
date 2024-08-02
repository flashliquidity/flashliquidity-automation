# FlashLiquidity Automation

Automation station provides a single entry point for managing multiple upkeeps in the [Chainlink Automation Network](https://chain.link/automation).
It supports programmatic registration, unregistration, pausing/unpausing and migration of upkeeps and enables automated funding to ensure all managed upkeeps maintain the required minimum balance for continued operation.


## Requirements

- [foundry](https://book.getfoundry.sh/getting-started/installation)

## Install Dependencies

`yarn setup`

## Quickstart

### Deployment

The first step is deploying the AutomationStation contract to a Chainlink Automation supported network. In order to deploy the contract, you will need to edit the required constructor arguments inside the script file `scripts/deployStation.ts` based on the network chosen for deployment. The required constructor arguments are the following:

- `linkToken`: The address of the ERC-677 compatible LINK token (depending on the network chosen, you might need to use [pegswap](https://pegswap.chain.link/) to convert Chainlink tokens to be ERC-677 compatible when funding the station).
- `registrar`: The address of the Chainlink Automation Registrar for the selected network (https://docs.chain.link/chainlink-automation/overview/supported-networks).
- `registerUpkeepSelector`: The Chainlink Automation Registrar 4-byte function selector of `registerUpkeep`.
- `refuelAmount`: The amount of LINK tokens that will be added to an upkeep balance when it will be underfunded.
- `stationUpkeepMinBalance`: The minimum balance of LINK tokens for the main station upkeep after which it will be considered underfunded (more on the main station upkeep in the initialization section).
- `minDelayNextRefuel`: The minimum delay between consecutive refuels of the same upkeep (main station upkeep excluded).
- `approveAmountLINK`: The initial allowance of LINK tokens to the Chainlink Automation Registrar.

When the arguments have been set, you can run the deployment script with:

```
npx hardhat run scripts/deployStation.ts --network arbitrum_sepolia
```
You can view the supported network for the deployment scripts inside hardhat.config.ts and add any required network if missing.

### Initialization

After deploying the AutomationStation, you need to transfer enough LINK tokens to the station before initializing it. During the initialization process, the main station upkeep will be registered. This upkeep will automate monitoring all the other registered upkeeps to ensure they are not underfunded; if they are, it will add funds to their balance. Before running the initialization script `scripts/initializeStation.ts`, you need to edit the following arguments:

- `registry`: The address of the Chainlink Automation Registry for the selected network, this parameter is optional (https://docs.chain.link/chainlink-automation/overview/supported-networks).
- `registrationParams`: The encoded registration parameters for the main station upkeep (the `adminAddress` and `upkeepContract` need to be the station address; an example of how to encode the registration parameters is provided inside the script, you can read more about upkeep registration parameters here: https://docs.chain.link/chainlink-automation/guides/register-upkeep-in-contract#register-the-upkeep).

If the registry address parameter is non-zero, the Automation forwarder of the station will be automatically set during initialization. Otherwise, you must set the forwarder before registering other upkeeps.
When the arguments have been set, you can run the deployment script with:

```
npx hardhat run scripts/initializeStation.ts --network arbitrum_sepolia
```

### Upkeep Registration

Once initialized, the station’s `registerUpkeep` function can be used to register a new Chainlink Automation upkeep. The newly registered upkeep will be monitored by the station to ensure it meets the minimum LINK token balance required for execution. If the balance falls below this threshold, the station will automatically use its own LINK token balance to increase the upkeep balance until it meets the required minimum.

To register a new upkeep, you will need to edit the necessary parameters inside `scripts/registerUpkeep.ts` and run the script. Once again, in the encoded `registrationParams`, the `adminAddress` must be the address of the station itself. The station must also hold an amount of LINK tokens greater than or equal to the `amount` parameter encoded in the `registrationParams`, and the allowance of LINK tokens to the Chainlink Automation Registrar must also be greater than or equal to this amount.

```
npx hardhat run scripts/registerUpkeep.ts --network arbitrum_sepolia
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

