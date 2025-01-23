const { ethers } = require('hardhat')

async function startDeploy(contractName) {
  console.log(`Start deploying ${contractName}`)

  const [deployer] = await ethers.getSigners()
 
  const balance = await ethers.provider.getBalance(deployer.address)
  console.log(`Deployer address is:${await deployer.getAddress()} with balance:${balance}`)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)

  return { contractName, deployer, balance, chainId }
}

function checkNotNull(value, fieldName) {
  if (value) {
    console.log(`${fieldName} is: ${value}`)
    return value
  } else {
    throw new Error(`${fieldName} is not set`)
  }
}

module.exports = {
  startDeploy,
  checkNotNull,
}
