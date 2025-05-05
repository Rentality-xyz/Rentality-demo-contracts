const { ethers, upgrades } = require('hardhat')
const { getNeededServices } = require('./deployHelpers')
const { startDeploy } = require('../utils/deployHelper')
const { ethToken, DiamondCutFunctions } = require('../../test/utils')
const { saveDiamondAbi } = require('../utils/abiSaver')


async function main() {
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
const map = {}

const { deployer } = await startDeploy('')

const {
  refferalLibAddress,
  engineAddress,
  rentalityVerifier,
  civicMockVerifier,
  rentalityEthService,
  rentalityUsdtService,
  usdtToken,
  baseDiscount,
} = await getNeededServices() 

const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet")
const diamondCutFacet = await DiamondCutFacet.deploy()
await diamondCutFacet.waitForDeployment()

const DiamondInit = await ethers.getContractFactory('DiamondInit')
const diamondInitFaucet = await DiamondInit.deploy()

const Diamond = await ethers.getContractFactory("Diamond")
let diamond = await Diamond.deploy(deployer.address, await diamondCutFacet.getAddress())

diamond = await ethers.getContractAt("DiamondCutFacet", await diamond.getAddress()) 
const cut = []
const abis = {
  abi: []
}
for (const FacetName of facetNames) {
  const Facet = await ethers.getContractFactory(FacetName);
  const facet = await Facet.deploy();
  await facet.waitForDeployment();
  const address = await facet.getAddress()


  abis.abi = abis.abi.concat(JSON.parse(facet.interface.formatJson()))

  const selectors = []
  Facet.interface.forEachFunction(f => {
    selectors.push(f.selector)
    if(map[f.selector] === undefined) {
      map[f.selector] = {};
      map[f.selector].contract = FacetName
      map[f.selector].funName = f.name
    }
    else {
      console.log("Double selector: ", f.selector)
      console.log("Fun name: ", f.name)
      console.log("Contract:", FacetName)
    }
  })
 cut.push({
    facetAddress: address,
    action: DiamondCutFunctions.addFacet,
    functionSelectors: selectors
  })
  console.log("Facet deployed: ",  FacetName)

}



let functionInitData = diamondInitFaucet.interface.encodeFunctionData('init',[
                                                                            rentalityVerifier,
                                                                            refferalLibAddress,
                                                                            "name",
                                                                            "sym",
                                                                            engineAddress,
                                                                            civicMockVerifier,
                                                                            10,
                                                                            rentalityEthService,
                                                                            usdtToken,
                                                                            rentalityUsdtService,
                                                                            baseDiscount,
                                                                            ethToken,
                                                                            ])


const result = await diamond.diamondCut(cut, await diamondInitFaucet.getAddress(), functionInitData)

saveDiamondAbi(abis)
console.log("DONE:", result.signature);
console.log("Diamond address:", await diamond.getAddress())
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
