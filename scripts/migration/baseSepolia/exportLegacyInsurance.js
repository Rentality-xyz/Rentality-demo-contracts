const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const OUTPUT_PATH = path.join(DATA_DIR, 'legacy-insurance.json');

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function readJsonFromGit(ref, filePath) {
  return JSON.parse(
    execFileSync('git', ['show', `${ref}:${filePath}`], {
      cwd: process.cwd(),
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    })
  );
}

function normalizeAbi(artifact) {
  return artifact.abi || artifact;
}

function getAddress(addressBook, contractName) {
  const network = addressBook.find((entry) => Number(entry.chainId) === CHAIN_ID);
  if (!network || !network[contractName]) {
    throw new Error(`No ${contractName} address found for chainId ${CHAIN_ID} in ${LEGACY_REF}`);
  }

  return network[contractName];
}

function normalizeValue(value) {
  if (typeof value === 'bigint') {
    return value.toString();
  }

  if (Array.isArray(value)) {
    return value.map((item) => normalizeValue(item));
  }

  if (value && typeof value === 'object') {
    if (typeof value.toObject === 'function') {
      try {
        return normalizeValue(value.toObject());
      } catch (_error) {
        // Some ethers Result values contain unnamed tuple fields. Fall back to array/object traversal.
      }
    }

    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, normalizeValue(item)]));
  }

  return value;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function optionalCall(label, call, retries = 3) {
  let lastError;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return normalizeValue(await call());
    } catch (error) {
      lastError = error;
      if (attempt < retries) {
        await sleep(250 * (attempt + 1));
      }
    }
  }

  return {
    unavailable: true,
    label,
    reason: lastError.shortMessage || lastError.message,
  };
}

function collectAddresses(value, output) {
  if (typeof value === 'string' && /^0x[a-fA-F0-9]{40}$/.test(value)) {
    const address = ethers.getAddress(value);
    if (address !== ethers.ZeroAddress) {
      output.add(address);
    }
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item) => collectAddresses(item, output));
    return;
  }

  if (value && typeof value === 'object') {
    Object.values(value).forEach((item) => collectAddresses(item, output));
  }
}

function requireSnapshot(name) {
  const snapshotPath = path.join(DATA_DIR, name);
  if (!fs.existsSync(snapshotPath)) {
    throw new Error(`${snapshotPath} is required. Export cars and trips first.`);
  }

  return readJson(snapshotPath);
}

async function main() {
  const rpcUrl = process.env.BASE_SEPOLIA_URL;
  if (!rpcUrl) {
    throw new Error('BASE_SEPOLIA_URL is required in .env to export Base Sepolia state');
  }

  const carsSnapshot = requireSnapshot('legacy-cars.json');
  const tripsSnapshot = requireSnapshot('legacy-trips.json');
  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const insuranceAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityInsurance.v0_2_0.abi.json');
  const insuranceAddress = getAddress(addressBook, 'RentalityInsurance');

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const insurance = new ethers.Contract(insuranceAddress, normalizeAbi(insuranceAbiArtifact), provider);

  const carIds = carsSnapshot.cars.map((car) => Number(car.carId));
  const tripIds = tripsSnapshot.trips.map((trip) => Number(trip.tripId));
  const users = new Set();
  collectAddresses(carsSnapshot.cars, users);
  collectAddresses(tripsSnapshot.trips, users);

  const carInsurance = [];
  for (let index = 0; index < carIds.length; index++) {
    const carId = carIds[index];
    const [info, price] = await Promise.all([
      optionalCall(`getCarInsuranceInfo(${carId})`, () => insurance.getCarInsuranceInfo(carId)),
      optionalCall(`getInsurancePriceByCar(${carId})`, () => insurance.getInsurancePriceByCar(carId)),
    ]);

    carInsurance.push({ carId, info, price });
    process.stdout.write(`Exported car insurance ${index + 1}/${carIds.length}\r`);
  }
  process.stdout.write('\n');

  const tripInsurance = [];
  for (let index = 0; index < tripIds.length; index++) {
    const tripId = tripIds[index];
    const [price, insurances] = await Promise.all([
      optionalCall(`getInsurancePriceByTrip(${tripId})`, () => insurance.getInsurancePriceByTrip(tripId)),
      optionalCall(`getTripInsurances(${tripId})`, () => insurance.getTripInsurances(tripId)),
    ]);

    tripInsurance.push({ tripId, price, insurances });
    process.stdout.write(`Exported trip insurance ${index + 1}/${tripIds.length}\r`);
  }
  process.stdout.write('\n');

  const guestInsurance = [];
  const userList = [...users].sort();
  for (let index = 0; index < userList.length; index++) {
    const user = userList[index];
    const [hasActiveGeneralInsurance, insurances] = await Promise.all([
      optionalCall(`isGuestHasInsurance(${user})`, () => insurance.isGuestHasInsurance(user)),
      optionalCall(`getMyInsurancesAsGuest(${user})`, () => insurance.getMyInsurancesAsGuest(user)),
    ]);

    guestInsurance.push({ user, hasActiveGeneralInsurance, insurances });
    process.stdout.write(`Exported guest insurance ${index + 1}/${userList.length}\r`);
  }
  process.stdout.write('\n');

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityInsurance: insuranceAddress,
    },
    sourceSnapshots: {
      cars: {
        totalSupply: carsSnapshot.totalSupply,
        exportedCars: carsSnapshot.exportedCars,
      },
      trips: {
        totalTripCount: tripsSnapshot.totalTripCount,
        exportedTrips: tripsSnapshot.exportedTrips,
      },
    },
    totals: {
      carInsurance: carInsurance.length,
      tripInsurance: tripInsurance.length,
      knownUsers: guestInsurance.length,
    },
    carInsurance,
    tripInsurance,
    guestInsurance,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy insurance exported: ${carInsurance.length} cars, ${tripInsurance.length} trips, ${guestInsurance.length} users`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
