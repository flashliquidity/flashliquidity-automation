import { task } from "hardhat/config"

task("migrateUpkeeps", "Migrate specified upkeeps from a Chainlink registry to a new one")
    .addParam(
        "fromRegistry",
        "The address of the Chainlink Automation registry to migrate upkeeps from",
    )
    .addParam(
        "toRegistry",
        "The address of the Chainlink Automation registry to migrate upkeeps to",
    )
    .addVariadicPositionalParam("upkeeps")
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.migrateUpkeeps(
            taskArgs.fromRegistry,
            taskArgs.toRegistry,
            taskArgs.upkeeps,
        )
        console.log(`Transaction Hash: ${tx.hash}`)
    })
