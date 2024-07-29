import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const upkeepIDs = ['']
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.addUpkeeps(upkeepIDs);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
