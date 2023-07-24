const saveJsonAbi = require("./utils/abiSaver");
const RentalityUserServiceJSONNet = require("../src/abis/RentalityUserService.json");
const RentalityUserServiceJSONLocal = require("../src/abis/RentalityUserService.localhost.json");
const { ethers } = require("hardhat");
const addressesGanache = require("./ganacheAddresses.json")
const addressesSepolia = require("./sepoliaAddresses.json")

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
  
  const addresses = chainId === 11155111 ? addressesSepolia : addressesGanache;
  const RentalityUserServiceJSON = chainId === 1337 ? RentalityUserServiceJSONLocal : RentalityUserServiceJSONNet;

  const rentalityCarTokenAddress =  addresses.RentalityCarToken;
  const rentalityCurrencyConverterAddress = addresses.RentalityCurrencyConverter;
  const rentalityTripServiceAddress = addresses.RentalityTripService;
  const rentalityUserServiceAddress = addresses.RentalityUserService;

  if (!rentalityCarTokenAddress) {
    console.log("rentalityCarTokenAddress is not set");
    return;
  }
  if (!rentalityCurrencyConverterAddress) {
    console.log("rentalityCurrencyConverterAddress is not set");
    return;
  }
  if (!rentalityTripServiceAddress) {
    console.log("rentalityTripServiceAddress is not set");
    return;
  }
  if (!rentalityUserServiceAddress) {
    console.log("rentalityUserServiceAddress is not set");
    return;
  }

  console.log("rentalityCarTokenAddress is:", rentalityCarTokenAddress);
  console.log(
    "rentalityCurrencyConverterAddress is:",
    rentalityCurrencyConverterAddress
  );
  console.log("rentalityTripServiceAddress is:", rentalityTripServiceAddress);
  console.log("rentalityUserServiceAddress is:", rentalityUserServiceAddress);
  
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(
    rentalityCarTokenAddress,
    rentalityCurrencyConverterAddress,
    rentalityTripServiceAddress,
    rentalityUserServiceAddress);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  let rentalityUserServiceContract = new ethers.Contract(
    RentalityUserServiceJSON.address,
    RentalityUserServiceJSON.abi,
    deployer
  );
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
