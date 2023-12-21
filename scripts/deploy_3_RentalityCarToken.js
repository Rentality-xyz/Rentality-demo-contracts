const saveJsonAbi = require("./utils/abiSaver");
const { ethers,upgrades } = require("hardhat");
const addressesContractsTestnets = require("./addressesContractsTestnets.json");

async function main() {
  const contractName = "RentalityCarToken";
  const [deployer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(
    "Deployer address is:",
   await deployer.getAddress(),
    " with balance:",
    balance
  );

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1;
  console.log("ChainId is:", chainId);
  if (chainId < 0) return;

  const addresses = addressesContractsTestnets.find((i) => i.chainId === chainId);
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`);
    return;
  }

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy();
  await contract.waitForDeployment()
  console.log(contractName + " deployed to:", await contract.getAddress());

  saveJsonAbi(contractName, chainId, contract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
