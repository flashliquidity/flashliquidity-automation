import { task } from "hardhat/config"

task("registerUpkeep", "Register a new upkeep and add it to the list of monitored upkeeps")
	.addParam("name", "The name of the upkeep")
	.addParam("contract", "The address of your Automation-compatible contract")
  .addParam("gasLimit", "The maximum gas limit that will be used for txns by this upkeep")
  .addOptionalParam("triggerType", "0 is Conditional upkeep, 1 is Log trigger upkeep", "0")
  .addOptionalParam("checkData", "checkData is a static input that you can specify now which will be sent into your checkUpkeep or checkLog, see interface.", "0x")
  .addOptionalParam("triggerConfig", "The configuration for your upkeep. 0x for conditional upkeeps.", "0x")
  .addOptionalParam("offchainConfig", "Leave as 0x, or use this field to set a gas price threshold for your upkeep.", "0x")
	.addOptionalParam("amount", "The LINK token amount to fund the upkeep", "5000000000000000000")
	.setAction(async (taskArgs, { ethers }) => {
	  const station = await ethers.getContract("AutomationStation")
    const stationAddr = await station.getAddress()
    const registrationParams = ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(string,bytes,address,uint32,address,uint8,bytes,bytes,bytes,uint96)"],
      [
        [
          taskArgs.name,                    // string name = "test upkeep";
          "0x",                             // bytes encryptedEmail = 0x;
          taskArgs.contract,                // address upkeepContract = 0x...;
          taskArgs.gasLimit,                // uint32 gasLimit = 500000;
          stationAddr,                      // address adminAddress = 0x....;
          taskArgs.triggerType,             // uint8 triggerType = 0;
          taskArgs.checkData,               // bytes checkData = 0x;
          taskArgs.triggerConfig,           // bytes triggerConfig = 0x;
          taskArgs.offchainConfig,          // bytes offchainConfig = 0x;
          ethers.toBigInt(taskArgs.amount)  // uint96 amount = 1000000000000000000;
        ]
      ]
    )
    const allUpkeepsLen = await station.allUpkeepsLength()
    const tx = await station.registerUpkeep(registrationParams)
    console.log(`Transaction Hash: ${tx.hash}`)
    await tx.wait(2)
    const upkeepID = await station.getUpkeepIdAtIndex(allUpkeepsLen.toString())
    console.log('New upkeep ID: ', upkeepID.toString())
	})