const { readFileSync, writeFileSync, readdirSync } = require('fs')
const path = require('path')
const packageJson = require('../../package.json')

const LOCALHOST_CHAIN_ID = 1337
const version = 'v' + packageJson.version.replace(/\./g, '_')

function readJson(filePath) {
  return JSON.parse(readFileSync(filePath, 'utf-8'))
}

function writeJson(filePath, value) {
  writeFileSync(filePath, JSON.stringify(value, null, 2) + '\n', 'utf-8')
}

function removeLocalhostFromAddressBook(rootDir) {
  const addressBookPath = path.join(rootDir, 'scripts', `addressesContractsTestnets.${version}.json`)
  const addressBook = readJson(addressBookPath)
  const filtered = addressBook.filter((entry) => entry.chainId !== LOCALHOST_CHAIN_ID)
  const removed = addressBook.length - filtered.length

  if (removed > 0) {
    writeJson(addressBookPath, filtered)
  }

  return { removed }
}

function removeLocalhostFromAbiAddressFiles(rootDir) {
  const abisDir = path.join(rootDir, 'src', 'abis')
  const files = readdirSync(abisDir).filter((file) => file.endsWith('.addresses.json'))

  let changedFiles = 0

  for (const file of files) {
    const filePath = path.join(abisDir, file)
    const parsed = readJson(filePath)

    if (!Array.isArray(parsed.addresses)) continue

    const filtered = parsed.addresses.filter((entry) => entry.chainId !== LOCALHOST_CHAIN_ID)
    if (filtered.length === parsed.addresses.length) continue

    parsed.addresses = filtered
    writeJson(filePath, parsed)
    changedFiles += 1
  }

  return { changedFiles }
}

function main() {
  const rootDir = path.resolve(__dirname, '..', '..')
  const addressBookResult = removeLocalhostFromAddressBook(rootDir)
  const abiResult = removeLocalhostFromAbiAddressFiles(rootDir)

  console.log(`Removed localhost entries from ${addressBookResult.removed} address-book record(s).`)
  console.log(`Updated ${abiResult.changedFiles} ABI address file(s).`)
  console.log('Localhost chainId 1337 addresses cleaned.')
}

main()