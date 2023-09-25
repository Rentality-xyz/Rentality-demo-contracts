const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");
const addressesContractsTestnets = require("./addressesContractsTestnets.json");

async function main() {
  const contractName = "RentalityPaymentService";
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  console.log(
    "Deployer address is:",
    deployer.getAddress(),
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
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
