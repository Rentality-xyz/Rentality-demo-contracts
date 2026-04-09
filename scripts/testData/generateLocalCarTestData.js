const { readFile, writeFile, mkdir, stat } = require('node:fs/promises')
const path = require('node:path')
const { HDNodeWallet } = require('ethers')

const FRONTEND_ENV_PATH = 'D:/Programms/dApps/Rentality/RentalityPrototypeNEW/.env.local'
const OUTPUT_DIR = __dirname
const OUTPUT_TEST_DATA_PATH = path.join(OUTPUT_DIR, 'testData.json')
const OUTPUT_MANIFEST_PATH = path.join(OUTPUT_DIR, 'carPhotoManifest.json')

const DEFAULT_HARDHAT_MNEMONIC = 'test test test test test test test test test test test junk'
const DEFAULT_LOCATION_INFO = {
  userAddress: 'Miami Riverwalk, Miami, Florida, US',
  country: 'US',
  state: 'Florida',
  city: 'Miami',
  latitude: '25.777747',
  longitude: '-80.216416',
  timeZoneId: 'America/New_York',
}

const PIN_FILE_URL = 'https://api.pinata.cloud/pinning/pinFileToIPFS'
const PIN_JSON_URL = 'https://api.pinata.cloud/pinning/pinJSONToIPFS'

const CAR_SPECS = [
  {
    brand: 'BMW',
    model: 'X5 M Competition',
    yearOfProduction: 2024,
    color: 'Silver',
    bodyType: 'SUV',
    seatsNumber: 5,
    doorsNumber: 5,
    trunkSize: 'Large',
    transmission: 'Automatic',
    wheelDrive: 'AWD',
    tankVolumeInGal: 22,
    filePath: 'D:/1/car_bmw.jpg',
  },
  {
    brand: 'Audi',
    model: 'Q8 e-tron',
    yearOfProduction: 2024,
    color: 'White',
    bodyType: 'SUV Coupe',
    seatsNumber: 5,
    doorsNumber: 5,
    trunkSize: 'Large',
    transmission: 'Automatic',
    wheelDrive: 'AWD',
    tankVolumeInGal: 0,
    filePath: 'D:/1/audi_e.png',
  },
  {
    brand: 'Ferrari',
    model: 'Portofino',
    yearOfProduction: 2023,
    color: 'Red',
    bodyType: 'Coupe',
    seatsNumber: 2,
    doorsNumber: 2,
    trunkSize: 'Medium',
    transmission: 'Automatic',
    wheelDrive: 'RWD',
    tankVolumeInGal: 21,
    filePath: 'D:/1/Ferrari_3.png',
  },
  {
    brand: 'Tesla',
    model: 'Model 3',
    yearOfProduction: 2024,
    color: 'Gray',
    bodyType: 'Sedan',
    seatsNumber: 5,
    doorsNumber: 4,
    trunkSize: 'Medium',
    transmission: 'Automatic',
    wheelDrive: 'RWD',
    tankVolumeInGal: 0,
    filePath: 'D:/1/tesla.png',
  },
  {
    brand: 'Hyundai',
    model: 'Ioniq 5',
    yearOfProduction: 2024,
    color: 'White',
    bodyType: 'Crossover',
    seatsNumber: 5,
    doorsNumber: 5,
    trunkSize: 'Medium',
    transmission: 'Automatic',
    wheelDrive: 'AWD',
    tankVolumeInGal: 0,
    filePath: 'D:/1/hyundai.jpg',
  },
  {
    brand: 'Toyota',
    model: 'Sienna',
    yearOfProduction: 2024,
    color: 'Bronze',
    bodyType: 'Minivan',
    seatsNumber: 7,
    doorsNumber: 5,
    trunkSize: 'Large',
    transmission: 'Automatic',
    wheelDrive: 'FWD',
    tankVolumeInGal: 18,
    filePath: 'D:/1/toyota.png',
  },
]

function deriveHardhatPrivateKey(index) {
  return HDNodeWallet.fromPhrase(DEFAULT_HARDHAT_MNEMONIC, undefined, `m/44'/60'/0'/0/${index}`).privateKey
}

function readEnvValue(source, key) {
  const match = source.match(new RegExp(`^${key}\\s*=\\s*(.+)$`, 'm'))
  if (!match) return ''
  return match[1].trim().replace(/^['\"]|['\"]$/g, '')
}

async function loadPinataJwt() {
  if (process.env.NEXT_PUBLIC_PINATA_JWT) return process.env.NEXT_PUBLIC_PINATA_JWT
  const envFile = await readFile(FRONTEND_ENV_PATH, 'utf8')
  return readEnvValue(envFile, 'NEXT_PUBLIC_PINATA_JWT')
}

function toIpfsUri(cid) {
  return `ipfs://${cid}`
}

function getPinataHeaders(jwt) {
  return {
    Authorization: `Bearer ${jwt}`,
  }
}

async function uploadFileToPinata(filePath, fileName, jwt, keyValues = {}) {
  await stat(filePath)
  const fileBuffer = await readFile(filePath)
  const blob = new Blob([fileBuffer])
  const form = new FormData()
  form.append('file', blob, path.basename(filePath))
  form.append('pinataMetadata', JSON.stringify({ name: fileName, keyvalues: keyValues }))
  form.append(
    'pinataOptions',
    JSON.stringify({
      cidVersion: 0,
      customPinPolicy: {
        regions: [
          { id: 'FRA1', desiredReplicationCount: 1 },
          { id: 'NYC1', desiredReplicationCount: 1 },
        ],
      },
    })
  )

  const response = await fetch(PIN_FILE_URL, {
    method: 'POST',
    headers: getPinataHeaders(jwt),
    body: form,
  })

  if (!response.ok) {
    throw new Error(`Pinata file upload failed (${response.status}): ${await response.text()}`)
  }

  const payload = await response.json()
  if (!payload.IpfsHash) {
    throw new Error(`Pinata file upload returned no IpfsHash for ${filePath}`)
  }

  return payload.IpfsHash
}

async function uploadJsonToPinata(jsonBody, fileName, jwt, keyValues = {}) {
  const response = await fetch(PIN_JSON_URL, {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      ...getPinataHeaders(jwt),
    },
    body: JSON.stringify({
      pinataContent: jsonBody,
      pinataOptions: { cidVersion: 0 },
      pinataMetadata: { name: fileName, keyvalues: keyValues },
    }),
  })

  if (!response.ok) {
    throw new Error(`Pinata JSON upload failed (${response.status}): ${await response.text()}`)
  }

  const payload = await response.json()
  if (!payload.IpfsHash) {
    throw new Error(`Pinata JSON upload returned no IpfsHash for ${fileName}`)
  }

  return payload.IpfsHash
}

function buildMetadata(carInfo, imageUri) {
  return {
    name: `${carInfo.brand} ${carInfo.model}`,
    description: `${carInfo.brand} ${carInfo.model} local seed car for Rentality demo`,
    image: imageUri,
    allImages: [imageUri],
    attributes: [
      { trait_type: 'VIN number', value: carInfo.carVinNumber },
      { trait_type: 'License plate', value: `SEED-${carInfo.brand.slice(0, 3).toUpperCase()}-${carInfo.yearOfProduction}` },
      { trait_type: 'License state', value: 'Florida' },
      { trait_type: 'Brand', value: carInfo.brand },
      { trait_type: 'Model', value: carInfo.model },
      { trait_type: 'Release year', value: String(carInfo.yearOfProduction) },
      { trait_type: 'Body type', value: carInfo.bodyType },
      { trait_type: 'Color', value: carInfo.color },
      { trait_type: 'Doors number', value: String(carInfo.doorsNumber) },
      { trait_type: 'Seats number', value: String(carInfo.seatsNumber) },
      { trait_type: 'Trunk size', value: carInfo.trunkSize },
      { trait_type: 'Transmission', value: carInfo.transmission },
      { trait_type: 'Wheel drive', value: carInfo.wheelDrive },
      { trait_type: 'Tank volume(gal)', value: String(carInfo.tankVolumeInGal) },
    ],
  }
}

function buildCarInfo(spec, tokenUri, index) {
  const seed = index + 1
  return {
    tokenUri,
    carVinNumber: `SEEDVIN${String(seed).padStart(10, '0')}`,
    brand: spec.brand,
    model: spec.model,
    yearOfProduction: spec.yearOfProduction,
    color: spec.color,
    bodyType: spec.bodyType,
    seatsNumber: spec.seatsNumber,
    doorsNumber: spec.doorsNumber,
    trunkSize: spec.trunkSize,
    transmission: spec.transmission,
    wheelDrive: spec.wheelDrive,
    tankVolumeInGal: spec.tankVolumeInGal,
    pricePerDayInUsdCents: seed * 100 + 2,
    securityDepositPerTripInUsdCents: seed * 100 + 3,
    engineParams: [seed * 100 + 4, seed * 100 + 5],
    engineType: 1,
    milesIncludedPerDay: seed * 100 + 6,
    timeBufferBetweenTripsInSec: 0,
    geoApiKey: ' ',
    locationInfo: {
      locationInfo: DEFAULT_LOCATION_INFO,
      signature: '0x',
    },
    currentlyListed: true,
    insuranceIncluded: true,
    insuranceRequired: false,
    insurancePriceInUsdCents: 0,
    dimoTokenId: 0,
    signedDimoTokenId: '0x',
  }
}

function buildDefaultTestData(carInfos) {
  return {
    hostWalletPrivateKey: deriveHardhatPrivateKey(1),
    guestWalletPrivateKey: deriveHardhatPrivateKey(2),
    adminWalletPrivateKey: deriveHardhatPrivateKey(3),
    kycManagerWalletPrivateKey: deriveHardhatPrivateKey(4),
    hostProfileInfo: {
      nickname: 'host',
      mobilePhoneNumber: '+15550000001',
      profilePhoto: 'host-photo',
      tcSignature: '0x',
      privateKey: deriveHardhatPrivateKey(1),
      publicKey: '',
      name: 'Host',
      surname: 'Local',
      licenseNumber: 'HOST-123456',
      expirationDate: 1893456000,
    },
    guestProfileInfo: {
      nickname: 'guest',
      mobilePhoneNumber: '+15550000002',
      profilePhoto: 'guest-photo',
      tcSignature: '0x',
      privateKey: deriveHardhatPrivateKey(2),
      publicKey: '',
      name: 'Guest',
      surname: 'Local',
      licenseNumber: 'GUEST-123456',
      expirationDate: 1893456000,
    },
    carInfos,
  }
}

async function main() {
  const jwt = await loadPinataJwt()
  if (!jwt) {
    throw new Error('NEXT_PUBLIC_PINATA_JWT was not found in the environment or frontend .env.local')
  }

  await mkdir(OUTPUT_DIR, { recursive: true })

  const manifest = []
  const carInfos = []

  for (let index = 0; index < CAR_SPECS.length; index += 1) {
    const spec = CAR_SPECS[index]
    const baseCarInfo = buildCarInfo(spec, '', index)
    const seedLabel = `${index + 1}/${CAR_SPECS.length}`

    console.log(`Uploading image ${seedLabel}: ${spec.brand} ${spec.model}`)
    const imageCid = await uploadFileToPinata(
      spec.filePath,
      `1337_RentalitySeedCarImage_${index + 1}`,
      jwt,
      { seed: 'localhost-cars', carIndex: index + 1, brand: spec.brand, model: spec.model }
    )
    const imageUri = toIpfsUri(imageCid)

    console.log(`Uploading metadata ${seedLabel}: ${spec.brand} ${spec.model}`)
    const metadataCid = await uploadJsonToPinata(
      buildMetadata(baseCarInfo, imageUri),
      `1337_RentalitySeedCarMetadata_${index + 1}`,
      jwt,
      { seed: 'localhost-cars', carIndex: index + 1, brand: spec.brand, model: spec.model }
    )
    const tokenUri = toIpfsUri(metadataCid)

    carInfos.push(buildCarInfo(spec, tokenUri, index))
    manifest.push({
      carIndex: index + 1,
      brand: spec.brand,
      model: spec.model,
      localFile: spec.filePath,
      imageCid,
      imageUri,
      metadataCid,
      tokenUri,
    })
  }

  await writeFile(OUTPUT_TEST_DATA_PATH, JSON.stringify(buildDefaultTestData(carInfos), null, 2) + '\n')
  await writeFile(OUTPUT_MANIFEST_PATH, JSON.stringify(manifest, null, 2) + '\n')

  console.log(`Created ${OUTPUT_TEST_DATA_PATH}`)
  console.log(`Created ${OUTPUT_MANIFEST_PATH}`)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
