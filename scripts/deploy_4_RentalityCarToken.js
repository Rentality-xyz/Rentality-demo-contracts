const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");

async function main() {
  const contractName = "RentalityCarToken";
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

  const userServiceAddress = "";
  if (!userServiceAddress) {
    console.log("userServiceAddress is not set");
    return;
  }
  console.log("userServiceAddress is:", userServiceAddress);

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(userServiceAddress);
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
