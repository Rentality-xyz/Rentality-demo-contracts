const fs = require("fs");

var saveJsonAbi = async function(fileName, chainId, contract) {
  const jsonData = {
    address: await contract.getAddress(),
    abi: JSON.parse(contract.interface.formatJson()),
  };

  const chainIdString = chainId !== 1337 ? chainId.toString() : "localhost";
  let filePath;

  fs.mkdirSync('./src/abis', { recursive: true }, (err) => {
    if (err) throw err;
  });

  if (chainId !== 1337) {
    filePath = "./src/abis/" + fileName + ".json";
    fs.writeFileSync(filePath, JSON.stringify(jsonData));
    console.log("JSON abi saved to " + filePath);
  }

  filePath = "./src/abis/" + fileName + "." + chainIdString + ".json";
  fs.writeFileSync(filePath, JSON.stringify(jsonData));
  console.log("JSON abi saved to " + filePath);
}

module.exports = saveJsonAbi;
