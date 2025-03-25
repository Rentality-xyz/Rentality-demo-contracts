const { expect } = require('chai')
const {
  deployDefaultFixture,
  getMockCarRequest,
  ethToken,
  calculatePayments,
  getEmptySearchCarParams,
  TripStatus,
  zeroHash,
  emptyLocationInfo,
  emptySignedLocationInfo,
} = require('../../utils')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { ethers } = require('hardhat')

describe('price feed work correctly', function () {
  let rentalityGateway,
    rentalityMockPriceFeed,
    rentalityUserService,
    rentalityTripService,
    rentalityCurrencyConverter,
    rentalityCarToken,
    rentalityPaymentService,
    rentalityPlatform,
    engineService,
    rentalityAutomationService,
    elEngine,
    pEngine,
    hEngine,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier,
    ethContract,
    usdtPaymentContract
  beforeEach(async function () {
    ;({
      rentalityGateway,
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityPlatform,
      engineService,
      rentalityAutomationService,
      elEngine,
      pEngine,
      hEngine,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
      ethContract,
      usdtPaymentContract
    } = await loadFixture(deployDefaultFixture))})


  it('can set new feed', async function () {
    const {priceFeed, batch} = await deployFeed(BigInt("300000000000"),rentalityUserService)
        await setPriceFeed(priceFeed,ethContract, rentalityCurrencyConverter)
})
it('calculate payments with new feed', async function () {
    const calculaterInConverter = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, 100)
    const calculatedInJs = getFromUsd(100, 200000000000, 8)
    expect(calculaterInConverter[0]).to.be.equal(BigInt(calculatedInJs))
    const {priceFeed, batch} = await deployFeed(BigInt("300000000000"),rentalityUserService)
        await setPriceFeed(priceFeed,ethContract, rentalityCurrencyConverter)

    const calculaterInConverterAfterUpdate = await rentalityCurrencyConverter.getFromUsdLatest(ethToken, 100)
    const calculatedInJsWithNewRate = getFromUsd(100, 300000000000, 8)
    expect(calculaterInConverterAfterUpdate[0]).to.be.equal(calculatedInJsWithNewRate)
    
})
it('batch update', async function () {
    const {priceFeed, batch}= await deployFeed(BigInt("300000000000"),rentalityUserService)
        await setPriceFeed(priceFeed,ethContract, rentalityCurrencyConverter)

        const contractFactory = await ethers.getContractFactory('RentalityAggregator')
        const usdtAggregator = await upgrades.deployProxy(contractFactory, [await rentalityUserService.getAddress(), 18, 'USDT/USD', 1000000])
        await usdtAggregator.waitForDeployment()

        await setPriceFeed(usdtAggregator, usdtPaymentContract, rentalityCurrencyConverter)

        expect(await batch.updatePrices([{feed: await priceFeed.getAddress(), answer: BigInt("300000000000")}, {feed: await usdtAggregator.getAddress(), answer: BigInt("1000000000000")}])).to.not.reverted

})
})
 async function setPriceFeed(priceFeed, feedService, converter) {
    expect(await feedService.setRateFeed(await priceFeed.getAddress())).to.not.reverted
    expect(await converter.addCurrencyType(ethToken, await feedService.getAddress(), 'ETH')).to.not.reverted
  }
 async function deployFeed(newPrice, userService) {
    const contractFactory = await ethers.getContractFactory('RentalityAggregator')
    const contract = await upgrades.deployProxy(contractFactory, [await userService.getAddress(), 8, 'ETH/USD', newPrice])
    await contract.waitForDeployment()

    const batchContractFactory = await ethers.getContractFactory('RentalityBatchPriceUpdater')
    const batchContract = await upgrades.deployProxy(batchContractFactory, [await userService.getAddress()])
    return {priceFeed: contract, batch: batchContract}
  }
  function getFromUsd(valueInUsdCents, ethToUsdRate, ethToUsdDecimals) {
    const WEI_PER_ETHER = BigInt(10 ** 18); 
    const scaleFactor = BigInt(10 ** (ethToUsdDecimals - 2));

    const valueInEthWei = (BigInt(valueInUsdCents) * WEI_PER_ETHER * scaleFactor) / BigInt(ethToUsdRate);

    return valueInEthWei.toString();
}
    
