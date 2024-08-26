import { task } from "hardhat/config"

task("refuelUpkeep", "Manually add funds to a station upkeep")
  .addParam("upkeep", "The ID of the upkeep to add funds to")
  .addOptionalParam("amount", "The LINK tokens amount", "1000000000000000000")
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.forceUpkeepRefuel(taskArgs.upkeep, ethers.toBigInt(taskArgs.amount))
    console.log(`Transaction Hash: ${tx.hash}`)
	})