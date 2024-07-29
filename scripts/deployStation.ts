import { ethers } from 'hardhat'

async function main() {
  const linkToken = '' // ERC 677 LINK TOKEN ADDRESS
  const registrar = '' // CHAINLINK AUTOMATION REGISTRAR ADDRESS
  const registerUpkeepSelector = '0x3f678e11' // CHAINLINK REGISTRAR registerUpkeep FUNCTION SELECTOR
  const refuelAmount = '1000000000000000000'  // AMOUNT OF LINK TOKEN TO ADD TO UNDERFUNDED UPKEEPS
  const stationUpkeepMinBalance = '1000000000000000000' // MINIMUM LINK BALANCE FOR MAIN STATION UPKEEP AFTER WHICH REFUEL IS NEEDED
  const minDelayNextRefuel = '600' // MINIMUM DELAY BETWEEN CONSECUTIVE REFUELS FOR AN UPKEEP (MAIN STATION UPKEEP EXCLUDED)
  const approveAmountLINK = '100000000000000000000' // INITIAL LINK ALLOWANCE TO CHAINLINK REGISTRAR
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = await AutomationStation.deploy(
    linkToken, 
    registrar, 
    registerUpkeepSelector, 
    refuelAmount, 
    stationUpkeepMinBalance, 
    minDelayNextRefuel,
    approveAmountLINK
  )
  await station.waitForDeployment()
  console.log(`AutomationStation deployed to: ${station.target}`)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
