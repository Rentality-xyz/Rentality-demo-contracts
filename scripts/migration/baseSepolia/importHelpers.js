const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');
const { readFromFile } = require('../../utils/contractAddress');

const BASE_SEPOLIA_CHAIN_ID = 84532;
const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const NEWMODEL_ABIS_DIR = path.join(process.cwd(), 'src', 'abis', 'base-sepolia-newmodel');

const MIGRATION_MODELS = {
  TripMain: {
    proxyName: 'TripMain',
    migrationImplementationName: 'TripMainMigration',
    productionImplementationName: 'TripMain',
  },
  UserProfileMain: {
    proxyName: 'UserProfileMain',
    migrationImplementationName: 'UserProfileMainMigration',
    productionImplementationName: 'UserProfileMain',
  },
  InvestmentMain: {
    proxyName: 'InvestmentMain',
    migrationImplementationName: 'InvestmentMainMigration',
    productionImplementationName: 'InvestmentMain',
  },
};

function readSnapshot(fileName) {
  const filePath = path.join(DATA_DIR, fileName);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function snapshotPath(fileName) {
  return path.join(DATA_DIR, fileName);
}

async function getCurrentChainId() {
  const [deployer] = await ethers.getSigners();
  const network = await deployer.provider.getNetwork();
  return Number(network.chainId);
}

async function requireBaseSepolia() {
  const chainId = await getCurrentChainId();
  if (chainId !== BASE_SEPOLIA_CHAIN_ID && process.env.ALLOW_NON_BASE_SEPOLIA_MIGRATION !== '1') {
    throw new Error(
      `Migration scripts are guarded for Base Sepolia (${BASE_SEPOLIA_CHAIN_ID}); current chainId is ${chainId}.`
    );
  }
  return chainId;
}

function requireConfirmedWrite() {
  if (process.env.CONFIRM_BASE_SEPOLIA_MIGRATION !== '1') {
    throw new Error('Refusing to write. Set CONFIRM_BASE_SEPOLIA_MIGRATION=1 when you intentionally run migration txs.');
  }
}

function resolveModel(modelName) {
  const config = MIGRATION_MODELS[modelName];
  if (!config) {
    throw new Error(`Unsupported migration model "${modelName}". Use one of: ${Object.keys(MIGRATION_MODELS).join(', ')}`);
  }
  return config;
}

function readCurrentAddress(contractName, chainId) {
  const newmodelAddress = readNewmodelAddress(contractName, chainId);
  const address = newmodelAddress || readFromFile(contractName, chainId);
  if (!address) {
    throw new Error(`No ${contractName} address found for chainId ${chainId}`);
  }
  return address;
}

function readNewmodelAddress(contractName, chainId) {
  const filePath = path.join(NEWMODEL_ABIS_DIR, `${contractName}.v0_2_0.addresses.json`);
  if (!fs.existsSync(filePath)) {
    return null;
  }

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const record = (data.addresses || []).find((item) => Number(item.chainId) === Number(chainId));
  return record?.address || null;
}

function getBatchSize(defaultSize = 25) {
  const raw = process.env.MIGRATION_BATCH_SIZE;
  if (!raw) {
    return defaultSize;
  }

  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`Invalid MIGRATION_BATCH_SIZE "${raw}"`);
  }

  return parsed;
}

function chunk(items, size) {
  const batches = [];
  for (let index = 0; index < items.length; index += size) {
    batches.push(items.slice(index, index + size));
  }
  return batches;
}

async function getTargetContract(contractName, chainId, artifactName = contractName) {
  const address = readCurrentAddress(contractName, chainId);
  const contract = await ethers.getContractAt(artifactName, address);
  return { address, contract };
}

async function sendAndWait(label, txPromise) {
  const tx = await txPromise;
  console.log(`${label} -> ${tx.hash ?? tx}`);
  const receipt = await tx.wait();
  return receipt;
}

module.exports = {
  BASE_SEPOLIA_CHAIN_ID,
  DATA_DIR,
  MIGRATION_MODELS,
  readSnapshot,
  snapshotPath,
  getCurrentChainId,
  requireBaseSepolia,
  requireConfirmedWrite,
  resolveModel,
  readCurrentAddress,
  getBatchSize,
  chunk,
  getTargetContract,
  sendAndWait,
};
