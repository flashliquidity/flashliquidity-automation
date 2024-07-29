import { ethers } from 'hardhat'

async function main() {
  const stationAddr = ''
  const registry = '' // CHAINLINK AUTOMATION REGISTRY
  /**
   * string name = "test upkeep";
   * bytes encryptedEmail = 0x;
   * address upkeepContract = 0x...;
   * uint32 gasLimit = 500000;
   * address adminAddress = 0x....;
   * uint8 triggerType = 0;
   * bytes checkData = 0x;
   * bytes triggerConfig = 0x;
   * bytes offchainConfig = 0x;
   * uint96 amount = 1000000000000000000;
   */
  //cast abi-encode "registerUpkeep((string,bytes,address,uint32,address,uint8,bytes,bytes,bytes,uint96))" '(Arbiter01, 0x, 0xFA42B9412Ea8f0bcfD4B11bB10a471Fb4f9B6Fac, 1000000, 0xFA42B9412Ea8f0bcfD4B11bB10a471Fb4f9B6Fac, 0, 0x, 0x, 0x, 2000000000000000000)'
  const registrationParams = ''
  const AutomationStation = await ethers.getContractFactory('AutomationStation')
  const station = AutomationStation.attach(stationAddr)
  await station.initialize(registry, registrationParams)
  const stationUpkeepID = await station.getStationUpkeepID();
  console.log('AutomationStation upkeep ID: ', stationUpkeepID.toString())
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
