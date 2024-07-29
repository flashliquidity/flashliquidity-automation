import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const refuelAmount = ''
  const stationUpkeepMinBalance = ''
  const minDelayNextRefuel = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.setRefuelConfig(refuelAmount, stationUpkeepMinBalance, minDelayNextRefuel);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
