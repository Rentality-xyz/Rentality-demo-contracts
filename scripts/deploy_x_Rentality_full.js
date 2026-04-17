const { spawnSync } = require('child_process')

const command = 'npx hardhat run scripts/'

const commands = [
  { message: 'Deploying user profile main..', command: command + 'deploy_1h_UserProfileMain.js' },
  { message: 'Deploying user profile query..', command: command + 'deploy_1i_UserProfileQuery.js' },
  { message: 'Deploying rental referral main..', command: command + 'deploy_3n_RentalReferralMain.js' },
  { message: 'Deploying rental referral query..', command: command + 'deploy_3o_RentalReferralQuery.js' },
  { message: 'Deploying rental pricing main..', command: command + 'deploy_3j_RentalPricingMain.js' },
  { message: 'Deploying rental pricing query..', command: command + 'deploy_3k_RentalPricingQuery.js' },
  { message: 'Deploying rental insurance main..', command: command + 'deploy_3l_RentalInsuranceMain.js' },
  { message: 'Deploying rental insurance query..', command: command + 'deploy_3m_RentalInsuranceQuery.js' },
  { message: 'Deploying rental investment main..', command: command + 'deploy_3p_RentalInvestmentMain.js' },
  { message: 'Deploying rental investment query..', command: command + 'deploy_3q_RentalInvestmentQuery.js' },
  { message: 'Deploying rental payment main..', command: command + 'deploy_3h_RentalPaymentMain.js' },
  { message: 'Deploying rental payment query..', command: command + 'deploy_3i_RentalPaymentQuery.js' },
  { message: 'Deploying profile gateway facet..', command: command + 'deploy_4h_ProfileGatewayFacet.js' },
  { message: 'Deploying referral gateway facet..', command: command + 'deploy_4i_ReferralGatewayFacet.js' },
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

