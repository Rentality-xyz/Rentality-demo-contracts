const { ethers, upgrades } = require('hardhat');
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

  console.log(`Upgrading ${model.proxyName} proxy ${proxyAddress} to ${model.migrationImplementationName}`);
  const factory = await ethers.getContractFactory(model.migrationImplementationName);
  const contract = await upgrades.upgradeProxy(proxyAddress, factory, {
    unsafeAllow: ['structs', 'missing-initializer'],
    redeployImplementation: 'always',
  });
  await contract.waitForDeployment();

  console.log(`${model.proxyName} is now using ${model.migrationImplementationName}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
