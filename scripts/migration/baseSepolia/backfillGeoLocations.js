const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');
const {
  requireBaseSepolia,
  requireConfirmedWrite,
  readSnapshot,
  sendAndWait,
} = require('./importHelpers');

const OLD_GEO_ADDRESSES_PATH = path.join(
  process.cwd(),
  'src',
  'abis',
  'RentalityGeoService.v0_2_0.addresses.json'
);
const NEW_GEO_ADDRESSES_PATH = path.join(
  process.cwd(),
  'src',
  'abis',
  'base-sepolia-newmodel',
  'RentalityGeoService.v0_2_0.addresses.json'
);

function readAddress(addressesPath, chainId) {
  const data = JSON.parse(fs.readFileSync(addressesPath, 'utf8'));
  const match = data.addresses.find((item) => Number(item.chainId) === Number(chainId));
  if (!match?.address) {
    throw new Error(`No RentalityGeoService address for chain ${chainId} in ${addressesPath}`);
  }
  return match.address;
}

function valueAt(value, key, index, fallback = '') {
  if (value == null) return fallback;
  if (typeof value === 'object' && key in value) return value[key] ?? fallback;
  if (Array.isArray(value)) return value[index] ?? fallback;
  return fallback;
}

function normalizeLocationInfo(info) {
  return {
    userAddress: valueAt(info, 'userAddress', 0, ''),
    country: valueAt(info, 'country', 1, ''),
    state: valueAt(info, 'state', 2, ''),
    city: valueAt(info, 'city', 3, ''),
    latitude: valueAt(info, 'latitude', 4, ''),
    longitude: valueAt(info, 'longitude', 5, ''),
    timeZoneId: valueAt(info, 'timeZoneId', 6, ''),
  };
}

function hasCoordinates(info) {
  return Boolean(info.latitude && info.longitude);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const chainId = await requireBaseSepolia();
  requireConfirmedWrite();

  const oldGeoAddress = readAddress(OLD_GEO_ADDRESSES_PATH, chainId);
  const newGeoAddress = readAddress(NEW_GEO_ADDRESSES_PATH, chainId);

  const oldGeo = await ethers.getContractAt('RentalityGeoService', oldGeoAddress);
  const newGeo = await ethers.getContractAt('RentalityGeoService', newGeoAddress);
  const delayMs = Number(process.env.MIGRATION_TX_DELAY_MS || 1000);

  const cars = readSnapshot('legacy-cars.json').cars || [];
  const hashes = Array.from(
    new Set(
      cars
        .map((car) => valueAt(car.carInfo, 'locationHash', 17, ''))
        .filter((hash) => hash && hash !== ethers.ZeroHash)
    )
  );

  console.log(`Backfilling ${hashes.length} unique car locations`);
  console.log(`old geo: ${oldGeoAddress}`);
  console.log(`new geo: ${newGeoAddress}`);

  let imported = 0;
  let skippedEmpty = 0;
  let skippedExisting = 0;

  for (let index = 0; index < hashes.length; index++) {
    const hash = hashes[index];
    const oldLocation = normalizeLocationInfo(await oldGeo.getLocationInfo(hash));
    if (!hasCoordinates(oldLocation)) {
      skippedEmpty++;
      console.log(`skip empty old location ${index + 1}/${hashes.length}: ${hash}`);
      continue;
    }

    const currentLocation = normalizeLocationInfo(await newGeo.getLocationInfo(hash));
    if (hasCoordinates(currentLocation)) {
      skippedExisting++;
      continue;
    }

    await sendAndWait(
      `location ${index + 1}/${hashes.length} ${oldLocation.city}, ${oldLocation.state}, ${oldLocation.country}`,
      newGeo.createLocationInfo(oldLocation)
    );
    imported++;
    if (delayMs > 0) {
      await sleep(delayMs);
    }
  }

  console.log(
    `Geo location backfill finished: imported=${imported}, skippedExisting=${skippedExisting}, skippedEmpty=${skippedEmpty}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
