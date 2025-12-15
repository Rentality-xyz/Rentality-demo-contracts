const { ethers, network } = require('hardhat')

async function main() {
  const contract = await ethers.getContractAt('RentalitySender', '0x2778796c6349a42A73afc6e2904155024cf6E3fb')

//   await contract.setPeer('0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b')
  console.log(await contract.setPeer('0x252086171d2D0363290431fE1ea184BA1fE006A2'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })