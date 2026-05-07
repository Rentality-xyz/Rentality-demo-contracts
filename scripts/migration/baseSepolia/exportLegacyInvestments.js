const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const OUTPUT_PATH = path.join(DATA_DIR, 'legacy-investments.json');

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
    throw new Error(`${snapshotPath} is required. Export cars first.`);
  }

  return readJson(snapshotPath);
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

async function findInvestorManager(userService, platformUsers, fallbackUsers) {
  const candidates = [...new Set([...platformUsers, ...fallbackUsers].map((address) => ethers.getAddress(address)))];

  for (const candidate of candidates) {
    const isInvestorManager = await optionalCall(`isInvestorManager(${candidate})`, () =>
      userService.isInvestorManager(candidate)
    );
    if (isInvestorManager === true) {
      return candidate;
    }
  }

  return null;
}

async function main() {
  const rpcUrl = process.env.BASE_SEPOLIA_URL;
  if (!rpcUrl) {
    throw new Error('BASE_SEPOLIA_URL is required in .env to export Base Sepolia state');
  }

  const carsSnapshot = requireSnapshot('legacy-cars.json');
  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const investmentAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityInvestment.v0_2_0.abi.json');
  const userServiceAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityUserService.v0_2_0.abi.json');

  const network = getNetwork(addressBook);
  const investmentAddress = getAddress(network, 'RentalityInvestment');
  const userServiceAddress = getAddress(network, 'RentalityUserService');
  const gatewayAddress = getAddress(network, 'RentalityGateway');

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const investmentInterface = new ethers.Interface(normalizeAbi(investmentAbiArtifact));
  const userService = new ethers.Contract(userServiceAddress, normalizeAbi(userServiceAbiArtifact), provider);

  const fallbackUsers = carsSnapshot.cars
    .map((car) => car.owner)
    .filter((owner) => typeof owner === 'string' && /^0x[a-fA-F0-9]{40}$/.test(owner));
  const platformUsers = [];
  const investorManager = await findInvestorManager(userService, platformUsers, fallbackUsers);

  const callSender = investorManager || gatewayAddress;
  const investments = await optionalCall('getAllInvestments()', () =>
    gatewayStaticCall(
      provider,
      investmentAddress,
      gatewayAddress,
      investmentInterface,
      'getAllInvestments',
      [],
      callSender
    )
  );

  const carPaymentInfo = [];
  for (let index = 0; index < carsSnapshot.cars.length; index++) {
    const carId = Number(carsSnapshot.cars[index].carId);
    const paymentInfo = await optionalCall(`getPaymentsInfo(${carId})`, () =>
      gatewayStaticCall(
        provider,
        investmentAddress,
        gatewayAddress,
        investmentInterface,
        'getPaymentsInfo',
        [carId],
        callSender
      )
    );

    carPaymentInfo.push({ carId, paymentInfo });
    process.stdout.write(`Exported investment payment info ${index + 1}/${carsSnapshot.cars.length}\r`);
  }
  process.stdout.write('\n');

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityInvestment: investmentAddress,
      RentalityUserService: userServiceAddress,
      RentalityGateway: gatewayAddress,
    },
    callContext: {
      investorManager,
      callSender,
      platformUsersCount: platformUsers.length,
    },
    sourceSnapshots: {
      cars: {
        totalSupply: carsSnapshot.totalSupply,
        exportedCars: carsSnapshot.exportedCars,
      },
    },
    totals: {
      investments: Array.isArray(investments) ? investments.length : null,
      carPaymentInfo: carPaymentInfo.length,
    },
    investments,
    carPaymentInfo,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy investments exported: ${Array.isArray(investments) ? investments.length : 'unavailable'} investments`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
