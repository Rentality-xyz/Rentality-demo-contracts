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

  const RentalityTripService = await hre.ethers.getContractFactory("RentalityTripService");
  const rentalityTripService = await RentalityTripService.deploy();
  await rentalityTripService.deployed();
  console.log("RentalityTripService deployed to:", rentalityTripService.address);

  const data = {
    address: rentalityTripService.address,
    abi: JSON.parse(rentalityTripService.interface.format("json")),
  };

  if (chainId !== 1337) {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync("./src/RentalityTripService.json", JSON.stringify(data));
    console.log("JSON abi saved to ./src/RentalityTripService.json");

    const backupFilePath = "./src/RentalityTripService." + chainId + ".json";
    fs.writeFileSync(backupFilePath, JSON.stringify(data));
    console.log("JSON abi saved to " + backupFilePath);
  } else {
    fs.writeFileSync(
      "./src/RentalityTripService.Localhost.json",
      JSON.stringify(data)
    );
    console.log("JSON abi saved to ./src/RentalityTripService.Localhost.json");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
