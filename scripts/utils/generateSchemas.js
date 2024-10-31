const fs = require('fs')
// const { Type } = require('hardhat/internal/hardhat-network/provider/filter')

const INPUT_SOLIDITY_FILE = './contracts/Schemas.sol'
const OUTPUT_TYPESCRIPT_FILE = 'src/Schemas.ts'

function mapSolidityTypeToTs(solidityType) {
  switch (solidityType) {
    case 'uint256':
    case 'int256':
    case 'uint128':
    case 'int128':
    case 'uint64':
    case 'int64':
    case 'uint32':
    case 'int32':
    case 'uint16':
    case 'int16':
    case 'uint8':
    case 'int8':
      return 'bigint'
      return 'number'
    case 'uint256[]':
    case 'int256[]':
    case 'uint128[]':
    case 'int128[]':
    case 'uint64[]':
    case 'int64[]':
    case 'uint32[]':
    case 'int32[]':
    case 'uint16[]':
    case 'int16[]':
    case 'uint8[]':
    case 'int8[]':
      return 'bigint[]'
      return 'number[]'
    case 'uint':
    case 'int':
      return 'bigint'
    case 'uint[]':
    case 'int[]':
      return 'bigint[]'
    case 'bytes32':
    case 'bytes':
      return 'string'
    case 'address':
      return 'string'
    case 'string':
      return solidityType
    case 'address[]':
    case 'string[]':
      return 'string[]'
    case 'bool':
      return 'boolean'
    default:
      return solidityType
  }
}

function main() {
  const structPattern = /struct\s+(\w+)\s*{([^}]*)}/g
  const enumPattern = /enum\s+(\w+)\s*{([^}]*)}/g

  let tsCode = ''

  fs.readFile(INPUT_SOLIDITY_FILE, 'utf8', (err, data) => {
    if (err) {
      console.error('Error reading Solidity file:', err)
      return
    }

    let match
    let allStructNames = []

    while ((match = structPattern.exec(data)) !== null) {
      allStructNames.push(match[1])
    }

    while ((match = structPattern.exec(data)) !== null) {
      const structName = match[1]
      const structContent = match[2]
      const typescriptStructName = `Contract${structName}`

      tsCode += `export type ${typescriptStructName} = {\n`
      structContent.split(';').forEach((field) => {
        field = field.trim()
        if (field) {
          if (field.startsWith('//')) {
            field = field.split('\n')[1].trim()
          }
          let [fieldType, fieldName] = field.split(/\s+/)
          if (allStructNames.includes(fieldType.replace('[]', ''))) {
            fieldType = `Contract${fieldType}`
          }
          if (fieldName === 'engineType') {
            fieldType = 'EngineType'
          }
          const tsFieldType = mapSolidityTypeToTs(fieldType).toString()
          tsCode += `  ${fieldName}: ${tsFieldType};\n`
        }
      })
      tsCode += '};\n\n'
    }

    while ((match = enumPattern.exec(data)) !== null) {
      const enumName = match[1]
      const enumContent = match[2]
      let i = 0

      tsCode += `export type ${enumName} = bigint;\n`
      tsCode += `export const ${enumName} = {\n`
      if (enumName !== 'TripStatus') {
        enumContent.split(',').forEach((value) => {
          value = value.trim()
          if (value && !value.includes('//')) {
            tsCode += `  ${value}: BigInt(${i}),\n`
            i++
          }
        })
      } else {
        tsCode += `  Pending: BigInt(0), // Created\n`
        tsCode += `  Confirmed: BigInt(1), // Approved\n`
        tsCode += `  CheckedInByHost: BigInt(2), // CheckedInByHost\n`
        tsCode += `  Started: BigInt(3), // CheckedInByGuest\n`
        tsCode += `  CheckedOutByGuest: BigInt(4), //CheckedOutByGuest\n`
        tsCode += `  Finished: BigInt(5), //CheckedOutByHost\n`
        tsCode += `  Closed: BigInt(6), //Finished\n`
        tsCode += `  Rejected: BigInt(7), //Canceled\n`
        tsCode += `\n  CompletedWithoutGuestComfirmation: BigInt(100), //Finished\n`
      }

      tsCode += '};\n\n'
    }
    tsCode += `export type EngineType = bigint;\n`
    tsCode += `export const EngineType = {\n`
    tsCode += `  PETROL: BigInt(1),\n`
    tsCode += `  ELECTRIC: BigInt(2),\n`
    tsCode += `};\n`

    fs.writeFile(OUTPUT_TYPESCRIPT_FILE, tsCode, (err) => {
      if (err) {
        console.error('Error writing TypeScript file:', err)
        return
      }
      console.log(`TypeScript file ${OUTPUT_TYPESCRIPT_FILE} has been generated.`)
    })
  })
}

main()
