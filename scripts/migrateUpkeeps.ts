import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const oldRegistry = '' // OLD CHAINLINK REGISTRY TO MIGRATE UPKEEPS FROM
  const newRegistry = '' // NEW CHAINLINK AUTOMATION REGISTRY TO MIGRATE UPKEEPS TO
  const upkeepIDs = ['']
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.migrateUpkeeps(oldRegistry, newRegistry, upkeepIDs);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
