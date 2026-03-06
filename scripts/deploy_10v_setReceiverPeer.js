const { ethers, network } = require('hardhat')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const readlineSync = require('readline-sync')
const chains = require('../chainIdToEid.json');
const { getContractAddress } = require('./utils/contractAddress')

async function main() {


  const { contractName, chainId } = await startDeploy('')


  const senderChainId = readlineSync.question('Sender chainId:\n')
  
  const senderAddress = checkNotNull(
    getContractAddress('RentalitySender', 'scripts/deploy_10a_RentalitySender.js', senderChainId),
    'RentalitySender'
  )


  const receiverAddress = checkNotNull(
    getContractAddress('RentalityReceiver', 'scripts/deploy_10b_RentalityReceiver.js', chainId),
    'RentalityReceiver'
  )

  const contract = await ethers.getContractAt('RentalityReceiver', receiverAddress)

  let eid = chains[senderChainId].eid

  console.log('Sender chainId: ', senderChainId, ' eid: ', eid)
  // console.log(await contract.setNewPeer(eid, senderAddress))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })