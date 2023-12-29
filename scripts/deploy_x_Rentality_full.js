const { execSync, spawnSync } = require('child_process')
const command = 'npx hardhat run scripts/';
async function main() {


  const commands = [deployGateway, deployChatHelper, grandManagerRole]

  for (let i = 0; i < commands.length; i++) {
    try {
      spawnSync(commands[i](), {
        shell: true,
        stdio: 'inherit',
      })


    } catch (error) {
      console.error('Error:', error)
      process.exit(1)
    }


  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

function deployGateway() {
  console.log("Deploying contracts..")
  return command + 'deploy_7_RentalityGateway.js';
}
function deployChatHelper()
{
  console.log("Deploying chat helper..")
  return command + 'deploy_x_RentalityChatHelper.js';
}

function grandManagerRole()
{
  console.log("Grand manager role...")
  return command + 'deploy_8_GrandManagerRole.js';
}