const { readFileSync } = require('fs')
const { network } = require('hardhat')
const { execSync } = require('child_process')
const exec = require('child_process').exec

const path = 'scripts/deploy_0_'
const pathToAddressFile = 'scripts/addressesContractsTestnets.json'


module.exports = function getContractAddress(contractName, addressToDeployScript) {
  let address = readFromFile(contractName)


  if (address === null) {
    console.log(`The contract ${contractName} is not deployed. Starting deployment...`)

    const command = 'npx hardhat run ' + addressToDeployScript
    try {
      const stdout = execSync(command);
      console.log('stdout:', stdout.toString());
    } catch (error) {
      console.error('exec error:', error);
    }
    address = readFromFile(contractName);

    if (address === null)
    {
    throw Error("Fail to deploy contract " + contractName)
    }
    setTimeout(() => {},2000); /// need,
    // because error in case of execution several scripts one by one
  }
  return address

}

function readFromFile(contractName) {
  const data = readFileSync(pathToAddressFile, 'utf-8')
  const jsonData = JSON.parse(data)

  const contract = jsonData.find((el) =>
    el.name === network.name &&
    el.chainId === network.config.chainId &&
    el[contractName] !== undefined &&
    el[contractName] !== '',
  )
  return contract === undefined ? null: contract[contractName]
}