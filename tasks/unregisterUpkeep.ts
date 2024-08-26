import { task } from "hardhat/config"

task("unregisterUpkeep", "Unregister and remove an upkeep from the station list")
  .addParam("index", "The index of the upkeep to be canceled")
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.unregisterUpkeep(taskArgs.index)
    console.log(`Transaction Hash: ${tx.hash}`)
	})