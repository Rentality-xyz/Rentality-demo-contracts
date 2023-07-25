const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");
const addressesContractsTestnets = require("./addressesContractsTestnets.json");

async function main() {
  let contractName = "";
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

  if (chainId === 1337) {
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
  console.log("ethToUsdPriceFeedAddress is:", ethToUsdPriceFeedAddress);

  contractName = "RentalityUserService";
  let contractFactory = await ethers.getContractFactory(contractName);
  let contract = await contractFactory.deploy();
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);

  let rentalityUserServiceAddress = contract.address;
  const rentalityUserServiceContract = contract;

  contractName = "RentalityTripService";
  contractFactory = await ethers.getContractFactory(contractName);
  contract = await contractFactory.deploy();
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);

  let rentalityTripServiceAddress = contract.address;

  contractName = "RentalityCurrencyConverter";
  contractFactory = await ethers.getContractFactory(contractName);
  contract = await contractFactory.deploy(ethToUsdPriceFeedAddress);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);

  let rentalityCurrencyConverterAddress = contract.address;

  contractName = "RentalityCarToken";
  contractFactory = await ethers.getContractFactory(contractName);
  contract = await contractFactory.deploy(rentalityUserServiceAddress);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);

  let rentalityCarTokenAddress = contract.address;

  contractName = "Rentality";
  contractFactory = await ethers.getContractFactory(contractName);
  contract = await contractFactory.deploy(
    rentalityCarTokenAddress,
    rentalityCurrencyConverterAddress,
    rentalityTripServiceAddress,
    rentalityUserServiceAddress);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  try{
    await rentalityUserServiceContract.grantManagerRole(contract.address);
    console.log("manager role granded");
  } catch(e){
    console.log("grand manager role error:", e);
  }
  //await rentalityUserServiceContract.connect(deployer).grantManagerRole(contract.address);
  
  saveJsonAbi(contractName, chainId, contract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
