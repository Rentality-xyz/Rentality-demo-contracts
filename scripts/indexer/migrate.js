const saveJsonAbi = require('../utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('../utils/addressSaver')
const { startDeploy, checkNotNull } = require('../utils/deployHelper');
const { ethToken } = require('../../test/utils');
const { getContractAddress } = require('../utils/contractAddress');

const EventType = Object.freeze({
    Car: 0,
    Claim: 1,
    Trip: 2,
    User: 3,
    Insurance: 4,
    Taxes: 5,
    Discount: 6,
    Delivery: 7,
    Currency: 8,
    AddClaimType: 9,
    SaveTripInsurance: 10
  });

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityMockPriceFeed')

  const notificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )
  
  let notificationContract = await ethers.getContractAt('RentalityNotificationService', notificationService)

  const defaultDataEvents = [{
    eType: EventType.Currency,
    id: 0,        
    objectStatus: 1,
    from: ethToken,
    to: ethToken   
  },
  {
  eType: EventType.Delivery,
  id: 0,        
  objectStatus: 1,
  from: ethToken,
  to: ethToken   
},
{
    eType: EventType.Discount,
    id: 0,        
    objectStatus: 1,
    from: ethToken,
    to: ethToken   
  },
  ]

  const taxesEvents = Array.from({ length: 51 }, (_, i) => ({
    eType: EventType.Taxes,
    id: i + 2,        
    objectStatus: 0,
    from: ethToken,
    to: ethToken   
  }));
  console.log(await notificationContract.emitAll(defaultDataEvents.concat(taxesEvents)))
  console.log("Taxes events, Default events emited!")
  const userProfileQuery = checkNotNull(
    getContractAddress('UserProfileQuery', 'scripts/deploy_1i_UserProfileQuery.js', chainId),
    'UserProfileQuery'
  )

  const userProfileQueryContract = await ethers.getContractAt('UserProfileQuery', userProfileQuery)

  const users = await userProfileQueryContract.getPlatformUsers();
  let userEvents = users.map((u) => {
    {
        return {
            eType: EventType.User,
            id: 0,
            objectStatus: 0,
            from: u,
            to: u
        }
    }}
  )
  let insuranceEvents = users.map((u) => {
    return {
        eType: EventType.Insurance,
        id: 0,
        objectStatus: 1,
        from: u,
        to: u
    }
  })
  console.log(await notificationContract.emitAll(userEvents.concat(insuranceEvents)))
  console.log("User events, Insurance events emited!")

  const carGatewayAdapterAddress = checkNotNull(
    getContractAddress('CarGatewayAdapter', 'scripts/deploy_3_CarGatewayAdapter.js', chainId),
    'CarGatewayAdapter'
  )

  let carContract = await ethers.getContractAt('ICarGateway', carGatewayAdapterAddress)


  let totalSupply = await carContract.totalSupply();
 
  let carEvents = Array.from({ length: Number(totalSupply) }, (_, i) => ({
    eType: EventType.Car,
    id: i + 1,        
    objectStatus: 0,
    from: ethToken,
    to: ethToken   
  }));
  console.log(await notificationContract.emitAll(carEvents.concat()))
  console.log("Car events emited!")

  let tripsAddress = checkNotNull(getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId), 'TripQuery')

  let tripsContract = await ethers.getContractAt('TripQuery', tripsAddress)

  let totalTrips = await tripsContract.totalSupply();

  let tripsEvents = Array.from({ length: Number(totalTrips) }, (_, i) => ({
    eType: EventType.Trip,
    id: i + 1,        
    objectStatus: 0,
    from: ethToken,
    to: ethToken   
  }));

  console.log(await notificationContract.emitAll(tripsEvents.concat()))
  console.log("Trips events emited!")



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })





