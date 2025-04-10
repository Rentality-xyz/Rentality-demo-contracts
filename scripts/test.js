const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { DiamondCutFunctions, ethToken } = require('../test/utils')


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

const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet")
const diamondCutFacet = await DiamondCutFacet.deploy()
await diamondCutFacet.waitForDeployment()

const DiamondInit = await ethers.getContractFactory('DiamondInit')
const diamondInitFaucet = await DiamondInit.deploy()

const Diamond = await ethers.getContractFactory("Diamond")
let diamond = await Diamond.deploy(deployer.address, await diamondCutFacet.getAddress())

diamond = await ethers.getContractAt("DiamondCutFacet", await diamond.getAddress()) 
const cut = []
for (const FacetName of facetNames) {
  const Facet = await ethers.getContractFactory(FacetName);
  const facet = await Facet.deploy();
  await facet.waitForDeployment();
  const address = await facet.getAddress()

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
                                                                            ethToken,
                                                                            ethToken,
                                                                            "name",
                                                                            "sym",
                                                                            ethToken,
                                                                            ethToken,
                                                                            10,
                                                                            ethToken,
                                                                            ethToken,
                                                                            ethToken,
                                                                            ethToken,
                                                                            ethToken
                                                                            ])


const result = await diamond.diamondCut(cut, await diamondInitFaucet.getAddress(), functionInitData)
console.log("DONE:", result.signature);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
