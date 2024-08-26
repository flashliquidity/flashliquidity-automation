import { task } from "hardhat/config"

task("unpauseUpkeeps", "Unpause specified upkeeps")
    .addVariadicPositionalParam("upkeeps")
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.unpauseUpkeeps(taskArgs.upkeeps)
        console.log(`Transaction Hash: ${tx.hash}`)
    })
