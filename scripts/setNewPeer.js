const { ethers, upgrades } = require('hardhat')

async function main() {


    let sender = await ethers.getContractAt(
      'RentalityReceiver',
      '0x335cA50Fe7CB4e06a1708e599644361e45F5B153'
    )

    console.log('Encoded data:', await sender.setNewPeer(40232, '0x1C97042e54bAa7ba8d58520b855ec67C6Ff4286C'))
    
  

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

