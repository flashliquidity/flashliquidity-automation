import { task } from "hardhat/config"

task("removeUpkeep", "Remove an upkeep from the station list without canceling it")
  .addParam<number>("index", "The index of the upkeep to be removed from the station list")
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.removeUpkeep(taskArgs.index)
    console.log(`Transaction Hash: ${tx.hash}`)
	})