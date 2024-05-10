const { ethers, upgrades } = require('hardhat')
const readlineSync = require('readline-sync')

async function startRecovering() {
  const [deployer] = await ethers.getSigners()

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1

  console.log('Recover proxy metadata in chainId:', chainId)

  const contractName = readlineSync.question('Enter contract name to recover:\n')

  return [contractName, chainId]
}
module.exports = {
  startRecovering,
}
