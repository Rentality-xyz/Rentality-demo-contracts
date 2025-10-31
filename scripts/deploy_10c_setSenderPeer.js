const { ethers, network } = require('hardhat')

async function main() {
  const contract = await ethers.getContractAt('RentalitySender', '0x1C97042e54bAa7ba8d58520b855ec67C6Ff4286C')
  const addressToSet = '0x467D254DF93C8F6437F3158A9B875f24d9473990'

//   await contract.setPeer('0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b')
  console.log(await contract.setPeer('0xC774418A741b472dD697092766517F8C238972a7'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })