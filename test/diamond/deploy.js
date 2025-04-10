const { ethers } = require("hardhat")
const { ethToken, DiamondCutFunctions, signTCMessage, zeroHash } = require("../utils")

const facetNames = [
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "RentalityCarDeliveryFacet",
    "RentalityDimoServiceFacet",
    "RentalityGeoServiceFacet",
    "RentalityRefferalServiceFacet",
    "RentalityRefferalServiceFacet2",
    "RentalityTaxesFacet",
    "RentalityCarTokenFacet",
    "RentalityTripServiceFacet",
    "RentalityTripServiceFacet2",
    "RentalityUserServiceFacet",
    "RentalityViewFacet",
    "RentalityViewFacet2",
    "RentalityViewFacet3",
    "RentalityCurrencyConverterFacet",
    "RentalityInsuranceFacet",
    "RentalityPaymentsServiceFacet"

]


const calculatePayments = async (gateway, value, tripDays, deposit, token = ethToken, taxId = 1) => {
    const gatewayAddress = await gateway.getAddress()
    const paymentService = await ethers.getContractAt('RentalityPaymentsServiceFacet', gatewayAddress)
    const taxesService = await ethers.getContractAt('RentalityTaxesFacet', gatewayAddress)

    let priceWithDiscount = await paymentService.calculateSumWithDiscount(
      '0x0000000000000000000000000000000000000000',
      tripDays,
      value
    )
    let totalTaxes = await taxesService.calculateTaxes(taxId, tripDays, priceWithDiscount)
  
    const converter = await ethers.getContractAt('RentalityCurrencyConverterFacet', gatewayAddress) 
    const [rate, decimals] = await converter.getCurrentRate(token)
  
    const rentPriceInEth = await converter.getFromUsd(
      token,
      priceWithDiscount + totalTaxes + BigInt(deposit),
      rate,
      decimals
    )
    const taxes = await converter.getFromUsd(token, totalTaxes, rate, decimals)
  
    const feeInUsdCents = await paymentService.getPlatformFeeFrom(priceWithDiscount)
  
    const rentalityFee = await converter.getFromUsd(token, feeInUsdCents, rate, decimals)
  
    return {
      rentPriceInEth,
      ethToCurrencyRate: rate,
      ethToCurrencyDecimals: decimals,
      rentalityFee,
      taxes,
    }
  }


// baseDiscount,
// investService
async function deployDefault() {

    const [owner, admin, manager, host, guest, anonymous, hashCreator] = await ethers.getSigners()

      let RefferalLibFactory = await ethers.getContractFactory('RentalityRefferalLibDiamond')
      let refferalLib = await RefferalLibFactory.deploy()
      await refferalLib.waitForDeployment()


      const RentalityUserService = await ethers.getContractFactory("RentalityUserService")

      const RentalityMockPriceFeed = await ethers.getContractFactory('RentalityMockPriceFeed')
        let rentalityMockPriceFeed = await RentalityMockPriceFeed.deploy(8, 200000000000)
        await rentalityMockPriceFeed.waitForDeployment()
      
        let rentalityMockUsdtPriceFeed = await RentalityMockPriceFeed.deploy(6, 100)
        await rentalityMockPriceFeed.waitForDeployment()
      
        const MockCivic = await ethers.getContractFactory('CivicMockVerifier')
        const mockCivic = await MockCivic.deploy()
        await mockCivic.waitForDeployment()

        const rentalityUserService = await upgrades.deployProxy(RentalityUserService, [await mockCivic.getAddress(), 0])

        await rentalityUserService.waitForDeployment()

        const electricEngine = await ethers.getContractFactory('RentalityElectricEngine')
        const elEngine = await electricEngine.deploy(await rentalityUserService.getAddress())
      
        const patrolEngine = await ethers.getContractFactory('RentalityPetrolEngine')
        const pEngine = await patrolEngine.deploy(await rentalityUserService.getAddress())
      
        const hybridEngine = await ethers.getContractFactory('RentalityHybridEngine')
        const hEngine = await hybridEngine.deploy(await rentalityUserService.getAddress())
      
        const EngineService = await ethers.getContractFactory('RentalityEnginesService')
        const engineService = await upgrades.deployProxy(EngineService, [
          await rentalityUserService.getAddress(),
          [await pEngine.getAddress(), await elEngine.getAddress(), await hEngine.getAddress()],
        ])
        await engineService.waitForDeployment()

        const RentalityVerifier = await ethers.getContractFactory('RentalityLocationVerifier')

          let rentalityLocationVerifier = await upgrades.deployProxy(RentalityVerifier, [
            await rentalityUserService.getAddress(),
            admin.address,
          ])


            const RentalityEth = await ethers.getContractFactory('RentalityETHConvertor')
          
            const ethContract = await upgrades.deployProxy(RentalityEth, [
              await rentalityUserService.getAddress(),
              ethToken,
              await rentalityMockPriceFeed.getAddress(),
            ])
          
            await ethContract.waitForDeployment()
          
            const TestUsdt = await ethers.getContractFactory('RentalityTestUSDT')
            const usdtContract = await TestUsdt.deploy()
            await usdtContract.waitForDeployment()
          
            const RentalityUSDT = await ethers.getContractFactory('RentalityUSDTConverter')
          
            const usdtPaymentContract = await upgrades.deployProxy(RentalityUSDT, [
              await rentalityUserService.getAddress(),
              await usdtContract.getAddress(),
              await rentalityMockUsdtPriceFeed.getAddress(),
            ])
            await usdtContract.waitForDeployment()


              const RentalityBaseDiscount = await ethers.getContractFactory('RentalityBaseDiscount')
            
              const rentalityBaseDiscount = await upgrades.deployProxy(RentalityBaseDiscount, [
                await rentalityUserService.getAddress(),
              ])

        


const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet")
const diamondCutFacet = await DiamondCutFacet.deploy()
await diamondCutFacet.waitForDeployment()

const DiamondInit = await ethers.getContractFactory('DiamondInit')
const diamondInitFaucet = await DiamondInit.deploy()

const Diamond = await ethers.getContractFactory("Diamond")
let diamond = await Diamond.deploy(owner.address, await diamondCutFacet.getAddress())

diamond = await ethers.getContractAt("DiamondCutFacet", await diamond.getAddress()) 
const cut = []
for (const FacetName of facetNames) {
  const Facet = await ethers.getContractFactory(FacetName);
  const facet = await Facet.deploy();
  await facet.waitForDeployment();
  const address = await facet.getAddress()

  const selectors = []
  Facet.interface.forEachFunction(f => selectors.push(f.selector))
 cut.push({
    facetAddress: address,
    action: DiamondCutFunctions.addFacet,
    functionSelectors: selectors
  })

}


let functionInitData = diamondInitFaucet.interface.encodeFunctionData('init',[
                                                                            await rentalityLocationVerifier.getAddress(),
                                                                            await refferalLib.getAddress(),
                                                                            "name",
                                                                            "sym",
                                                                            await engineService.getAddress(),
                                                                            await mockCivic.getAddress(),
                                                                            10,
                                                                            await ethContract.getAddress(),
                                                                            await usdtContract.getAddress(),
                                                                            await usdtPaymentContract.getAddress(),
                                                                            await rentalityBaseDiscount.getAddress(),
                                                                            ethToken
                                                                            ])

const result = await diamond.diamondCut(cut, await diamondInitFaucet.getAddress(), functionInitData)


  const rentalityGateway = await ethers.getContractAt('IRentalityGateway',await diamond.getAddress())


    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    const adminSignature = await signTCMessage(admin)
    await rentalityGateway.connect(host).setKYCInfo(' ', ' ', ' ', ' ', hostSignature, zeroHash)
    await rentalityGateway.connect(guest).setKYCInfo(' ', ' ', ' ', ' ', guestSignature, zeroHash)

  return {
    rentalityGateway,
    admin,
    anonymous,
    host,
    guest,
    owner,
    manager,
    admin,
    rentalityLocationVerifier
  }
}
module.exports = {
    deployDefault,
    calculatePayments
}