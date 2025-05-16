const { ethers, upgrades } = require('hardhat')
const { checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')


async function main() {
    const [deployer] = await ethers.getSigners()
    const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1

    const viewServiceAddress = checkNotNull(
        getContractAddress('RentalityView', 'scripts/deploy_4c_RentalityView.js', chainId),
        'RentalityView'
      )
    const viewService = await ethers.getContractAt('RentalityView', viewServiceAddress)


    const rentalityTripsView = checkNotNull(
        getContractAddress('RentalityTripsView', 'scripts/deploy_4b_RentalityTripsView.js', chainId),
        'RentalityTripsView'
      )
      const rentalityContract = {
        carService: checkNotNull(
          getContractAddress('RentalityCarToken', 'scripts/deploy_3_RentalityCarToken.js', chainId),
          'RentalityCarToken'
        ),
        currencyConverterService: checkNotNull(
          getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
          'RentalityCurrencyConverter'
        ),
        tripService: checkNotNull(
          getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js', chainId),
          'RentalityTripService'
        ),
        userService: checkNotNull(
          getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
          'RentalityUserService'
        ),
        rentalityPlatform: checkNotNull(
          getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
          'RentalityPlatform'
        ),
        paymentService: checkNotNull(
          getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
          'RentalityPaymentService'
        ),
        claimService: checkNotNull(
          getContractAddress('RentalityClaimService', 'scripts/deploy_2a_RentalityClaimService.js', chainId),
          'RentalityClaimService'
        ),
        adminService: checkNotNull(
          getContractAddress('RentalityAdminGateway', 'scripts/deploy_6_RentalityAdminGateway.js', chainId),
          'RentalityAdminGateway'
        ),
        deliveryService: checkNotNull(
          getContractAddress('RentalityCarDelivery', 'scripts/deploy_2i_RentalityCarDelivery.js', chainId),
          'RentalityCarDelivery'
        ),
        viewService: checkNotNull(
          getContractAddress('RentalityView', 'scripts/deploy_4c_RentalityView.js', chainId),
          'RentalityView'
        ),
      }

      const dimoService = checkNotNull(
        getContractAddress('RentalityDimoService', 'scripts/deploy_3e_RentalityDimoService.js', chainId),
        'RentalityDimoService'
      )

      const rentalityInsurance = checkNotNull(
        getContractAddress('RentalityInsurance', 'scripts/deploy_3d_RentalityInsurance.js', chainId),
        'RentalityInsurance'
      )
    

      const rentalityPromoService = checkNotNull(
        getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId))


        console.log(
            await viewService.updateServiceAddresses(rentalityContract, rentalityInsurance, rentalityTripsView,rentalityPromoService, dimoService)
        )
 


}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
