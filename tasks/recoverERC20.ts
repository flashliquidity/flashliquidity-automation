import { task } from "hardhat/config"

task("recoverTokens", "Transfer tokens from the station")
  .addParam("to", "The recipient address")
  .addParam("token", "The address of the token to be transferred")
  .addParam("amount", "The amount to be transferred")
	.setAction(async (taskArgs, { ethers }) => {
		const station = await ethers.getContract("AutomationStation")
    const tokens = [taskArgs.token]
    const amounts = [taskArgs.amount] 
    const tx = await station.recoverERC20(taskArgs.to, tokens, amounts)
    console.log(`Transaction Hash: ${tx.hash}`)
	})