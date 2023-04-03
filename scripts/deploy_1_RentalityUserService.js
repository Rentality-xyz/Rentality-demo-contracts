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

  const RentalityUserService = await hre.ethers.getContractFactory("RentalityUserService");
  const rentalityUserService = await RentalityUserService.deploy();
  await rentalityUserService.deployed();
  console.log( "RentalityUserService deployed to:", rentalityUserService.address );

  const data = {
    address: rentalityUserService.address,
    abi: JSON.parse(rentalityUserService.interface.format("json")),
  };

  if (chainId !== 1337) {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync("./src/RentalityUserService.json", JSON.stringify(data));
    console.log("JSON abi saved to ./src/RentalityUserService.json");

    const backupFilePath = "./src/RentalityUserService." + chainId + ".json";
    fs.writeFileSync(backupFilePath, JSON.stringify(data));
    console.log("JSON abi saved to " + backupFilePath);
  } else {
    fs.writeFileSync(
      "./src/RentalityUserService.Localhost.json",
      JSON.stringify(data)
    );
    console.log("JSON abi saved to ./src/RentalityUserService.Localhost.json");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
