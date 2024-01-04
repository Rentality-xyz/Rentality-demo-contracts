const { ethers } = require('hardhat')
const contractName = 'RentalityUserService'
const [deployer] = await ethers.getSigners()
const balance = await ethers.provider.getBalance(deployer.address)
console.log(
  'Deployer address is:',
  await deployer.getAddress(),
  ' with balance:',
  balance,
)
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
