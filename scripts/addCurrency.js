const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  let swaps = await ethers.getContractAt('RentalitySwaps','0x820404483885356af5FB7376078774c2A0beA509')

  // console.log(await swaps.getAllowedCurrencies())
//   let contract = await ethers.getContractAt('RentalityCurrencyConverter','0xA3492D84a36236939e77184327b4072CAefAF3E0')

console.log(await swaps.addAllowedCurrency("0xB24DaDAe370Ff7C9492FA0d1DE99FdfF019Ca46B"))

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
