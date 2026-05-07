const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const OUTPUT_PATH = path.join(process.cwd(), 'migration-data', 'base-sepolia', 'legacy-cars.json');

function readJsonFromGit(ref, filePath) {
  const content = execFileSync('git', ['show', `${ref}:${filePath}`], {
    cwd: process.cwd(),
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  return JSON.parse(content);
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

async function optionalCall(label, call, fallback = null, retries = 3) {
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
    fallback,
  };
}

async function main() {
  const rpcUrl = process.env.BASE_SEPOLIA_URL;
  if (!rpcUrl) {
    throw new Error('BASE_SEPOLIA_URL is required in .env to export Base Sepolia state');
  }

  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const carAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityCarToken.v0_2_0.abi.json');
  const carAddress = getAddress(addressBook, 'RentalityCarToken');

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const carToken = new ethers.Contract(carAddress, normalizeAbi(carAbiArtifact), provider);
  const totalSupply = Number(await carToken.totalSupply());

  const cars = [];
  const skippedCars = [];
  for (let carId = 1; carId <= totalSupply; carId++) {
    const exists = await optionalCall(`exists(${carId})`, () => carToken.exists(carId), true);
    if (exists === false) {
      skippedCars.push({
        carId,
        reason: 'exists returned false',
      });
      continue;
    }

    const [carInfo, owner, tokenURI, listingMoment] = await Promise.all([
      optionalCall(`getCarInfoById(${carId})`, () => carToken.getCarInfoById(carId)),
      optionalCall(`ownerOf(${carId})`, () => carToken.ownerOf(carId)),
      optionalCall(`tokenURI(${carId})`, () => carToken.tokenURI(carId)),
      optionalCall(`getListingMoment(${carId})`, () => carToken.getListingMoment(carId)),
    ]);

    cars.push({
      carId,
      exists,
      owner,
      tokenURI,
      listingMoment,
      carInfo,
    });

    process.stdout.write(`Exported legacy car ${carId}/${totalSupply}\r`);
  }

  process.stdout.write('\n');

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityCarToken: carAddress,
    },
    totalSupply,
    exportedCars: cars.length,
    skippedCars,
    cars,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy cars exported: ${cars.length}/${totalSupply}`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
