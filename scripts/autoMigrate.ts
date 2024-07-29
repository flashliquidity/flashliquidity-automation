import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const newRegistry = '' // NEW CHAINLINK AUTOMATION REGISTRY TO MIGRATE UPKEEPS TO
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.autoMigrate(newRegistry);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
