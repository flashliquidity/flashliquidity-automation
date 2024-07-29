import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const upkeepID = ''
  const refuelAmount = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.forceUpkeepRefuel(upkeepID, refuelAmount);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
