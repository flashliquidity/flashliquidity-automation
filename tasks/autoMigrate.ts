import { task } from "hardhat/config"

task("migrate", "Migrate all station upkeeps to a new Chainlink Automation registry")
  .addParam<string>("registry", "The address of the new Chainlink Automation registry to migrate upkeeps to")
	.setAction(async (taskArgs, { ethers }) => {
    const station = await ethers.getContract("AutomationStation")
    const tx = await station.autoMigrate(taskArgs.registry)
    console.log(`Transaction Hash: ${tx.hash}`)
	})