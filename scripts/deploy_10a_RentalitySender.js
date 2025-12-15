const { ethers, artifacts } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const saveJsonAbi = require('./utils/abiSaver')
// const { encodeParams, encodeCall, bytecodeDigest } = require('@openzeppelin/upgrades')
const { zeroPadBytes, Wallet, Transaction, TransactionRequest, JsonRpcSigner, JsonRpcProvider } = require('ethers')
const chains = require('../chainIdToEid.json');
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

const { Interface } = require('ethers')

/// For deploying on the same address
async function main() {
  /// logic for deploying contracts on the same address in dif chains.
  /// we will use fun 'create2' to deploy 'senders', that use keccak256(0xFF,this(address),salt, bytecode)
  /// for creation new address
  /// that means we need to have deployer contract on the eq address to.
  /// it will be created by fun 'create', it uses keccak256(sender,nonce)
  /// nonce is amount of sent transactions in current network
  ///the fastest way to achieve that, is created new wallet, with nonce zero in all networks
  let wallet
  let [signer] = await ethers.getSigners()
  let value = 3784261028548176
  let targetChain = 84532

  const chainId = (await signer.provider?.getNetwork())?.chainId ?? -1
  let eid = chains[chainId].eid
  let dstEid = chains[targetChain].eid
  let gasLimit = 3_000_000
  let eindpoint = chains[chainId].eindpoint

  if (process.env.NEW_WALLET === undefined) {
    wallet = new Wallet(Wallet.createRandom().privateKey, ethers.provider)
    console.log('New deployer wallet', wallet.privateKey)

    let tx = await signer.sendTransaction({
      to: await wallet.getAddress(),
      value,
    })
    await tx.wait()
  } else {
    wallet = new Wallet(process.env.NEW_WALLET, ethers.provider)
    let tx = await signer.sendTransaction({
      to: await wallet.getAddress(),
      value,
    })
    await tx.wait()
  }
  let { contractName } = await startDeploy('RentalitySender')

  if (chainId < 0) throw new Error('chainId is not set')
  let r = await ethers.getContractFactory('RentalityDeployer', wallet)
  let deployer = await r.deploy()
  await deployer.waitForDeployment()
  // console.log(await deployer.getAddress())

  const defaultAbiCoder = new ethers.AbiCoder()
 const salt = zeroPadBytes( defaultAbiCoder.encode(["uint32"], [10]), 32)

 const iface = new Interface([
  "function initialize(address endpoint, address owner, uint32 dstEid, uint32 eid, uint128 gasLimit)"
]);

  const result = iface.encodeFunctionData("initialize", [
    eindpoint,
    await signer.getAddress(),
    dstEid,
    eid,
    gasLimit
  ]);
  let tx = await deployer.initialize(salt, await signer.getAddress(), result, wallet)
  await tx.wait()
  let contractAddress = await deployer.getDeployedAddress()
  await deployer.destruct(wallet)
  console.log(contractAddress)

  

  let contract = await ethers.getContractAt('IRentalitySender', contractAddress)
  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })