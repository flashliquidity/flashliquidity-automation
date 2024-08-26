import { task } from "hardhat/config"

task("approveLinkToRegistrar", "Set allowance of LINK tokens to Chainlink Automation registrar")
    .addOptionalParam("amount", "The LINK token amount", "100000000000000000000")
    .setAction(async (taskArgs, { ethers }) => {
        const station = await ethers.getContract("AutomationStation")
        const tx = await station.approveLinkToRegistrar(ethers.toBigInt(taskArgs.amount))
        console.log(`Transaction Hash: ${tx.hash}`)
    })
