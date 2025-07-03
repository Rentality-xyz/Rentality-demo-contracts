const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')

const tripsFilter = {
  paymentStatus: 0,
  status: 0,
  location: emptyLocationInfo,
  startDateTime: 0,
  endDateTime: 1893456000,
}
//block 26718122
async function main() {
let contract = await ethers.getContractAt('IRentalityGateway','0xF57bBa938f5eD700648819971A13757e8064e40e')
console.log(await contract.getAvaibleCurrencies())

  // const taxesData = Array.from({ length: 52 }, (_, i) => ({
  //   eType: 5,
  //   id: i + 1,
  //   objectStatus: 0,
  //   from: ethToken,
  //   to: ethToken,
  // }));

  // let userService = await ethers.getContractAt('RentalityUserService','0xE15378Ad98796BB35cbbc116DfC70d3416B52D45')
  // let userData = await userService.getPlatformUsers();
  // let users = userData.map((user) => {
  //   return {
  //     eType: 3,
  //     id:0,
  //     objectStatus: 0,
  //     from: user,
  //     to: user,
  //   }})

  const claims = Array.from({ length: 82 }, (_, i) => ({
    eType: 1,
    id: i + 1,
    objectStatus: 0,
    from: ethToken,
    to: ethToken,
  }))
  let mods = [
    {
      eType: 8,
      id: 0,
      objectStatus: 1,
      from: ethToken,
      to: ethToken,
    },
    {
      eType: 7,
      id: 0,
      objectStatus: 1,
      from: ethToken,
      to: ethToken,
    },
    {
      eType: 6,
      id: 0,
      objectStatus: 1,
      from: ethToken,
      to: ethToken,
    },
  ]

  console.log('Notification service address: ', await notificationService.emitAll(mods))
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
