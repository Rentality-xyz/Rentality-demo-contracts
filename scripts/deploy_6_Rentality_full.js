const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  console.log(
    "Deployer address is:",
    deployer.getAddress(),
    " with balance:",
    balance
  );

  const chainId = (await deployer.provider?.getNetwork()).chainId;
  console.log("ChainId is:", chainId);

  const ethToUsdPriceFeedAddress =
    chainId === 5
      ? "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"
      : chainId === 80001
      ? "0x0715A7794a1dc8e42615F059dD6e406A6594651A"
      : chainId === 1337
      ? "0x5FbDB2315678afecb367f032d93F642f64180aa3"
      : "";
  
  const RentalityUserService = await hre.ethers.getContractFactory("RentalityUserService");  
  const rentalityUserService = await RentalityUserService.deploy();
  await rentalityUserService.deployed();
  console.log( "RentalityUserService deployed to:", rentalityUserService.address);

  const RentalityTripService = await hre.ethers.getContractFactory("RentalityTripService");
  const rentalityTripService = await RentalityTripService.deploy();
  await rentalityTripService.deployed();
  console.log("RentalityTripService deployed to:", rentalityTripService.address);

  const RentalityCurrencyConverter = await hre.ethers.getContractFactory("RentalityCurrencyConverter");
  const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(ethToUsdPriceFeedAddress);
  await rentalityCurrencyConverter.deployed();
  console.log("RentalityCurrencyConverter deployed to:", rentalityCurrencyConverter.address);

  const RentalityCarToken = await hre.ethers.getContractFactory("RentalityCarToken");  
  const rentalityCarToken = await RentalityCarToken.deploy(rentalityUserService.address);
  await rentalityCarToken.deployed();
  console.log("RentalityCarToken deployed to:", rentalityCarToken.address);

  const Rentality = await hre.ethers.getContractFactory("Rentality");
  const rentality = await Rentality.deploy(
    rentalityCarToken.address,
    rentalityCurrencyConverter.address,
    rentalityTripService.address,
    rentalityUserService.address
  );
  await rentality.deployed();
  console.log("Rentality deployed to:", rentality.address);
  
  saveJsonAbi("RentalityUserServiceData", chainId, rentalityUserService);
  saveJsonAbi("RentalityTripServiceData", chainId, rentalityTripService);
  saveJsonAbi("RentalityCurrencyConverterData", chainId, rentalityCurrencyConverter);
  saveJsonAbi("RentalityCarTokenData", chainId, rentalityCarToken);
  saveJsonAbi("RentalityData", chainId, rentality);
}

function saveJsonAbi(fileName, chainId, contract){  
  const jsonData = {
    address: contract.address,
    abi: JSON.parse(contract.interface.format("json")),
  };
  
  const chainIdString = chainId !== 1337 ? chainId.toString() : "localhost";
  let filePath;
  
  if (chainId !== 1337) {
    filePath = "./src/" + fileName + ".json";
    fs.writeFileSync(filePath, JSON.stringify(jsonData));
    console.log("JSON abi saved to " + filePath);
  }

  filePath = "./src/" + fileName + "." + chainIdString + ".json";
  fs.writeFileSync(filePath, JSON.stringify(jsonData));
  console.log("JSON abi saved to " + filePath);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
