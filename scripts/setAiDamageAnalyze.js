const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
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

        const aiDamageAnalyze = checkNotNull(
            getContractAddress('RentalityAiDamageAnalyze', 'scripts/deploy_3f_RentalityAiDamageAnalyze.js', chainId))

      const contract = await ethers.getContractAt('RentalityTripsView',rentalityTripsView)

      const tx = await contract.updateServiceAddresses(rentalityContract,
        rentalityInsurance,
        rentalityPromoService,
        dimoService,
        aiDamageAnalyze
      )

      console.log(tx)

      console.log("Done!")

  }

  main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })