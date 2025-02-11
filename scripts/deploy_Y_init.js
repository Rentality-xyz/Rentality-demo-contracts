const RentalityGatewayJSON_ABI = require('../src/abis/RentalityGateway.v0_2_0.abi.json')
const testData = require('./testData/testData.json')
const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { bigIntReplacer } = require('./utils/json')
const { error } = require('console')
const { signTCMessage } = require('../test/utils')

const checkInitialization = async () => {
  const { chainId, deployer } = await startDeploy('')
  if (chainId < 0) throw new Error('chainId is not set')

  const path = buildPath()
  const addressesContractsTestnets = readFileSync(path, 'utf-8')
  const addresses = JSON.parse(addressesContractsTestnets).find(
    (i) => i.chainId === Number(chainId) && i.name === network.name
  )
  if (addresses == null) {
    throw new Error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`)
  }
  const rentalityGatewayAddress = checkNotNull(addresses['RentalityGateway'], 'rentalityGatewayAddress')
  if (!rentalityGatewayAddress) {
    throw new Error(`Addresses for RentalityGateway was not found`)
  }

  const verifierAddress = checkNotNull(addresses['RentalityLocationVerifier'], 'verifierAddress')
  if (!verifierAddress) {
    throw new Error(`Addresses for RentalityLocationVerifier was not found`)
  }

  const HOST_PRIVATE_KEY = testData.hostWalletPrivateKey
  if (!HOST_PRIVATE_KEY) {
    throw new Error('HOST_PRIVATE_KEY env variable is undefined')
  }
  const host = new ethers.Wallet(HOST_PRIVATE_KEY, ethers.provider)

  const GUEST_PRIVATE_KEY = testData.guestWalletPrivateKey
  if (!GUEST_PRIVATE_KEY) {
    throw new Error('GUEST_PRIVATE_KEY env variable is undefined')
  }
  const guest = new ethers.Wallet(GUEST_PRIVATE_KEY, ethers.provider)

  const KYC_MANAGER_PRIVATE_KEY = testData.kycManagerWalletPrivateKey
  if (!KYC_MANAGER_PRIVATE_KEY) {
    throw new Error('KYC_MANAGER_PRIVATE_KEY env variable is undefined')
  }
  const kycManager = new ethers.Wallet(KYC_MANAGER_PRIVATE_KEY, ethers.provider)

  const ADMIN_PRIVATE_KEY = testData.adminWalletPrivateKey
  if (!ADMIN_PRIVATE_KEY) {
    throw new Error('ADMIN_PRIVATE_KEY env variable is undefined')
  }
  const admin = new ethers.Wallet(ADMIN_PRIVATE_KEY, ethers.provider)

  if (chainId === 1337n) {
    const hardhatAccount = new ethers.Wallet(deployer, ethers.provider)
    if ((await ethers.provider.getBalance(hardhatAccount.address)) > 0) {
      console.log('Transfering ETH for host and guest fot the Hardhat node')

      const txHost = await hardhatAccount.sendTransaction({
        to: host.address,
        value: ethers.parseEther('100.0'),
      })
      await txHost.wait()

      const txGuest = await hardhatAccount.sendTransaction({
        to: guest.address,
        value: ethers.parseEther('100.0'),
      })
      await txGuest.wait()
    } else {
      console.log('It is not hardhat node')
    }
  }

  const gateway = new ethers.Contract(rentalityGatewayAddress, RentalityGatewayJSON_ABI.abi, deployer)

  return [host, guest, kycManager, admin, gateway, verifierAddress]
}

const emptyContractLocationInfo = {
  userAddress: '',
  country: '',
  state: '',
  city: '',
  latitude: '',
  longitude: '',
  timeZoneId: '',
}

async function signLocationInfo(signer, verifierAddress, locationInfo) {
  const chainId = Number((await signer.provider?.getNetwork())?.chainId)

  const domain = {
    name: 'RentalityLocationVerifier',
    version: '1',
    chainId: chainId,
    verifyingContract: verifierAddress,
  }

  const types = {
    LocationInfo: [
      { name: 'userAddress', type: 'string' },
      { name: 'country', type: 'string' },
      { name: 'state', type: 'string' },
      { name: 'city', type: 'string' },
      { name: 'latitude', type: 'string' },
      { name: 'longitude', type: 'string' },
      { name: 'timeZoneId', type: 'string' },
    ],
  }

  return signer.signTypedData(domain, types, locationInfo)
}

async function setHostKycIfNotSet(host, kycManager, gateway) {
  console.log('\nSetting KYC for host...')

  const kyc = (await gateway.connect(host).getMyFullKYCInfo()).kyc

  if (kyc.name && kyc.licenseNumber) {
    console.log('KYC for host has already set')
    return
  }

  const data = testData.hostProfileInfo
  const email = `${data.name}${data.surname}@gmail.com`
  if (!kyc.name) {
    await gateway
      .connect(host)
      .setKYCInfo(
        data.nickname,
        data.mobilePhoneNumber,
        data.profilePhoto,
        email,
        await signTCMessage(host),
        '0x00000000'
      )
    console.log('KYC for host was set')
  }
  if (!kyc.licenseNumber) {
    await gateway.connect(kycManager).setCivicKYCInfo(host, {
      fullName: `${data.name} ${data.surname}`,
      licenseNumber: data.licenseNumber,
      expirationDate: data.expirationDate,
      issueCountry: 'UKR',
      email: email,
    })
    console.log('Civic KYC for host was set')
  }
}

async function setGuestKycIfNotSet(guest, kycManager, gateway) {
  console.log('\nSetting KYC for guest...')

  const kyc = (await gateway.connect(guest).getMyFullKYCInfo()).kyc

  if (kyc.name && kyc.licenseNumber) {
    console.log('KYC for guest has already set')
    return
  }

  const data = testData.guestProfileInfo
  const email = `${data.name}${data.surname}@gmail.com`
  if (!kyc.name) {
    await gateway
      .connect(guest)
      .setKYCInfo(data.nickname, data.mobilePhoneNumber, data.profilePhoto, email, data.tcSignature, '0x00000000')
    console.log('KYC for guest was set')
  }

  if (!kyc.licenseNumber) {
    await gateway.connect(kycManager).setCivicKYCInfo(guest, {
      fullName: `${data.name} ${data.surname}`,
      licenseNumber: data.licenseNumber,
      expirationDate: data.expirationDate,
      issueCountry: 'UKR',
      email: email,
    })
    console.log('Civic KYC for guest was set')
  }
}

async function setCarsForHost(host, admin, verifierAddress, gateway) {
  console.log('\nListing cars for host...')

  let listedCars = await gateway.connect(host).getMyCars()
  const carCount = listedCars.length

  if (carCount > 6) {
    console.log(
      `All car has been already listed. Car ids: ${JSON.stringify(listedCars.map((i) => Number(i.carInfo.carId)))}`
    )
    return listedCars.map((i) => i.carInfo.carId)
  }

  for (let index = carCount; index < 6; index++) {
    console.log(`Listing car #${index}...`)

    const carData = testData.carInfos[index]
    carData.locationInfo.signature = signLocationInfo(admin, verifierAddress, carData.locationInfo.locationInfo)

    await gateway.connect(host).addCar(carData)

    console.log(`Car #${index} listed successfully`)
  }

  listedCars = await gateway.connect(host).getMyCars()
  carIds = listedCars.map((i) => i.carInfo.carId)
  console.log(`All cars were listed. Car ids: ${JSON.stringify(carIds.map((i) => Number(i)))}`)

  return carIds
}

async function getTripCount(host, gateway) {
  return (await gateway.connect(host).getTripsAs(true)).length
}

async function createPendingTrip(tripIndex, carId, host, guest, gateway) {
  const ethAddress = ethers.getAddress('0x0000000000000000000000000000000000000000')

  const carDeliveryData = await gateway.connect(guest).getDeliveryData(carId)
  const carLocationInfo = {
    userAddress: carDeliveryData.locationInfo.userAddress,
    country: carDeliveryData.locationInfo.country,
    state: carDeliveryData.locationInfo.state,
    city: carDeliveryData.locationInfo.city,
    latitude: carDeliveryData.locationInfo.latitude,
    longitude: carDeliveryData.locationInfo.longitude,
    timeZoneId: carDeliveryData.locationInfo.timeZoneId,
  }

  const paymentsNeeded = await gateway
    .connect(guest)
    .calculatePaymentsWithDelivery(carId, 1, ethAddress, carLocationInfo, carLocationInfo, '')
  const request = {
    carId: carId,
    startDateTime: Math.ceil(new Date().getTime() / 1000 + tripIndex * 3),
    endDateTime: Math.ceil(new Date().getTime() / 1000 + tripIndex * 3 + 1),
    currencyType: ethAddress,
    pickUpInfo: {
      locationInfo: emptyContractLocationInfo,
      signature: '0x',
    },
    returnInfo: {
      locationInfo: emptyContractLocationInfo,
      signature: '0x',
    },
  }
  await gateway.connect(guest).createTripRequestWithDelivery(request, {
    value: paymentsNeeded.totalPrice,
  })

  const trips = await gateway.connect(guest).getTripsAs(false)
  const tripId = trips[trips.length - 1]?.trip?.tripId ?? -1
  console.log(`\nTrip #${tripIndex} was created with id ${tripId} and status 'Pending'`)
  return tripId
}

async function createRejectedByGuestTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createPendingTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(guest).rejectTripRequest(tripId)
  console.log(`Trip #${tripIndex} was rejected by Guest`)
  return tripId
}

async function createRejectedByHostTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createPendingTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(host).rejectTripRequest(tripId)
  console.log(`Trip #${tripIndex} was rejected by Host`)
  return tripId
}

async function createConfirmedTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createPendingTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(host).approveTripRequest(tripId)
  console.log(`Status of the trip #${tripIndex} was changed to 'Confirmed'`)
  return tripId
}

async function createCheckedInByHostTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createConfirmedTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway
    .connect(host)
    .checkInByHost(tripId, [tripIndex * 10, tripIndex * 100], 'Insurance Company', 'Insurance Numbre 123')
  console.log(`Status of the trip #${tripIndex} was changed to 'CheckedInByHost'`)
  return tripId
}

async function createStartedTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createCheckedInByHostTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(guest).checkInByGuest(tripId, [tripIndex * 10, tripIndex * 100])
  console.log(`Status of the trip #${tripIndex} was changed to 'Started'`)
  return tripId
}

async function createCheckedOutByGuestTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createStartedTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(guest).checkOutByGuest(tripId, [tripIndex * 10, tripIndex * 100])
  console.log(`Status of the trip #${tripIndex} was changed to 'CheckedOutByGuest'`)
  return tripId
}

async function createFinishedTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createCheckedOutByGuestTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(host).checkOutByHost(tripId, [tripIndex * 10, tripIndex * 100])
  console.log(`Status of the trip #${tripIndex} was changed to 'Finished'`)
  return tripId
}

async function createClosedTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createFinishedTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(host).finishTrip(tripId)
  console.log(`Status of the trip #${tripIndex} was changed to 'Closed'`)
  return tripId
}

async function createCompletedWithoutGuestComfirmationTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createStartedTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(host).checkOutByHost(tripId, [tripIndex * 10, tripIndex * 100])
  console.log(`Status of the trip #${tripIndex} was changed to 'CompletedWithoutGuestComfirmation'`)
  return tripId
}

async function createConfirmedAfterCompletedWithoutGuestComfirmationTrip(tripIndex, carId, host, guest, gateway) {
  const tripId = await createCompletedWithoutGuestComfirmationTrip(tripIndex, carId, host, guest, gateway)

  if (tripId < 0) {
    throw new error('create trip error ')
  }
  await gateway.connect(guest).confirmCheckOut(tripId)
  console.log(`Status of the trip #${tripIndex} was changed to 'Closed?'`)
  return tripId
}

async function main() {
  const [host, guest, kycManager, admin, gateway, verifierAddress] = await checkInitialization()

  await setHostKycIfNotSet(host, kycManager, gateway)
  await setGuestKycIfNotSet(guest, kycManager, gateway)

  const carIds = await setCarsForHost(host, admin, verifierAddress, gateway)
  let tripCount = await getTripCount(host, gateway)

  if (carIds.length > 0 && tripCount < 6) {
    console.log(`\nCreating trips for car #${carIds[0]}...`)
    switch (tripCount) {
      case 0:
        await createPendingTrip(0, carIds[0], host, guest, gateway)
      case 1:
        await createRejectedByGuestTrip(1, carIds[0], host, guest, gateway)
      case 2:
        await createRejectedByHostTrip(2, carIds[0], host, guest, gateway)
      case 3:
        await createConfirmedTrip(3, carIds[0], host, guest, gateway)
      case 4:
        await createClosedTrip(4, carIds[0], host, guest, gateway)
      case 5:
        await createCheckedInByHostTrip(5, carIds[0], host, guest, gateway)
    }
  }

  if (carIds.length > 1 && tripCount <= 6) {
    console.log(`\nCreating trips for car #${carIds[1]}...`)
    await createStartedTrip(6, carIds[1], host, guest, gateway)
  }
  if (carIds.length > 2 && tripCount <= 7) {
    console.log(`\nCreating trips for car #${carIds[2]}...`)
    await createCheckedOutByGuestTrip(7, carIds[2], host, guest, gateway)
    tripCount++
  }
  if (carIds.length > 3 && tripCount <= 8) {
    console.log(`\nCreating trips for car #${carIds[3]}...`)
    await createFinishedTrip(8, carIds[3], host, guest, gateway)
  }
  if (carIds.length > 4 && tripCount <= 9) {
    console.log(`\nCreating trips for car #${carIds[4]}...`)
    await createCompletedWithoutGuestComfirmationTrip(9, carIds[4], host, guest, gateway)
  }
  if (carIds.length > 5 && tripCount <= 10) {
    console.log(`\nCreating trips for car #${carIds[5]}...`)
    await createConfirmedAfterCompletedWithoutGuestComfirmationTrip(10, carIds[5], host, guest, gateway)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
