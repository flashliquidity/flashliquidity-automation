import { exec } from 'child_process'
import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const upkeepIDs = ['']
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.pauseUpkeeps(upkeepIDs);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
