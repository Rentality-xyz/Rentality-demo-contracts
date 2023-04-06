const saveJsonAbi = require("./utils/abiSaver");
const { ethers } = require("hardhat");

async function main() {
  const contractName = "RentalityCurrencyConverter";
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
  if (chainId < 0) return;

  const ethToUsdPriceFeedAddress =
    chainId === 5
      ? "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"
      : chainId === 80001
      ? "0x0715A7794a1dc8e42615F059dD6e406A6594651A"
      : chainId === 1337
      ? "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318"
      : "";

  console.log("EthToUsdPriceFeedAddress is:", ethToUsdPriceFeedAddress);

  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = await contractFactory.deploy(ethToUsdPriceFeedAddress);
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
