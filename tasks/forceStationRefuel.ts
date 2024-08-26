import { task } from "hardhat/config"

task("refuelStation", "Manually add funds to the main station upkeep")
  .addOptionalParam<bigint>("amount", "The LINK tokens amount", 1000000000000000000n)
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.forceStationRefuel(taskArgs.amount)
    console.log(`Transaction Hash: ${tx.hash}`)
	})