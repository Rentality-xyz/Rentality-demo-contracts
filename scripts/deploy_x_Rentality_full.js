const { spawnSync } = require('child_process')

const command = 'npx hardhat run scripts/'

const commands = [
  { message: 'Deploying contracts..', command: command + 'deploy_7_RentalityGateway.js' },
  { message: 'Grand manager role...', command: command + 'deploy_8_GrandManagerRole.js' },
  { message: 'Grand KYC manager role...', command: command + 'grandKYCManagerRole.js' },
  { message: 'Set trusted forwarder...', command: command + 'deploy_XI_setTrusted.js' },
  { message: 'Formatting ABIs...', command: 'npx prettier --write ./src' },
]

async function main() {
  for (let i = 0; i < commands.length; i++) {
    console.log('\n' + commands[i].message)
    spawnSync(commands[i].command, {
      shell: true,
      stdio: 'inherit',
    })
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('deploy_x_Rentality_full error: ', error)
    process.exit(1)
  })
