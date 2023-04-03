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

  const RentalityCurrencyConverter = await hre.ethers.getContractFactory(
    "RentalityCurrencyConverter"
  );

  const ethToUsdPriceFeedAddress =
    chainId === 5
      ? "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"
      : chainId === 80001
      ? "0x0715A7794a1dc8e42615F059dD6e406A6594651A"
      : chainId === 1337
      ? "0x5FbDB2315678afecb367f032d93F642f64180aa3"
      : "";

  console.log("EthToUsdPriceFeedAddress is:", ethToUsdPriceFeedAddress);

  const rentalityCurrencyConverter = await RentalityCurrencyConverter.deploy(ethToUsdPriceFeedAddress);
  await rentalityCurrencyConverter.deployed();
  console.log("RentalityCurrencyConverter deployed to:", rentalityCurrencyConverter.address);

  const data = {
    address: rentalityCurrencyConverter.address,
    abi: JSON.parse(rentalityCurrencyConverter.interface.format("json")),
  };

  if (chainId !== 1337) {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync(
      "./src/RentalityCurrencyConverter.json",
      JSON.stringify(data)
    );
    console.log("JSON abi saved to ./src/RentalityCurrencyConverter.json");

    const backupFilePath =
      "./src/RentalityCurrencyConverter." + chainId + ".json";
    fs.writeFileSync(backupFilePath, JSON.stringify(data));
    console.log("JSON abi saved to " + backupFilePath);
  } else {
    fs.writeFileSync(
      "./src/RentalityCurrencyConverter.Localhost.json",
      JSON.stringify(data)
    );
    console.log(
      "JSON abi saved to ./src/RentalityCurrencyConverter.Localhost.json"
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
