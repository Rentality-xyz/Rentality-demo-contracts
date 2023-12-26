const RentalityUserServiceJSONNet = require("../src/abis/RentalityUserService.json");
const RentalityUserServiceJSONLocal = require("../src/abis/RentalityUserService.1337.json");
const { ethers, network } = require("hardhat");
const addressesContractsTestnets = require("./addressesContractsTestnets.json");
const net = require('net')

async function main() {
  const [deployer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(deployer)
  console.log(
    "Deployer address is:",
    deployer.getAddress(),
    " with balance:",
    balance
  );

  const chainId = network.config.chainId

  const addresses = addressesContractsTestnets.find((i) => i.chainId === chainId && i.name === network.name);
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`);
    return;
  }
  
  const RentalityUserServiceJSON = chainId === 1337 ? RentalityUserServiceJSONLocal : RentalityUserServiceJSONNet;

  const rentalityUserServiceAddress = addresses['RentalityUserService'];
  const rentalityGatewayAddress = addresses['RentalityGateway'];
  const rentalityTripServiceAddress = addresses['RentalityTripService'];
  const rentalityPlatformAddress = addresses['RentalityPlatform'];

  if (!rentalityUserServiceAddress) {
    console.log("rentalityUserServiceAddress is not set");
    return;
  }
  if (!rentalityGatewayAddress) {
    console.log("rentalityAddress is not set");
    return;
  }
  if (!rentalityTripServiceAddress) {
    console.log("rentalityTripServiceAddress is not set");
    return;
  }
  if (!rentalityPlatformAddress) {
    console.log("rentalityAddress is not set");
    return;
  }

  console.log("rentalityUserServiceAddress is:", rentalityUserServiceAddress);
  console.log("rentalityGatewayAddress is:", rentalityGatewayAddress);
  console.log("rentalityTripServiceAddress is:", rentalityTripServiceAddress);
  console.log("rentalityPlatformAddress is:", rentalityPlatformAddress);
  
  let rentalityUserServiceContract = new ethers.Contract(
    rentalityUserServiceAddress,
    RentalityUserServiceJSON.abi,
    deployer
  );
  try{
    await rentalityUserServiceContract.grantManagerRole(rentalityGatewayAddress);
    await rentalityUserServiceContract.grantManagerRole(rentalityTripServiceAddress);
    await rentalityUserServiceContract.grantManagerRole(rentalityPlatformAddress);
    console.log("manager role granded");
  } catch(e){
    console.log("grand manager role error:", e);
  }
  //await rentalityUserServiceContract.connect(deployer).grantManagerRole(contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
