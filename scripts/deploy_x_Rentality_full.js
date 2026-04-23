const { spawnSync } = require('child_process')

const command = 'npx hardhat run scripts/'

const commands = [
  { message: 'Deploying test USDT..', command: command + 'deploy_0a_RentalityTestUSDT.js' },
  { message: 'Deploying native price feed..', command: command + 'deploy_0b_RentalityMockPriceFeed.js' },
  { message: 'Deploying USDT price feed..', command: command + 'deploy_0c_RentalityMockUsdtPriceFeed.js' },
  { message: 'Deploying user profile main..', command: command + 'deploy_1h_UserProfileMain.js' },
  { message: 'Deploying user profile query..', command: command + 'deploy_1i_UserProfileQuery.js' },
  { message: 'Deploying location verifier..', command: command + 'deploy_2_RentalityLocationVerifier.js' },
  { message: 'Deploying notification service..', command: command + 'deploy_2_RentalityNotificationService.js' },
  { message: 'Deploying native currency adapter..', command: command + 'deploy_2c_RentalityEthService.js' },
  { message: 'Deploying usdt currency adapter..', command: command + 'deploy_2f_RentalityUsdtService.js' },
  { message: 'Deploying currency converter..', command: command + 'deploy_3b_RentalityCurrencyConverter.js' },
  { message: 'Deploying pricing taxes..', command: command + 'deploy_2e_RentalityTaxes.js' },
  { message: 'Deploying pricing base discount..', command: command + 'deploy_2g_RentalityBaseDiscount.js' },
  { message: 'Deploying swaps service..', command: command + 'deploy_2h_RentalitySwaps.js' },
  { message: 'Deploying promo service..', command: command + 'deploy_4f_RentalityPromo.js' },
  { message: 'Deploying geo service..', command: command + 'deploy_2f_RentalityGeoService.js' },
  { message: 'Deploying engine service..', command: command + 'deploy_2b_RentalityEngineService.js' },
  { message: 'Deploying car model..', command: command + 'deploy_3_CarModel.js' },
  { message: 'Deploying dimo service..', command: command + 'deploy_3e_RentalityDimoService.js' },
  { message: 'Deploying rental referral main..', command: command + 'deploy_3n_RentalReferralMain.js' },
  { message: 'Deploying rental referral query..', command: command + 'deploy_3o_RentalReferralQuery.js' },
  { message: 'Deploying rental pricing main..', command: command + 'deploy_3j_RentalPricingMain.js' },
  { message: 'Deploying rental pricing query..', command: command + 'deploy_3k_RentalPricingQuery.js' },
  { message: 'Deploying rental insurance main..', command: command + 'deploy_3l_RentalInsuranceMain.js' },
  { message: 'Deploying rental insurance query..', command: command + 'deploy_3m_RentalInsuranceQuery.js' },
  { message: 'Deploying car tax adapter..', command: command + 'deploy_3r_CarTaxAdapter.js' },
  { message: 'Deploying trip main..', command: command + 'deploy_3s_TripMain.js' },
  { message: 'Deploying trip query..', command: command + 'deploy_3t_TripQuery.js' },
  { message: 'Deploying rental claim store..', command: command + 'deploy_2a_RentalClaimStore.js' },
  { message: 'Deploying rental claim query..', command: command + 'deploy_3u_RentalClaimQuery.js' },
  { message: 'Deploying rental insurance query facet 1..', command: command + 'deploy_3v_RentalInsuranceQueryFacet1.js' },
  { message: 'Deploying car query facet 2..', command: command + 'deploy_3w_CarQueryFacet2.js' },
  { message: 'Deploying rental insurance query facet 2..', command: command + 'deploy_3x_RentalInsuranceQueryFacet2.js' },
  { message: 'Deploying rental investment main..', command: command + 'deploy_3p_RentalInvestmentMain.js' },
  { message: 'Deploying rental investment query..', command: command + 'deploy_3q_RentalInvestmentQuery.js' },
  { message: 'Deploying rental payment main..', command: command + 'deploy_3h_RentalPaymentMain.js' },
  { message: 'Deploying rental payment query..', command: command + 'deploy_3i_RentalPaymentQuery.js' },
  { message: 'Deploying rental claim main..', command: command + 'deploy_3y_RentalClaimMain.js' },
  { message: 'Deploying profile gateway facet..', command: command + 'deploy_4h_ProfileGatewayFacet.js' },
  { message: 'Deploying referral gateway facet..', command: command + 'deploy_4i_ReferralGatewayFacet.js' },
  { message: 'Deploying investment gateway facet..', command: command + 'deploy_4j_InvestmentGatewayFacet.js' },
  { message: 'Deploying trip gateway facet..', command: command + 'deploy_4k_TripGatewayFacet.js' },
  { message: 'Deploying car gateway facet..', command: command + 'deploy_4l_CarGatewayFacet.js' },
  { message: 'Deploying car view gateway facet..', command: command + 'deploy_4m_CarViewGatewayFacet.js' },
  { message: 'Deploying car view gateway facet 1..', command: command + 'deploy_4m1_CarViewGatewayFacet1.js' },
  { message: 'Deploying payment gateway facet..', command: command + 'deploy_4n_PaymentGatewayFacet.js' },
  { message: 'Deploying claim gateway facet..', command: command + 'deploy_4o_ClaimGatewayFacet.js' },
  { message: 'Deploying insurance gateway facet..', command: command + 'deploy_4p_InsuranceGatewayFacet.js' },
  { message: 'Deploying admin gateway facet..', command: command + 'deploy_4q_AdminGatewayFacet.js' },
  { message: 'Deploying contracts..', command: command + 'deploy_7_RentalityGateway.js' },
  { message: 'Grand manager role...', command: command + 'deploy_8_GrandManagerRole.js' },
  { message: 'Grand KYC manager role...', command: command + 'grandKYCManagerRole.js' },
  { message: 'Set trusted forwarder...', command: command + 'deploy_XI_setTrusted.js' },
  { message: 'Set taxes for all states...', command: command + 'setTaxes.js' },
  { message: 'Formatting ABIs...', command: 'npx prettier --write ./src' },
]

async function main() {
  for (let i = 0; i < commands.length; i++) {
    console.log('\n' + commands[i].message)
    spawnSync(commands[i].command, {
      shell: true,
      stdio: 'inherit',
      env: { ...process.env, SILENT: 'true' },
    })
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('deploy_x_Rentality_full error: ', error)
    process.exit(1)
  })




