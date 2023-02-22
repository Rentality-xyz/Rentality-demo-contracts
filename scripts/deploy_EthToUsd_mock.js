const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main(args) {
  const [deployer] = await ethers.getSigners();
  
  const chainId = (await deployer.provider?.getNetwork()).chainId;
  if (chainId !== 1337)  { 
    return;
  }

  const balance = await deployer.getBalance();
  console.log("Deployer address is:", deployer.getAddress()," with balance:", balance);
  const MockEthToUsdPriceFeed = await hre.ethers.getContractFactory("MockEthToUsdPriceFeed");
  const mockEthToUsdPriceFeed = await MockEthToUsdPriceFeed.deploy(8, 165000000000);

  await mockEthToUsdPriceFeed.deployed();
  console.log("MockEthToUsdPriceFeed deployed to:", mockEthToUsdPriceFeed.address);

    const data = {
      address: mockEthToUsdPriceFeed.address,
      abi: JSON.parse(mockEthToUsdPriceFeed.interface.format('json'))
    }
  
  if (chainId !== 1337)
  {
    //This writes the ABI and address to the mktplace.json
    fs.writeFileSync('./src/MockEthToUsdPriceFeed.json', JSON.stringify(data))
    console.log("JSON abi saved to ./src/MockEthToUsdPriceFeed.json");
  } else {
    fs.writeFileSync('./src/MockEthToUsdPriceFeed.Localhost.json', JSON.stringify(data))
    console.log("JSON abi saved to ./src/MockEthToUsdPriceFeed.Localhost.json");
  }
}

main(process.argv)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
