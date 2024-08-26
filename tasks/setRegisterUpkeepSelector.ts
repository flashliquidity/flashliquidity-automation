import { task } from "hardhat/config"

task("setRegisterUpkeepSelector", "Set the registerUpkeep function selector")
    .addParam("selector", "The registerUpkeep function selector of Chainlink Automation registrar")
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.setRegisterUpkeepSelector(taskArgs.selector)
        console.log(`Transaction Hash: ${tx.hash}`)
    })
