const { ethers, upgrades } = require('hardhat')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
async function main() {
  const { contractName, chainId } = await startDeploy('RentalityTripsView')
console.log("CHAiN ID", chainId)
console.log("CONTRACT NAME", contractName)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })