const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const OUTPUT_PATH = path.join(DATA_DIR, 'legacy-profiles.json');

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

async function main() {
  const rpcUrl = process.env.BASE_SEPOLIA_URL;
  if (!rpcUrl) {
    throw new Error('BASE_SEPOLIA_URL is required in .env to export Base Sepolia state');
  }

  const snapshots = [
    requireSnapshot('legacy-cars.json'),
    requireSnapshot('legacy-trips.json'),
    requireSnapshot('legacy-insurance.json'),
    requireSnapshot('legacy-investments.json'),
    requireSnapshot('legacy-referrals.json'),
  ];

  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const userServiceAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityUserService.v0_2_0.abi.json');
  const network = getNetwork(addressBook);
  const userServiceAddress = getAddress(network, 'RentalityUserService');

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const userService = new ethers.Contract(userServiceAddress, normalizeAbi(userServiceAbiArtifact), provider);

  const users = new Set();
  snapshots.forEach((snapshot) => collectAddresses(snapshot, users));
  const userList = [...users].sort();

  const roleNames = [
    'isAdmin',
    'isAdminViewRole',
    'isGuest',
    'isHost',
    'isHostOrGuest',
    'isInvestorManager',
    'isManager',
    'isOracleManager',
    'isRentalityPlatform',
    'isSignatureManager',
  ];

  const profiles = [];
  for (let index = 0; index < userList.length; index++) {
    const user = userList[index];
    const [kycInfo, myFullKYCInfo, hasPassedKYC, hasPassedKYCAndTC, hasValidKYC] = await Promise.all([
      optionalCall(`getKYCInfo(${user})`, () => userService.getKYCInfo(user)),
      optionalCall(`getMyFullKYCInfo(${user})`, () => userService.getMyFullKYCInfo(user)),
      optionalCall(`hasPassedKYC(${user})`, () => userService.hasPassedKYC(user)),
      optionalCall(`hasPassedKYCAndTC(${user})`, () => userService.hasPassedKYCAndTC(user)),
      optionalCall(`hasValidKYC(${user})`, () => userService.hasValidKYC(user)),
    ]);

    const roles = {};
    for (const roleName of roleNames) {
      roles[roleName] = await optionalCall(`${roleName}(${user})`, () => userService[roleName](user));
    }

    profiles.push({
      user,
      kycInfo,
      myFullKYCInfo,
      hasPassedKYC,
      hasPassedKYCAndTC,
      hasValidKYC,
      roles,
    });

    process.stdout.write(`Exported profile ${index + 1}/${userList.length}\r`);
  }
  process.stdout.write('\n');

  const adminViewUser = profiles.find((profile) => profile.roles.isAdminViewRole === true)?.user || null;
  const [kycCommission, platformUsersCount, platformUsers] = await Promise.all([
    optionalCall('getKycCommission()', () => userService.getKycCommission()),
    optionalCall('getPlatformUsersCount()', () => userService.getPlatformUsersCount()),
    adminViewUser
      ? optionalCall(`getPlatformUsers({ from: ${adminViewUser} })`, () => userService.getPlatformUsers({ from: adminViewUser }))
      : null,
  ]);

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityUserService: userServiceAddress,
    },
    sourceSnapshots: {
      files: [
        'legacy-cars.json',
        'legacy-trips.json',
        'legacy-insurance.json',
        'legacy-investments.json',
        'legacy-referrals.json',
      ],
    },
    totals: {
      knownUsers: profiles.length,
    },
    global: {
      kycCommission,
      platformUsersCount,
      adminViewUser,
      platformUsers,
    },
    profiles,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy profiles exported: ${profiles.length} users`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
