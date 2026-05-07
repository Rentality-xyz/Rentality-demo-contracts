const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { ethers } = require('ethers');
require('dotenv').config();

const CHAIN_ID = 84532;
const LEGACY_REF = process.env.LEGACY_CONTRACTS_GIT_REF || 'main';
const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const OUTPUT_PATH = path.join(DATA_DIR, 'legacy-pricing-payments.json');

const ERC20_ABI = ['function balanceOf(address account) view returns (uint256)'];

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

function getAddress(network, contractName, required = true) {
  if (!network[contractName]) {
    if (required) {
      throw new Error(`No ${contractName} address found for chainId ${CHAIN_ID} in ${LEGACY_REF}`);
    }
    return null;
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

  const carsSnapshot = requireSnapshot('legacy-cars.json');
  const tripsSnapshot = requireSnapshot('legacy-trips.json');
  const profilesSnapshot = requireSnapshot('legacy-profiles.json');

  const addressBook = readJsonFromGit(LEGACY_REF, 'scripts/addressesContractsTestnets.v0_2_0.json');
  const paymentAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityPaymentService.v0_2_0.abi.json');
  const deliveryAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityCarDelivery.v0_2_0.abi.json');
  const discountAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityBaseDiscount.v0_2_0.abi.json');
  const taxesAbiArtifact = readJsonFromGit(LEGACY_REF, 'src/abis/RentalityTaxes.v0_2_0.abi.json');

  const network = getNetwork(addressBook);
  const paymentAddress = getAddress(network, 'RentalityPaymentService');
  const deliveryAddress = getAddress(network, 'RentalityCarDelivery');
  const baseDiscountAddress = getAddress(network, 'RentalityBaseDiscount');
  const taxesAddress = getAddress(network, 'RentalityTaxes');
  const tokenAddresses = {
    DefaultAllowedToken: getAddress(network, 'DefaultAllowedToken', false),
    RentalityTestUSDT: getAddress(network, 'RentalityTestUSDT', false),
    RentalityTestUSDC: getAddress(network, 'RentalityTestUSDC', false),
  };

  const provider = new ethers.JsonRpcProvider(rpcUrl, CHAIN_ID);
  const payment = new ethers.Contract(paymentAddress, normalizeAbi(paymentAbiArtifact), provider);
  const delivery = new ethers.Contract(deliveryAddress, normalizeAbi(deliveryAbiArtifact), provider);
  const discount = new ethers.Contract(baseDiscountAddress, normalizeAbi(discountAbiArtifact), provider);
  const taxes = new ethers.Contract(taxesAddress, normalizeAbi(taxesAbiArtifact), provider);

  const users = new Set();
  collectAddresses(carsSnapshot, users);
  collectAddresses(tripsSnapshot, users);
  collectAddresses(profilesSnapshot, users);
  const userList = [...users].sort();
  const tripIds = tripsSnapshot.trips.map((trip) => Number(trip.tripId));

  const [platformFeeInPPM, paymentBaseDiscountAddress, baseDefaultDiscount] = await Promise.all([
    optionalCall('getPlatformFeeInPPM()', () => payment.getPlatformFeeInPPM()),
    optionalCall('getBaseDiscount()', () => payment['getBaseDiscount()']()),
    optionalCall('defaultDiscount()', () => discount.defaultDiscount()),
  ]);

  const userDiscounts = [];
  const deliveryPrices = [];
  for (let index = 0; index < userList.length; index++) {
    const user = userList[index];
    const [paymentDiscount, parsedDiscount, userDeliveryPrices] = await Promise.all([
      optionalCall(`payment.getBaseDiscount(${user})`, () => payment['getBaseDiscount(address)'](user)),
      optionalCall(`discount.getParsedDiscount(${user})`, () => discount.getParsedDiscount(user)),
      optionalCall(`delivery.getUserDeliveryPrices(${user})`, () => delivery.getUserDeliveryPrices(user)),
    ]);

    userDiscounts.push({ user, paymentDiscount, parsedDiscount });
    deliveryPrices.push({ user, deliveryPrices: userDeliveryPrices });
    process.stdout.write(`Exported pricing user ${index + 1}/${userList.length}\r`);
  }
  process.stdout.write('\n');

  const tripTaxes = [];
  for (let index = 0; index < tripIds.length; index++) {
    const tripId = tripIds[index];
    const [totalTripTaxFromPayment, tripTaxesFromPayment, totalTripTax, tripTaxesDTO] = await Promise.all([
      optionalCall(`payment.getTotalTripTax(${tripId})`, () => payment.getTotalTripTax(tripId)),
      optionalCall(`payment.getTripTaxesDTO(${tripId})`, () => payment.getTripTaxesDTO(tripId)),
      optionalCall(`taxes.getTotalTripTax(${tripId})`, () => taxes.getTotalTripTax(tripId)),
      optionalCall(`taxes.getTripTaxesDTO(${tripId})`, () => taxes.getTripTaxesDTO(tripId)),
    ]);

    tripTaxes.push({
      tripId,
      totalTripTaxFromPayment,
      tripTaxesFromPayment,
      totalTripTax,
      tripTaxesDTO,
    });
    process.stdout.write(`Exported trip taxes ${index + 1}/${tripIds.length}\r`);
  }
  process.stdout.write('\n');

  const treasuryBalances = {
    native: await optionalCall(`provider.getBalance(${paymentAddress})`, () => provider.getBalance(paymentAddress)),
    tokens: {},
  };
  for (const [name, tokenAddress] of Object.entries(tokenAddresses)) {
    if (!tokenAddress) {
      treasuryBalances.tokens[name] = null;
      continue;
    }

    const token = new ethers.Contract(tokenAddress, ERC20_ABI, provider);
    treasuryBalances.tokens[name] = {
      address: tokenAddress,
      balance: await optionalCall(`${name}.balanceOf(${paymentAddress})`, () => token.balanceOf(paymentAddress)),
    };
  }

  const snapshot = {
    network: 'base_sepolia',
    chainId: CHAIN_ID,
    legacyRef: LEGACY_REF,
    exportedAt: new Date().toISOString(),
    contracts: {
      RentalityPaymentService: paymentAddress,
      RentalityCarDelivery: deliveryAddress,
      RentalityBaseDiscount: baseDiscountAddress,
      RentalityTaxes: taxesAddress,
      tokens: tokenAddresses,
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
      profiles: profilesSnapshot.totals,
    },
    totals: {
      knownUsers: userList.length,
      tripTaxes: tripTaxes.length,
    },
    platformFeeInPPM,
    paymentBaseDiscountAddress,
    baseDefaultDiscount,
    userDiscounts,
    deliveryPrices,
    tripTaxes,
    treasuryBalances,
  };

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(normalizeValue(snapshot), null, 2));

  console.log(`Legacy pricing/payments exported: ${userList.length} users, ${tripTaxes.length} trips`);
  console.log(`Snapshot written to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
