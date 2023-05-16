const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");

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

  let rentalityMockPriceFeedAddress = "";

  if( chainId === 1337){
    contractName = "RentalityMockPriceFeed";
    let contractFactory = await ethers.getContractFactory(contractName);
    let contract = await contractFactory.deploy(8, 165000000000);
    await contract.deployed();
    console.log(contractName + " deployed to:", contract.address);
    rentalityMockPriceFeedAddress = contract.address;
  }

  const ethToUsdPriceFeedAddress =
    chainId === 5
      ? "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"
      : chainId === 80001
      ? "0x0715A7794a1dc8e42615F059dD6e406A6594651A"
      : chainId === 1337
      ? rentalityMockPriceFeedAddress
      : "";

  contractName = "RentalityUserService";
  let contractFactory = await ethers.getContractFactory(contractName);
  let contract = await contractFactory.deploy();
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);

  let rentalityUserServiceAddress = contract.address;

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

  saveJsonAbi(contractName, chainId, contract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
