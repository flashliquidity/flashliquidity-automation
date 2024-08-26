import { task } from "hardhat/config"

task("pauseUpkeeps", "Pause specified upkeeps")
  .addVariadicPositionalParam("upkeeps")
	.setAction(async (taskArgs, { ethers }) => {
		const station = await ethers.getContract("AutomationStation") 
    const tx = await station.pauseUpkeeps(taskArgs.upkeeps)
    console.log(`Transaction Hash: ${tx.hash}`)
	})