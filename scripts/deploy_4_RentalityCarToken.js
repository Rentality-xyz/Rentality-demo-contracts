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

  const userServiceAddress = "";
  if (!userServiceAddress) { console.log("userServiceAddress is not set"); return; }
  console.log("userServiceAddress is:", userServiceAddress);

  const RentalityCarToken = await hre.ethers.getContractFactory("RentalityCarToken");
  const rentalityCarToken = await RentalityCarToken.deploy(userServiceAddress);
  await rentalityCarToken.deployed();
  console.log("RentalityCarToken deployed to:", rentalityCarToken.address);

  const data = {
    address: rentalityCarToken.address,
    abi: JSON.parse(rentalityCarToken.interface.format("json")),
  };

  if (chainId !== 1337) {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync("./src/RentalityCarToken.json", JSON.stringify(data));
    console.log("JSON abi saved to ./src/RentalityCarToken.json");

    const backupFilePath = "./src/RentalityCarToken." + chainId + ".json";
    fs.writeFileSync(backupFilePath, JSON.stringify(data));
    console.log("JSON abi saved to " + backupFilePath);
  } else {
    fs.writeFileSync(
      "./src/RentalityCarToken.Localhost.json",
      JSON.stringify(data)
    );
    console.log("JSON abi saved to ./src/RentalityCarToken.Localhost.json");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
