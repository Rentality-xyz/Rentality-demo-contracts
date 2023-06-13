const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");

async function main() {
  const contractName = "RentalityMockPriceFeed";
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
  if (chainId !== 1337) {
    console.log("Can be deployed only on chainId: 1337");
    return;
  }

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(8, 200000000000);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  saveJsonAbi(contractName, chainId, contract);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
