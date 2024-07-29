import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const to = ''
  const tokens = ['']
  const amounts = ['']
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.recoverERC20(to, tokens, amounts)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
