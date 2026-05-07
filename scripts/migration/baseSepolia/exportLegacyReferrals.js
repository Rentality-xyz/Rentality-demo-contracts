const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const OUTPUT_PATH = path.join(DATA_DIR, 'legacy-referrals.json');

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

function getNetwork(addressBook) {
  const network = addressBook.find((entry) => Number(entry.chainId) === CHAIN_ID);
  if (!network) {
    throw new Error(`No network entry found for chainId ${CHAIN_ID} in ${LEGACY_REF}`);
  }

  return network;
}

function getAddress(network, contractName) {
  if (!network[contractName]) {
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

function requireSnapshot(name) {
  const snapshotPath = path.join(DATA_DIR, name);
  if (!fs.existsSync(snapshotPath)) {
    throw new Error(`${snapshotPath} is required. Export dependent snapshots first.`);
  }

  return readJson(snapshotPath);
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

function appendGatewaySender(data, sender) {
  return `${data}${ethers.getAddress(sender).slice(2).toLowerCase()}`;
}

async function gatewayStaticCall(provider, contractAddress, gatewayAddress, iface, functionName, args, sender) {
  const data = appendGatewaySender(iface.encodeFunctionData(functionName, args), sender);
  const result = await provider.call({
    to: contractAddress,
    from: gatewayAddress,
    data,
  });

  return normalizeValue(iface.decodeFunctionResult(functionName, result));
}

async function main() {
  const rpcUrl = process.env.BASE_SEPOLIA_URL;
  if (!rpcUrl) {
    throw new Error('BASE_SEPOLIA_URL is required in .env to export Base Sepolia state');
  }

  const carsSnapshot = requireSnapshot('legacy-cars.json');
  const tripsSnapshot = requireSnapshot('legacy-trips.json');
  const insuranceSnapshot = requireSnapshot('legacy-insurance.json');
  const investmentsSnapshot = requireSnapshot('legacy-investments.json');

  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const referralAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityReferralProgram.v0_2_0.abi.json');
  const network = getNetwork(addressBook);
  const referralAddress = getAddress(network, 'RentalityReferralProgram');
  const gatewayAddress = getAddress(network, 'RentalityGateway');

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const referralAbi = normalizeAbi(referralAbiArtifact);
  const referral = new ethers.Contract(referralAddress, referralAbi, provider);
  const referralInterface = new ethers.Interface(referralAbi);

  const users = new Set();
  collectAddresses(carsSnapshot.cars, users);
  collectAddresses(tripsSnapshot.trips, users);
  collectAddresses(insuranceSnapshot, users);
  collectAddresses(investmentsSnapshot, users);
  const userList = [...users].sort();

  const carIds = carsSnapshot.cars.map((car) => Number(car.carId));
  const carDailyClaimed = [];
  for (let index = 0; index < carIds.length; index++) {
    const carId = carIds[index];
    const claimedTime = await optionalCall(`getCarDailyClaimedTime(${carId})`, () =>
      referral.getCarDailyClaimedTime(carId)
    );
    carDailyClaimed.push({ carId, claimedTime });
    process.stdout.write(`Exported referral car claim ${index + 1}/${carIds.length}\r`);
  }
  process.stdout.write('\n');

  const userReferrals = [];
  for (let index = 0; index < userList.length; index++) {
    const user = userList[index];
    const [
      points,
      startDiscount,
      readyToClaim,
      readyToClaimFromReferralHash,
      referralHash,
      referralHashV2,
      myReferralInfo,
      pointsHistory,
    ] = await Promise.all([
      optionalCall(`addressToPoints(${user})`, () => referral.addressToPoints(user)),
      optionalCall(`getMyStartDiscount(${user})`, () => referral.getMyStartDiscount(user)),
      optionalCall(`getReadyToClaim(${user})`, () => referral.getReadyToClaim(user)),
      optionalCall(`getReadyToClaimFromRefferalHash(${user})`, () => referral.getReadyToClaimFromRefferalHash(user)),
      optionalCall(`referralHash(${user})`, () => referral.referralHash(user)),
      optionalCall(`referralHashV2(${user})`, () => referral.referralHashV2(user)),
      optionalCall(`getMyRefferalInfo(${user})`, () =>
        gatewayStaticCall(provider, referralAddress, gatewayAddress, referralInterface, 'getMyRefferalInfo', [], user)
      ),
      optionalCall(`getPointsHistory(${user})`, () =>
        gatewayStaticCall(provider, referralAddress, gatewayAddress, referralInterface, 'getPointsHistory', [], user)
      ),
    ]);

    userReferrals.push({
      user,
      points,
      startDiscount,
      readyToClaim,
      readyToClaimFromReferralHash,
      referralHash,
      referralHashV2,
      myReferralInfo,
      pointsHistory,
    });
    process.stdout.write(`Exported user referral ${index + 1}/${userList.length}\r`);
  }
  process.stdout.write('\n');

  const [allTiersInfo, referralPointsInfo, emptyToClaim] = await Promise.all([
    optionalCall('getAllTearsInfo()', () => referral.getAllTearsInfo()),
    optionalCall('getRefferalPointsInfo()', () => referral.getRefferalPointsInfo()),
    optionalCall('getEmptyToClaim()', () => referral.getEmptyToClaim()),
  ]);

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityReferralProgram: referralAddress,
      RentalityGateway: gatewayAddress,
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
      insurance: insuranceSnapshot.totals,
      investments: investmentsSnapshot.totals,
    },
    totals: {
      knownUsers: userReferrals.length,
      carDailyClaimed: carDailyClaimed.length,
    },
    allTiersInfo,
    referralPointsInfo,
    emptyToClaim,
    carDailyClaimed,
    userReferrals,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy referrals exported: ${userReferrals.length} users, ${carDailyClaimed.length} cars`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
