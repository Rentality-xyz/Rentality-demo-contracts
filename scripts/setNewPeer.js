const { ethers, upgrades } = require('hardhat')

async function main() {


    let sender = await ethers.getContractAt(
      'RentalityReceiver',
      '0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b'
    )

    console.log('Encoded data:', await sender.setNewPeer(40232, '0xd281c18CAbDe03B04238BeFAbF5E3c92B1e97250'))
    
  

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

