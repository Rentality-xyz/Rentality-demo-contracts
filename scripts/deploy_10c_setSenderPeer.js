const { ethers, network } = require('hardhat')

async function main() {
  const contract = await ethers.getContractAt('RentalitySender', '0xa253A36D6Ca39219d1789ce5F2E5c6D41e99Bc83')
  const addressToSet = '0x467D254DF93C8F6437F3158A9B875f24d9473990'

//   await contract.setPeer('0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b')
  console.log(await contract.setPeer('0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })