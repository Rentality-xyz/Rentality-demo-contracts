const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');

const BASE_SEPOLIA_CHAIN_ID = 84532;
const DIAMOND_STORAGE_POSITION = ethers.keccak256(ethers.toUtf8Bytes('diamond.standard.diamond.storage'));
const FEATURE_NAME = process.env.FEATURE_NAME || 'base-sepolia-newmodel';
const ABI_DIR = path.join(process.cwd(), 'src', 'abis', FEATURE_NAME);
const CONTRACT_NAME = process.env.APP_GATEWAY_CONTRACT_NAME || 'AppGateway';
const STRICT = process.env.STRICT_APP_GATEWAY_SELECTOR_CHECK === '1';
const SMOKE_FROM = process.env.APP_GATEWAY_SMOKE_FROM || '';

const SMOKE_CALLS = [
  { name: 'getFilterInfo', args: [1n] },
  { name: 'getMyInsurancesAsGuest', args: [] },
  { name: 'getCarDetails', args: [1n] },
  { name: 'getDiscount', args: [ethers.ZeroAddress] },
];

const INDEXER_ZERO_FROM_SMOKE_CALLS = [{ name: 'getDiscount', args: [ethers.ZeroAddress] }];

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function readGatewayConfig(chainId) {
  const abiPath = path.join(ABI_DIR, `${CONTRACT_NAME}.v0_2_0.abi.json`);
  const addressesPath = path.join(ABI_DIR, `${CONTRACT_NAME}.v0_2_0.addresses.json`);
  const abiJson = readJson(abiPath);
  const addressesJson = readJson(addressesPath);
  const address = addressesJson.addresses.find((item) => Number(item.chainId) === chainId)?.address;

  if (!address) {
    throw new Error(`No ${CONTRACT_NAME} address for chainId ${chainId} in ${addressesPath}`);
  }

  return {
    abi: abiJson.abi || abiJson,
    address,
    abiPath,
    addressesPath,
  };
}

function selectorStorageSlot(selector) {
  const coder = ethers.AbiCoder.defaultAbiCoder();
  return ethers.keccak256(coder.encode(['bytes4', 'uint256'], [selector, BigInt(DIAMOND_STORAGE_POSITION)]));
}

async function readFacetAddress(provider, gatewayAddress, selector) {
  const raw = await provider.getStorage(gatewayAddress, selectorStorageSlot(selector));
  const facet = `0x${raw.slice(-40)}`;
  return facet.toLowerCase() === ethers.ZeroAddress.toLowerCase() ? ethers.ZeroAddress : ethers.getAddress(facet);
}

function formatError(error) {
  return error?.shortMessage || error?.reason || error?.message || String(error);
}

async function main() {
  const [signer] = await ethers.getSigners();
  const network = await signer.provider.getNetwork();
  const chainId = Number(network.chainId);

  if (chainId !== BASE_SEPOLIA_CHAIN_ID && process.env.ALLOW_NON_BASE_SEPOLIA_DIAGNOSTICS !== '1') {
    throw new Error(`This diagnostic defaults to Base Sepolia (${BASE_SEPOLIA_CHAIN_ID}); current chainId is ${chainId}.`);
  }

  const { abi, address, abiPath, addressesPath } = readGatewayConfig(chainId);
  const iface = new ethers.Interface(abi);
  const contract = new ethers.Contract(address, abi, signer);
  const functions = iface.fragments.filter((fragment) => fragment.type === 'function');
  const missing = [];
  const routed = [];

  for (const fragment of functions) {
    const selector = fragment.selector;
    const signature = fragment.format('sighash');
    const facet = await readFacetAddress(signer.provider, address, selector);
    const row = { selector, signature, facet };

    if (facet === ethers.ZeroAddress) {
      missing.push(row);
    } else {
      routed.push(row);
    }
  }

  console.log(`AppGateway selector coverage`);
  console.log(`  feature: ${FEATURE_NAME}`);
  console.log(`  abi: ${abiPath}`);
  console.log(`  addresses: ${addressesPath}`);
  console.log(`  gateway: ${address}`);
  if (SMOKE_FROM) {
    console.log(`  smoke from: ${SMOKE_FROM}`);
  }
  console.log(`  ABI functions: ${functions.length}`);
  console.log(`  routed selectors: ${routed.length}`);
  console.log(`  missing selectors: ${missing.length}`);

  for (const row of missing) {
    console.log(`  MISSING ${row.selector} ${row.signature}`);
  }

  const runtimeFailures = [];
  console.log(`Runtime smoke calls`);

  for (const smoke of SMOKE_CALLS) {
    const fragments = functions.filter((fragment) => fragment.name === smoke.name);
    if (fragments.length === 0) {
      console.log(`  SKIP ${smoke.name}: not in ABI`);
      continue;
    }

    for (const fragment of fragments) {
      const signature = fragment.format('sighash');
      const facet = await readFacetAddress(signer.provider, address, fragment.selector);

      if (facet === ethers.ZeroAddress) {
        const message = `${signature} is not routed`;
        runtimeFailures.push(message);
        console.log(`  MISSING ${fragment.selector} ${message}`);
        continue;
      }

      try {
        if (SMOKE_FROM) {
          const data = iface.encodeFunctionData(fragment, smoke.args);
          const result = await signer.provider.call({
            to: address,
            from: SMOKE_FROM,
            data,
          });
          iface.decodeFunctionResult(fragment, result);
        } else {
          const fn = contract.getFunction(signature);
          await fn.staticCall(...smoke.args);
        }
        console.log(`  OK ${fragment.selector} ${signature} -> ${facet}`);
      } catch (error) {
        const message = `${signature} routed to ${facet} but reverted: ${formatError(error)}`;
        runtimeFailures.push(message);
        console.log(`  REVERT ${fragment.selector} ${message}`);
      }
    }
  }

  console.log(`Indexer zero-from smoke calls`);
  for (const smoke of INDEXER_ZERO_FROM_SMOKE_CALLS) {
    const fragments = functions.filter((fragment) => fragment.name === smoke.name);
    if (fragments.length === 0) {
      console.log(`  SKIP ${smoke.name}: not in ABI`);
      continue;
    }

    for (const fragment of fragments) {
      const signature = fragment.format('sighash');
      const facet = await readFacetAddress(signer.provider, address, fragment.selector);

      if (facet === ethers.ZeroAddress) {
        const message = `${signature} is not routed`;
        runtimeFailures.push(message);
        console.log(`  MISSING ${fragment.selector} ${message}`);
        continue;
      }

      try {
        const data = iface.encodeFunctionData(fragment, smoke.args);
        const result = await signer.provider.call({
          to: address,
          from: ethers.ZeroAddress,
          data,
        });
        iface.decodeFunctionResult(fragment, result);
        console.log(`  OK ${fragment.selector} ${signature} from zero -> ${facet}`);
      } catch (error) {
        const message = `${signature} routed to ${facet} but reverted from zero: ${formatError(error)}`;
        runtimeFailures.push(message);
        console.log(`  REVERT ${fragment.selector} ${message}`);
      }
    }
  }

  if (STRICT && (missing.length > 0 || runtimeFailures.length > 0)) {
    throw new Error(
      `AppGateway selector check failed: missing=${missing.length}, runtimeFailures=${runtimeFailures.length}`
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
