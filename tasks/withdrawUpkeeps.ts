import { task } from "hardhat/config"

task("withdrawUpkeeps", "Withdraw LINK tokens from canceled upkeeps")
  .addVariadicPositionalParam("upkeeps")
	.setAction(async (taskArgs, { ethers }) => {
		const station = await ethers.getContract("AutomationStation") 
    const tx = await station.withdrawUpkeeps(taskArgs.upkeeps)
    console.log(`Transaction Hash: ${tx.hash}`)
	})