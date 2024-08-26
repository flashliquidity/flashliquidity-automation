import { task } from "hardhat/config"

task("setForwarder", "Set the address of the forwarder of the main station upkeep")
  .addParam("forwarder", "The address of the forwarder")
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.setForwarder(taskArgs.forwarder)
    console.log(`Transaction Hash: ${tx.hash}`)
	})