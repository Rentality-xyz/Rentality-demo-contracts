const { ethers, network } = require('hardhat')

async function main() {
  const contract = await ethers.getContractAt('RentalityReceiver', '0x252086171d2D0363290431fE1ea184BA1fE006A2')

//   await contract.setPeer('0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b')
  console.log(await contract.setNewPeer(40232,'0x59c2C61371b51eDf1076E37A947cA843b234C53D'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })