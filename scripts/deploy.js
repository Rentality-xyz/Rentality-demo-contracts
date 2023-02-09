const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  console.log("Deployer address is:", deployer.getAddress()," with balance:", balance);
  const RentCar = await hre.ethers.getContractFactory("RentCar");
  const rentCar = await RentCar.deploy();

  await rentCar.deployed();
  console.log("RentCar deployed to:", rentCar.address);

  const chainId = (await deployer.provider?.getNetwork()).chainId;
  if (chainId !== 1337)
  {
    const data = {
      address: rentCar.address,
      abi: JSON.parse(rentCar.interface.format('json'))
    }
  
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync('./src/RentCar.json', JSON.stringify(data))
    console.log("JSON abi saved to ./src/RentCar.json");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
