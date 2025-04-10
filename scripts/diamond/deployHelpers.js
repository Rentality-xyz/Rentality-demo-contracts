const { ethers } = require('hardhat')
const { checkNotNull, startDeploy } = require('../utils/deployHelper')
const { getContractAddress } = require('../utils/contractAddress')


async function getNeededServices() {
  const { deployer, chainId } = await startDeploy('')
    const refferalLibAddress = checkNotNull(
        getContractAddress('RentalityRefferalLib', 'scripts/deploy_1f_RentalityRefferalLib.js', chainId),
        'RentalityRefferalLib'
      )

      const engineAddress = checkNotNull(
        getContractAddress('RentalityEnginesService', 'scripts/deploy_2b_RentalityEngineService.js', chainId),
        'RentalityEnginesService'
      )
      const rentalityVerifier = checkNotNull(
        getContractAddress('RentalityLocationVerifier', 'scripts/deploy_2_RentalityLocationVerifier.js', chainId),
        'RentalityLocationVerifier'
      )

      const rentalityEthService = checkNotNull(
        getContractAddress('RentalityETHConvertor', 'scripts/deploy_2c_RentalityEthService.js', chainId),
        'RentalityETHConvertor'
      )

      const rentalityUsdtService = checkNotNull(
        getContractAddress('RentalityUSDTConverter', 'scripts/deploy_2f_RentalityUsdtService.js', chainId),
        'RentalityUSDTConverter'
      )
      const usdtToken = checkNotNull(
        getContractAddress('RentalityTestUSDT', 'scripts/deploy_0a_RentalityTestUSDT.js', chainId),
        'RentalityTestUSDT'
      )

      const baseDiscount = checkNotNull(
        getContractAddress('RentalityBaseDiscount', 'scripts/deploy_2g_RentalityBaseDiscount.js', chainId),
        'RentalityBaseDiscount'
      )

      const civicMockVerifier = checkNotNull(
        getContractAddress('CivicMockVerifier', '', chainId),
        'CivicMockVerifier'
      )

    

      return {
        refferalLibAddress,
        engineAddress,
        rentalityVerifier,
        rentalityEthService,
        rentalityUsdtService,
        usdtToken,
        baseDiscount,
        civicMockVerifier
      }


}
module.exports = {
    getNeededServices
}