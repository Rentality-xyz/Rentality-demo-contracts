const { ethers, upgrades } = require('hardhat');
const saveJsonAbi = require('../../utils/abiSaver');
const {
  requireBaseSepolia,
  requireConfirmedWrite,
  resolveModel,
  readCurrentAddress,
} = require('./importHelpers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const modelName = process.env.MODEL;
  const model = resolveModel(modelName);
  const proxyAddress = readCurrentAddress(model.proxyName, chainId);

  console.log(`Upgrading ${model.proxyName} proxy ${proxyAddress} back to ${model.productionImplementationName}`);
  const factory = await ethers.getContractFactory(model.productionImplementationName);
  const contract = await upgrades.upgradeProxy(proxyAddress, factory, {
    unsafeAllow: ['structs'],
    redeployImplementation: 'always',
  });
  await contract.waitForDeployment();
  await saveJsonAbi(model.proxyName, chainId, contract);

  console.log(`${model.proxyName} is back on ${model.productionImplementationName}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
