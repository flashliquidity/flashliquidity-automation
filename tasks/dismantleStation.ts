import { task } from "hardhat/config"

task("dismantle", "Cancel the main station upkeep, all other upkeeps must be already canceled")
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.dismantle()
    console.log(`Transaction Hash: ${tx.hash}`)
	})