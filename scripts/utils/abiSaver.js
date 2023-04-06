const fs = require("fs");

var saveJsonAbi = function (fileName, chainId, contract) {
  const jsonData = {
    address: contract.address,
    abi: JSON.parse(contract.interface.format("json")),
  };

  const chainIdString = chainId !== 1337 ? chainId.toString() : "localhost";
  let filePath;

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
