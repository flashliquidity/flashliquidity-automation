import { task } from "hardhat/config"

task("approveLinkToRegistrar", "Set allowance of LINK tokens to Chainlink Automation registrar")
  .addOptionalParam<bigint>("amount", "The LINK token amount", 100000000000000000000n)
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.approveLinkToRegistrar(taskArgs.amount)
    console.log(`Transaction Hash: ${tx.hash}`)
	})