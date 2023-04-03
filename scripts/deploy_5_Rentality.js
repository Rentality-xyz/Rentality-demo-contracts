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

  const carServiceAddress = "";
  const currencyConverterServiceAddress = "";
  const tripServiceAddress = "";
  const userServiceAddress = "";

  if (!carServiceAddress) { console.log("carServiceAddress is not set"); return; }
  if (!currencyConverterServiceAddress) { console.log("currencyConverterServiceAddress is not set"); return; }
  if (!tripServiceAddress) { console.log("tripServiceAddress is not set"); return; }
  if (!userServiceAddress) { console.log("userServiceAddress is not set"); return; }

  console.log("carServiceAddress is:", carServiceAddress);
  console.log("currencyConverterServiceAddress is:", currencyConverterServiceAddress);
  console.log("tripServiceAddress is:", tripServiceAddress);
  console.log("userServiceAddress is:", userServiceAddress);

  const Rentality = await hre.ethers.getContractFactory("Rentality");
  const rentality = await Rentality.deploy(
    carServiceAddress,
    currencyConverterServiceAddress,
    tripServiceAddress,
    userServiceAddress
  );
  await rentality.deployed();
  console.log("Rentality deployed to:", rentality.address);

  const data = {
    address: rentality.address,
    abi: JSON.parse(rentality.interface.format("json")),
  };

  if (chainId !== 1337) {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync("./src/Rentality.json", JSON.stringify(data));
    console.log("JSON abi saved to ./src/Rentality.json");

    const backupFilePath = "./src/Rentality." + chainId + ".json";
    fs.writeFileSync(backupFilePath, JSON.stringify(data));
    console.log("JSON abi saved to " + backupFilePath);
  } else {
    fs.writeFileSync("./src/Rentality.Localhost.json", JSON.stringify(data));
    console.log("JSON abi saved to ./src/Rentality.Localhost.json");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
