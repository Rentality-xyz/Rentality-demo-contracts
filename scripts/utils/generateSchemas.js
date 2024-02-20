const fs = require('fs');
const {Type} = require("hardhat/internal/hardhat-network/provider/filter");

function mapSolidityTypeToTs(solidityType) {
    switch (solidityType) {
        case 'uint256':
        case 'int256':
        case 'uint64':
        case 'int64':
            return 'bigint';
        case 'uint32':
        case 'int32':
        case 'uint16':
        case 'int16':
        case 'uint8':
        case 'int8':
            return 'number';
        case 'uint256[]':
        case 'int256[]':
        case 'uint64[]':
        case 'int64[]':
            return 'bigint[]';
        case 'uint32[]':
        case 'int32[]':
        case 'uint16[]':
        case 'int16[]':
        case 'uint8[]':
        case 'int8[]':
            return 'number[]';
        case 'uint':
        case 'int':
            return 'bigint';
        case 'uint[]':
        case 'int[]':
            return 'bigint[]';
        case 'bytes32':
        case 'bytes':
            return 'Uint8Array'
        case 'address':
            return 'string';
        case 'string':
            return solidityType;
        case 'address[]':
        case 'string[]':
            return 'string[]';
        case 'bool':
            return 'boolean';
        default:
            return solidityType;
    }
}

function main() {

    const solidityFile = './contracts/Schemas.sol';

    const typescriptFile = 'Schemas.ts';

    const structPattern = /struct\s+(\w+)\s*{([^}]*)}/g;
    const enumPattern = /enum\s+(\w+)\s*{([^}]*)}/g;

    let tsCode = '';

    fs.readFile(solidityFile, 'utf8', (err, data) => {
        if (err) {
            console.error('Error reading Solidity file:', err);
            return;
        }


        let match;
        while ((match = structPattern.exec(data)) !== null) {
            const structName = match[1];
            const structContent = match[2];

            tsCode += `export type ${structName} = {\n`;
            structContent.split(';').forEach(field => {
                field = field.trim();
                if (field) {
                    const [fieldType, fieldName] = field.split(/\s+/);

                    const tsFieldType = mapSolidityTypeToTs(fieldType).toString();
                    tsCode += `     ${fieldName}: ${tsFieldType};\n`;
                }
            });
            tsCode += '}\n\n';
        }

        while ((match = enumPattern.exec(data)) !== null) {
            const enumName = match[1];
            const enumContent = match[2];

            tsCode += `export enum ${enumName} {\n`;
            enumContent.split(',').forEach(value => {
                value = value.trim();
                if (value && !value.includes('//')) {
                    tsCode += `     ${value},\n`;
                }
            });
            tsCode += '}\n\n';
        }

        fs.writeFile(typescriptFile, tsCode, err => {
            if (err) {
                console.error('Error writing TypeScript file:', err);
                return;
            }
            console.log(`TypeScript file ${typescriptFile} has been generated.`);
        });
    });
}

main();
