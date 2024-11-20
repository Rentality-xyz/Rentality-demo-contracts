const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  
    const [deployer] = await ethers.getSigners()
    const balance = await ethers.provider.getBalance(deployer.address)
  
    const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1


    const rentalityAdminGatewayAddress = checkNotNull(
        getContractAddress('RentalityAdminGateway', 'scripts/deploy_6_RentalityAdminGateway.js', chainId),
        'RentalityAdminGateway'
      )
      const rentalityPlatformAddress = checkNotNull(
        getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
        'RentalityPlatform'
      )
    
    const rentalityView = checkNotNull(
        getContractAddress('RentalityView', 'scripts/deploy_4c_RentalityView.js', chainId),
        'RentalityView'
      )

    const rentalityInsurance = checkNotNull(
        getContractAddress('RentalityInsurance', 'scripts/deploy_3d_RentalityInsurance.js', chainId),
        'RentalityInsurance'
      )
      const rentalityTripsView = checkNotNull(
        getContractAddress('RentalityTripsView', 'scripts/deploy_4b_RentalityTripsView.js', chainId),
        'RentalityTripsView'
      )
      const adminService = await ethers.getContractAt('RentalityAdminGateway',rentalityAdminGatewayAddress)
      await adminService.setInsuranceService(rentalityInsurance)

      const platform = await ethers.getContractAt('RentalityPlatform', rentalityPlatformAddress)

      await platform.updateServiceAddresses(rentalityAdminGatewayAddress)

      const contracts = await adminService.getRentalityContracts()

      const view = await ethers.getContractAt('RentalityView', rentalityView)


      const rentalityUserServiceAddress = checkNotNull(
        getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
        'RentalityUserService'
      )
    
      const rentalityClaimService = checkNotNull(
        getContractAddress('RentalityClaimService', 'scripts/deploy_2a_RentalityClaimService.js', chainId),
        'RentalityClaimService'
      )
    
      const rentalityCurrencyConverterAddress = checkNotNull(
        getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
        'RentalityCurrencyConverter'
      )
    
      const rentalityPaymentServiceAddress = checkNotNull(
        getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
        'RentalityPaymentService'
      )
    
      const rentalityCarTokenAddress = checkNotNull(
        getContractAddress('RentalityCarToken', 'scripts/deploy_3_RentalityCarToken.js', chainId),
        'RentalityCarToken'
      )
    
      const rentalityTripServiceAddress = checkNotNull(
        getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js', chainId),
        'RentalityTripService'
      )
    
    
      const rentalityCarDelivery = checkNotNull(
        getContractAddress('RentalityCarDelivery', 'scripts/deploy_2i_RentalityCarDelivery.js', chainId),
        'RentalityCarDelivery'
      )
        const contractsAddresses = {
            carService: rentalityCarTokenAddress,
            currencyConverterService: rentalityCurrencyConverterAddress,
            tripService: rentalityTripServiceAddress,
            userService: rentalityUserServiceAddress,
            rentalityPlatform: rentalityPlatformAddress,
            paymentService: rentalityPaymentServiceAddress,
            claimService: rentalityClaimService,
            adminService: rentalityAdminGatewayAddress,
            deliveryService: rentalityCarDelivery,
            viewService: rentalityView


        }
      await view.updateServiceAddresses(contractsAddresses,rentalityInsurance,rentalityTripsView )

    console.log('updated!')

    }

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
