import {HardhatRuntimeEnvironment} from 'hardhat/types'
import {DeployFunction} from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const linkToken = '' // ERC 677 LINK TOKEN ADDRESS
  const registrar = '' // CHAINLINK AUTOMATION REGISTRAR ADDRESS
  const registerUpkeepSelector = '0x3f678e11' // CHAINLINK REGISTRAR registerUpkeep FUNCTION SELECTOR
  const refuelAmount = '1000000000000000000'  // AMOUNT OF LINK TOKEN TO ADD TO UNDERFUNDED UPKEEPS
  const stationUpkeepMinBalance = '1000000000000000000' // MINIMUM LINK BALANCE FOR MAIN STATION UPKEEP AFTER WHICH REFUEL IS NEEDED
  const minDelayNextRefuel = '600' // MINIMUM DELAY BETWEEN CONSECUTIVE REFUELS FOR AN UPKEEP (MAIN STATION UPKEEP EXCLUDED)
  const approveAmountLINK = '100000000000000000000' // INITIAL LINK ALLOWANCE TO CHAINLINK REGISTRAR

  const {deployments, getNamedAccounts} = hre
  const {deploy} = deployments
  const {deployer} = await getNamedAccounts()

  await deploy('AutomationStation', {
    from: deployer,
    args: [    
      linkToken, 
      registrar, 
      registerUpkeepSelector, 
      refuelAmount, 
      stationUpkeepMinBalance, 
      minDelayNextRefuel,
      approveAmountLINK
    ],
    log: true,
  })
}

export default func

func.tags = ['AutomationStation']
