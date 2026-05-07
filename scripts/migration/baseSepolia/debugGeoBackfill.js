const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');
const { requireBaseSepolia, readSnapshot } = require('./importHelpers');

function readAddress(filePath, chainId) {
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const match = data.addresses.find((item) => Number(item.chainId) === Number(chainId));
  if (!match?.address) throw new Error(`No address for chain ${chainId} in ${filePath}`);
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

async function main() {
  const chainId = await requireBaseSepolia();
  const carId = Number(process.env.DEBUG_CAR_ID || 1);
  const cars = readSnapshot('legacy-cars.json').cars || [];
  const car = cars.find((item) => Number(item.carId) === carId);
  if (!car) throw new Error(`Car ${carId} not found in legacy-cars.json`);

  const locationHash = valueAt(car.carInfo, 'locationHash', 17, '');
  console.log(`carId=${carId}`);
  console.log(`snapshot locationHash=${locationHash}`);

  const oldGeoAddress = readAddress(
    path.join(process.cwd(), 'src', 'abis', 'RentalityGeoService.v0_2_0.addresses.json'),
    chainId
  );
  const newGeoAddress = readAddress(
    path.join(process.cwd(), 'src', 'abis', 'base-sepolia-newmodel', 'RentalityGeoService.v0_2_0.addresses.json'),
    chainId
  );
  const carGatewayFacet2Address = readAddress(
    path.join(process.cwd(), 'src', 'abis', 'base-sepolia-newmodel', 'CarGatewayFacet2.v0_2_0.addresses.json'),
    chainId
  );

  const oldGeo = await ethers.getContractAt('RentalityGeoService', oldGeoAddress);
  const newGeo = await ethers.getContractAt('RentalityGeoService', newGeoAddress);
  const carGatewayFacet2 = await ethers.getContractAt('CarGatewayFacet2', carGatewayFacet2Address);

  console.log(`oldGeo=${oldGeoAddress}`);
  console.log(`newGeo=${newGeoAddress}`);
  console.log(`carGatewayFacet2=${carGatewayFacet2Address}`);

  console.log('oldGeo.getLocationInfo:', normalizeLocationInfo(await oldGeo.getLocationInfo(locationHash)));
  console.log('newGeo.getLocationInfo:', normalizeLocationInfo(await newGeo.getLocationInfo(locationHash)));

  const details = await carGatewayFacet2.getCarDetails(carId);
  console.log('facet.getCarDetails.locationInfo:', normalizeLocationInfo(details.locationInfo));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
