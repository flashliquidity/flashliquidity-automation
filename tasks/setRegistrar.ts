import { task } from "hardhat/config"

task("setRegistrar", "Set the address of Chainlink Automation registrar")
    .addParam("registrar", "The address of Chainlink Automation registrar")
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.setRegistrar(taskArgs.registrar)
        console.log(`Transaction Hash: ${tx.hash}`)
    })
