const fs = require('fs')
const path = require('path')
const { spawnSync } = require('child_process')

const contractsAbiDir = path.resolve(__dirname, '..', '..', 'src', 'abis')
const frontendAbiDir = path.resolve(__dirname, '..', '..', '..', 'RentalityPrototypeNEW', 'src', 'abis')
const indexerSyncScriptPath = path.resolve(
  __dirname,
  '..',
  '..',
  '..',
  'RentalityPrototypeNEW',
  'indexer',
  'gateway',
  'scripts',
  'syncLocalhostAddresses.js'
)

const allowedPrefixes = ['Rentality', 'Car']
const allowedSuffixes = ['.abi.json', '.addresses.json']

function shouldCopy(fileName) {
  return (
    allowedPrefixes.some((prefix) => fileName.startsWith(prefix)) &&
    allowedSuffixes.some((suffix) => fileName.endsWith(suffix))
  )
}

function syncIndexerLocalhostAddresses() {
  if (!fs.existsSync(indexerSyncScriptPath)) {
    console.log(`Indexer localhost sync script was not found, skipping: ${indexerSyncScriptPath}`)
    return
  }

  const result = spawnSync(process.execPath, [indexerSyncScriptPath], {
    stdio: 'inherit',
  })

  if (result.status !== 0) {
    throw new Error(`Indexer localhost address sync failed with exit code ${result.status}`)
  }

  console.log('Indexer localhost addresses were synced')
}

function main() {
  if (!fs.existsSync(frontendAbiDir)) {
    throw new Error(`Frontend ABI directory was not found: ${frontendAbiDir}`)
  }

  const files = fs.readdirSync(contractsAbiDir).filter(shouldCopy)

  for (const fileName of files) {
    const sourcePath = path.join(contractsAbiDir, fileName)
    const targetPath = path.join(frontendAbiDir, fileName)

    fs.copyFileSync(sourcePath, targetPath)
    console.log(`Copied ${fileName}`)
  }

  console.log(`Synced ${files.length} ABI/address files to ${frontendAbiDir}`)
  syncIndexerLocalhostAddresses()
}

main()
