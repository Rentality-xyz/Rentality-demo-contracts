const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");
const addressesContractsTestnets = require("./addressesContractsTestnets.json");

async function main() {
  var contractName = "RentalityCurrencyConverter";
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

  let ethToUsdPriceFeedAddress =
    addressesContractsTestnets.find((i) => i.chainId === chainId)
      ?.EthToUsdPriceFeedAddress ?? "";

  if (chainId === 1337 && ethToUsdPriceFeedAddress.length === 0) {
    contractName = "RentalityMockPriceFeed";
    let contractFactory = await ethers.getContractFactory(contractName);
    let contract = await contractFactory.deploy(8, 200000000000);
    await contract.deployed();
    console.log(contractName + " deployed to:", contract.address);
    ethToUsdPriceFeedAddress = contract.address;
  }

  if (!ethToUsdPriceFeedAddress) {
    console.log("ethToUsdPriceFeedAddress is not set");
    return;
  }
  console.log("EthToUsdPriceFeedAddress is:", ethToUsdPriceFeedAddress);

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(ethToUsdPriceFeedAddress);
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
