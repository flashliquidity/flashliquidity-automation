import { task } from "hardhat/config"

task("setRefuelConfig", "Set the parameters used to add funds to upkeeps")
    .addParam("refuelAmount", "The amount that will be added to underfunded upkeeps")
    .addParam(
        "stationUpkeepMinBalance",
        "The minimum balance for the main station upkeep after which is considered underfunded",
    )
    .addParam(
        "minDelay",
        "The minimum delay between consecutive refuels of the same upkeep (except for the main station upkeep)",
    )
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.setRefuelConfig(
            taskArgs.refuelAmount,
            taskArgs.stationUpkeepMinBalance,
            taskArgs.minDelay,
        )
        console.log(`Transaction Hash: ${tx.hash}`)
    })
