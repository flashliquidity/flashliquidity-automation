import { task } from "hardhat/config"

task("refuelUpkeep", "Manually add funds to a station upkeep")
  .addParam<string>("upkeep", "The ID of the upkeep to add funds to")
  .addOptionalParam<bigint>("amount", "The LINK tokens amount", 1000000000000000000n)
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.forceUpkeepRefuel(taskArgs.upkeep, taskArgs.amount)
    console.log(`Transaction Hash: ${tx.hash}`)
	})