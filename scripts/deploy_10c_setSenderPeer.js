const { ethers, network } = require('hardhat')

async function main() {
  const contract = await ethers.getContractAt('RentalitySender', '0xd281c18CAbDe03B04238BeFAbF5E3c92B1e97250')
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