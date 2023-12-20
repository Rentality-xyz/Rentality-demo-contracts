const {ethers} = require('hardhat');

async function main() {
  const libFactory = await ethers.getContractFactory("LinkedLib");
  const lib = await libFactory.deploy();
  await lib.waitForDeployment();

  const proxyFactory = await ethers.getContractFactory("ProxyLib");
  const proxy = await proxyFactory.deploy(await lib.getAddress());
  await proxy.waitForDeployment();

  const UseLibFactory = await ethers.getContractFactory("UseLib");
  const useLib = await UseLibFactory.deploy(await proxy.getAddress());
  await useLib.waitForDeployment();

 const result = await useLib.compareStringWithLib("f","a");
  await result.wait();

  const state = await useLib.getState();
  console.log(state)



}

main().catch((e) => {
  console.error(e)
  process.exit(0)
})