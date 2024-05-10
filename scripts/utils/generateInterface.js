const fs = require('fs')
const { exec, execSync } = require('child_process')

const directory = './artifacts'

const args = process.argv.slice(2)
if (args[0] === undefined) {
  console.log('Enter contract name, and try again: \nnpm run generate_interface -- IRentalityGateway\n')
  process.exit(0)
}
const contract = args[0]

fs.access(directory, fs.constants.F_OK, (err) => {
  if (err) {
    console.log('Artifacts folder is not found, run: npx hardhat compile, and try again.')
    process.exit(0)
  }

  exec(
    'typechain --target=ethers-v6 artifacts/contracts/' + contract + '.sol/' + contract + '.json',
    (error, stdout, stderr) => {
      if (error) {
        console.error(`Error: ${error.message}`)
        return
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`)
        return
      }
      console.log(`Compilation and typechain process completed: ${stdout}`)
    }
  )
})
