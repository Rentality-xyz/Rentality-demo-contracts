const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  const RentCar = await hre.ethers.getContractFactory("RentCar");
  const rentCar = await RentCar.deploy();

  await rentCar.deployed();

  const data = {
    address: rentCar.address,
    abi: JSON.parse(rentCar.interface.format('json'))
  }

  //This writes the ABI and address to the mktplace.json
  fs.writeFileSync('./src/RentCar.json', JSON.stringify(data))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
