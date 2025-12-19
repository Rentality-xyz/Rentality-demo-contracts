const { ethers, upgrades } = require('hardhat')

async function main() {
const userService = await ethers.getContractAt('RentalityUserService','0xE15378Ad98796BB35cbbc116DfC70d3416B52D45')
console.log(await userService.hasRole('0xbaa42688efd68ad7551eb3356f98d93887878ab0c9b9212d12cee7725992818d',"0xD89c758da61E45eEE4770888EBe04372f0D55A6a"))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })