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
    endDateTime: 1893456000
    
}
//block 26718122
async function main() {

    // enum EventType {
    //     Car,
    //     Claim,
    //     Trip,
    //     User,
    //     Insurance,
    //     Taxes,
    //     Discount,
    //     Delivery,
    //     Currency
    //   }
    //   Schemas.EventType eType;
    //   uint256 id;
    //   uint8 objectStatus;
    //   address from;
    //   address to;

const adminContract = await ethers.getContractAt('RentalityAdminGateway','0xE27172d322E2ba92A9cDCd17D5021B82df7B6b95')

// const users = await adminContract.getPlatformUsersInfo(1,100)
// const u = users.kycInfos
// .map(
//     user => {
//        return { eType: 3, id: 0, objectStatus: 0, from: user.wallet, to: user.wallet }
      
//     });

    const cars = Array.from({ length: 162 }, (_, i) => ({
        eType: 0,
        id: i + 1,
        objectStatus: 0,
        from: ethToken,
        to: ethToken
      }));
      console.log("CARS", cars)


// const trips =  Array.from({ length: 447 }, (_, i) => ({
//     eType: 2,
//     id: i + 1,
//     objectStatus: 0,
//     from: ethToken,
//     to: ethToken
//   }));
const v = await ethers.getContractAt('RentalityNotificationService','0x6538488EAD213996727D1f4eC9738c3C92141180')
// const request = [
//     { eType: 5, id: 2, objectStatus: 1, from: ethToken, to: ethToken },
//     { eType: 6, id: 2, objectStatus: 1, from: ethToken, to: ethToken },
//     { eType: 7, id: 2, objectStatus: 1, from: ethToken, to: ethToken }

// ]

const taxes = Array.from({ length: 52 }, (_, i) => ({
    eType: 5,
    id: i + 1,
    objectStatus: 0,
    from: ethToken,
    to: ethToken
  }));
  const paymentService = await ethers.getContractAt('RentalityPaymentService','0x6080F7A1F4fDaED78e01CDC951Bb15588B04EBF7')
  const gateway = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')
  const taxesContract = await ethers.getContractAt('RentalityTaxes','0x2287de614e0CafED95b42c45dd959176F4a9fF14')
  const ids = [
    1,2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
    12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
    42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
    52,53
  ];
  const states = [
    "Florida",
    "Florida","Florida","Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
    "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts",
    "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska",
    "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina",
    "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
    "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
    "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming", "District of Columbia"
  ];

//   const carToken = await ethers.getContractAt('RentalityCarToken','0xCfd84b30b9fddaa275b38a40E08D8bE990688033')
//   const details = await gateway.getCarDetails(162)
//   console.log(details.locationInfo)

  console.log(await gateway.getTaxesInfoById(2))
//   console.log(ids.length)
//   console.log(await taxesContract.setTaxesLocations(ids,states))
//   console.log(await gateway.getTaxesInfoById(0))
// console.log(taxes)
const currency = {
    eType: 9,
    id:0,
    objectStatus: 1,
    from: ethToken,
    to: ethToken
  }
console.log(await v.emitAll([{
    eType: 8,
    id:0,
    objectStatus: 1,
    from: ethToken,
    to: ethToken
  }]))
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
