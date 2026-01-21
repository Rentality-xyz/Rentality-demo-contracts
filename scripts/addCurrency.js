const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  let swaps = await ethers.getContractAt('RentalitySwaps','0x2a3390352Cc6f216D9613A996E17Be6b80D4FA02')

  // console.log(await swaps.getAllowedCurrencies())
//   let contract = await ethers.getContractAt('RentalityCurrencyConverter','0xA3492D84a36236939e77184327b4072CAefAF3E0')

console.log(await swaps.addAllowedCurrency("0x565df9Ea339318cb31526f65b24139A506d8B82A"))

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
