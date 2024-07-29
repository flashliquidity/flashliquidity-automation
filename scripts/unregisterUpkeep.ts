import { exec } from 'child_process'
import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const upkeepIndex = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.unregisterUpkeep(upkeepIndex);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
