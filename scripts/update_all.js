const { spawnSync } = require('child_process')
const { getChains } = require('./utils/proxyList')

async function main() {
  let chains = await getChains()
  let updatedNetworks = new Set()
  for (let i = 0; i < chains.length; i++) {
    let contracts = chains[i]
    if (!updatedNetworks.has(contracts.name)) {
      updatedNetworks.add(contracts.name)
      updateProxies(contracts.name)
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

function updateProxies(network) {
  console.log('Start updating on network: ' + network)
  const command = 'npx hardhat run ' + '--network ' + network + ' scripts/updateCommand.js'
  try {
    const result = spawnSync(command, {
      shell: true,
      stdio: 'inherit',
    })

    if (result.error) {
      console.error('Error:', result.error)
      process.exit(1)
    }
    console.log('Deployment finished.')
  } catch (error) {
    console.error('Error:', error)
    process.exit(1)
  }
}
