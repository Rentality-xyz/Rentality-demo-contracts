const fs = require('fs')
const path = require('path')

const contractsAbiDir = path.resolve(__dirname, '..', '..', 'src', 'abis')
const frontendAbiDir = path.resolve(__dirname, '..', '..', '..', 'RentalityPrototypeNEW', 'src', 'abis')

const allowedPrefixes = ['Rentality', 'Car']
const allowedSuffixes = ['.abi.json', '.addresses.json']

function shouldCopy(fileName) {
  return (
    allowedPrefixes.some((prefix) => fileName.startsWith(prefix)) &&
    allowedSuffixes.some((suffix) => fileName.endsWith(suffix))
  )
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
}

main()
