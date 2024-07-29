import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const registrar = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.setRegistrar(registrar);
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
