const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  console.log("Deployer address is:", deployer.getAddress()," with balance:", balance);

  const chainId = (await deployer.provider?.getNetwork()).chainId
  console.log("ChainId is:", chainId);

  const RentCar = await hre.ethers.getContractFactory("RentCar");

  const ethToUsdPriceFeedAddress = chainId === 5 
    ?  "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"
    : chainId === 80001 
      ? "0x0715A7794a1dc8e42615F059dD6e406A6594651A"
      : chainId === 1337
        ? "0x5FbDB2315678afecb367f032d93F642f64180aa3"
        : "";

  console.log("EthToUsdPriceFeedAddress is:", ethToUsdPriceFeedAddress);

  const rentCar = await RentCar.deploy(ethToUsdPriceFeedAddress);

  await rentCar.deployed();
  console.log("RentCar deployed to:", rentCar.address);

    const data = {
      address: rentCar.address,
      abi: JSON.parse(rentCar.interface.format('json'))
    }
  
  if (chainId !== 1337)
  {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync('./src/RentCar.json', JSON.stringify(data))
    console.log("JSON abi saved to ./src/RentCar.json");
    
    const backupFilePath = './src/RentCar.'+ chainId + '.json'
    fs.writeFileSync(backupFilePath, JSON.stringify(data))
    console.log("JSON abi saved to " + backupFilePath);
  } else {
    fs.writeFileSync('./src/RentCar.Localhost.json', JSON.stringify(data))
    console.log("JSON abi saved to ./src/RentCar.Localhost.json");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
