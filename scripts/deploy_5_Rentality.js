const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");

async function main() {
  const contractName = "Rentality";
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

  const carServiceAddress = "";
  const currencyConverterServiceAddress = "";
  const tripServiceAddress = "";
  const userServiceAddress = "";

  if (!carServiceAddress) {
    console.log("carServiceAddress is not set");
    return;
  }
  if (!currencyConverterServiceAddress) {
    console.log("currencyConverterServiceAddress is not set");
    return;
  }
  if (!tripServiceAddress) {
    console.log("tripServiceAddress is not set");
    return;
  }
  if (!userServiceAddress) {
    console.log("userServiceAddress is not set");
    return;
  }

  console.log("carServiceAddress is:", carServiceAddress);
  console.log(
    "currencyConverterServiceAddress is:",
    currencyConverterServiceAddress
  );
  console.log("tripServiceAddress is:", tripServiceAddress);
  console.log("userServiceAddress is:", userServiceAddress);

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(
    carServiceAddress,
    currencyConverterServiceAddress,
    tripServiceAddress,
    userServiceAddress
  );
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
