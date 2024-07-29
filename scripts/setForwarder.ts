import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const forwarder = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.setForwarder(forwarder);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
