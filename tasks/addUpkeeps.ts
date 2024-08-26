import { task } from "hardhat/config"

task("addUpkeeps", "Add already registered upkeeps to the list of upkeeps monitored by the station")
  .addVariadicPositionalParam("upkeeps")
	.setAction(async (taskArgs, { ethers }) => {
		const station = await ethers.getContract("AutomationStation") 
    const tx = await station.addUpkeeps(taskArgs.upkeeps)
    console.log(`Transaction Hash: ${tx.hash}`)
	})