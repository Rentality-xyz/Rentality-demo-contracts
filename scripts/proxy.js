const { ethers, upgrades } = require('hardhat')

async function main() {
  const RentalityUserService = await ethers.getContractFactory('RentalityUserService');
  const userService = await upgrades.deployProxy(RentalityUserService);
  await userService.initialize();
  await userService.deployed();

  return userService;
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });