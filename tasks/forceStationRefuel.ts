import { task } from "hardhat/config"

task("refuelStation", "Manually add funds to the main station upkeep")
    .addOptionalParam("amount", "The LINK tokens amount", "1000000000000000000")
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.forceStationRefuel(ethers.toBigInt(taskArgs.amount))
        console.log(`Transaction Hash: ${tx.hash}`)
    })
