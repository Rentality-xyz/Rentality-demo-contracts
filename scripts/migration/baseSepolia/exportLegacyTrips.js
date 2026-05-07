const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const OUTPUT_PATH = path.join(process.cwd(), 'migration-data', 'base-sepolia', 'legacy-trips.json');

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

async function main() {
  const rpcUrl = process.env.BASE_SEPOLIA_URL;
  if (!rpcUrl) {
    throw new Error('BASE_SEPOLIA_URL is required in .env to export Base Sepolia state');
  }

  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const tripAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityTripService.v0_2_0.abi.json');
  const tripAddress = getAddress(addressBook, 'RentalityTripService');

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const tripService = new ethers.Contract(tripAddress, normalizeAbi(tripAbiArtifact), provider);
  const totalTripCount = Number(await tripService.totalTripCount());

  const trips = [];
  const unavailableTrips = [];
  for (let tripId = 1; tripId <= totalTripCount; tripId++) {
    const trip = await optionalCall(`getTrip(${tripId})`, () => tripService.getTrip(tripId));
    const completedByAdmin = await optionalCall(`completedByAdmin(${tripId})`, () => tripService.completedByAdmin(tripId));
    const ethSumInTripCreation = await optionalCall(
      `tripIdToEthSumInTripCreation(${tripId})`,
      () => tripService.tripIdToEthSumInTripCreation(tripId)
    );

    if (trip && trip.unavailable) {
      unavailableTrips.push({ tripId, reason: trip.reason });
      continue;
    }

    trips.push({
      tripId,
      trip,
      completedByAdmin,
      ethSumInTripCreation,
    });

    process.stdout.write(`Exported legacy trip ${tripId}/${totalTripCount}\r`);
  }

  process.stdout.write('\n');

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityTripService: tripAddress,
    },
    totalTripCount,
    exportedTrips: trips.length,
    unavailableTrips,
    trips,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy trips exported: ${trips.length}/${totalTripCount}`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
