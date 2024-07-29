import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const amount = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.approveLinkToRegistrar(amount);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
