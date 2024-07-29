import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const upkeepID = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.removeUpkeep(upkeepID);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
