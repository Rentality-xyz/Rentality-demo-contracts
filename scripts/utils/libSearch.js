const fs = require('fs');
const path = require('path');

const contractHasLib =  (libName, contract) => {
return findContractFile(contract,'./contracts/')
}

function findContractFile(contractName, folderPath) {

    const files = fs.readdirSync(folderPath);

    for (const file of files) {

        const filePath = path.join(folderPath, file);

        const stats = fs.statSync(filePath);

        if (stats.isDirectory()) {
            const result = findContractFile(contractName, filePath);
            if (result) {
                return result;
            }
        } else {
            if (file.match(contractName)) {
                return '.' + path.sep + filePath;
            }
        }
    }

    return null;
}
module.exports = contractHasLib