import { task } from "hardhat/config"

task("initialize", "Initialize the station by registering the main upkeep")
	.addOptionalParam("registry", "Chainlink Automation registry", "0x0000000000000000000000000000000000000000")
	.addOptionalParam("amount", "The LINK token amount to fund the station upkeep", "10000000000000000000")
  .addOptionalParam("gasLimit", "The maximum gas limit that will be used for txns by the station upkeep")
	.setAction(async (taskArgs, { ethers }) => {
		const station = await ethers.getContract("AutomationStation") 
    const stationAddr = await station.getAddress()
    const registrationParams = ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(string,bytes,address,uint32,address,uint8,bytes,bytes,bytes,uint96)"],
      [
        [
          "AutomationStation", 
          "0x", 
          stationAddr, 
          750000, 
          stationAddr, 
          0, 
          "0x", 
          "0x", 
          "0x", 
          ethers.toBigInt(taskArgs.amount)
        ]
      ]
    )
    const tx = await station.initialize(taskArgs.registry, registrationParams)
    console.log(`Transaction Hash: ${tx.hash}`)
    await tx.wait(2)
    const stationUpkeepID = await station.getStationUpkeepID()
    console.log('AutomationStation initialized with upkeep ID: ', stationUpkeepID.toString())
    if(taskArgs.registry == ethers.ZeroAddress) {
      console.log("Chainlink Automation forwarder not set, setForwarder task must be executed")
    }
	})