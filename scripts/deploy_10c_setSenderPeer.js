const { ethers, network } = require('hardhat')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const readlineSync = require('readline-sync')
const { getContractAddress } = require('./utils/contractAddress')


async function main() {

  const { contractName, chainId } = await startDeploy('')
  const receiverChainId = readlineSync.question('Target chainId:\n')

  console.log('Receiver chainId: ', receiverChainId)


  const senderAddress = checkNotNull(
    getContractAddress('RentalitySender', 'scripts/deploy_10a_RentalitySender.js', chainId),
    'RentalitySender'
  )

  const receiverAddress = checkNotNull(
    getContractAddress('RentalityReceiver', 'scripts/deploy_10b_RentalityReceiver.js', receiverChainId),
    'RentalityReceiver'
  )

   const contract = await ethers.getContractAt('RentalitySender', senderAddress)

  console.log(await contract.setPeer(receiverAddress)) 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })