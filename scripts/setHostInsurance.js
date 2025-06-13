const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

    
    async function main() {
      const { contractName, chainId } = await startDeploy('')
    
      if (chainId < 0) throw new Error('chainId is not set')
    
        const rentalityPlatformAddress = checkNotNull(
            getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
            'RentalityPlatform'
          )
          const rentalityPlatformHelperAddress = checkNotNull(
            getContractAddress('RentalityPlatformHelper', 'scripts/deploy_4g_RentalityPlatformHelper.js', chainId),
            'RentalityPlatformHelper'
          )

        const platform = await ethers.getContractAt('RentalityPlatform',rentalityPlatformAddress)
        const platformHelper = await ethers.getContractAt('RentalityPlatformHelper',rentalityPlatformHelperAddress)


        const tripsViewAddress = checkNotNull(
        getContractAddress('RentalityTripsView', 'scripts/deploy_4b_RentalityTripsView.js', chainId),
        'RentalityTripsView'
      )

        const tripsView = await ethers.getContractAt('RentalityTripsView',tripsViewAddress)
    
       const paymentsAddress = checkNotNull(
        getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
        'RentalityPaymentService'
       )

       const payments = await ethers.getContractAt('RentalityPaymentService',paymentsAddress)

       const rentalityHostInsurace = checkNotNull(
        getContractAddress('RentalityHostInsurance', 'scripts/deploy_3g_RentalityHostInsurance.js', chainId),
        'RentalityHostInsurance'
      )
   

      console.log(await platform.setHostInsuranceAddress(rentalityHostInsurace))
      console.log(await payments.setHostInsuranceService(rentalityHostInsurace))
      console.log(await tripsView.setHostInsuranceAddress(rentalityHostInsurace))
      console.log(await platformHelper.setHostInsuranceAddress(rentalityHostInsurace))
    }
    
    main()
      .then(() => process.exit(0))
      .catch((error) => {
        console.error(error)
        process.exit(1)
      })
    
