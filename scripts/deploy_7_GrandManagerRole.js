const RentalityUserServiceJSONNet = require("../src/abis/RentalityUserService.json");
const RentalityUserServiceJSONLocal = require("../src/abis/RentalityUserService.localhost.json");
const { ethers } = require("hardhat");
const addressesGanache = require("./ganacheAddresses.json")
const addressesSepolia = require("./sepoliaAddresses.json")

async function main() {
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

  const rentalityUserServiceAddress = addresses.RentalityUserService;
  const rentalityAddress = addresses.Rentality;

  if (!rentalityUserServiceAddress) {
    console.log("rentalityUserServiceAddress is not set");
    return;
  }
  if (!rentalityAddress) {
    console.log("rentalityAddress is not set");
    return;
  }

  console.log("rentalityUserServiceAddress is:", rentalityUserServiceAddress);
  console.log("rentalityAddress is:", rentalityAddress);
  
  let rentalityUserServiceContract = new ethers.Contract(
    rentalityUserServiceAddress,
    RentalityUserServiceJSON.abi,
    deployer
  );
  try{
    await rentalityUserServiceContract.grantManagerRole(rentalityAddress);
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
