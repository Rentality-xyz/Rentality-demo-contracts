const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')

async function getInsuranceUrl(proxyAddress, caseId, mapSlot) {
    const provider = new ethers.JsonRpcProvider("https://base-sepolia.g.alchemy.com/v2/7NsKIcu9tp2GBR_6wuAL3L-oEvo5wflB");
    const keyBytes32 =  ethers.zeroPadBytes(caseId, 32);
    const mapSlotBytes32 = ethers.zeroPadBytes('0x00', 32);
    
    // Вычисление слота хранения
    const concatenated = ethers.concat([keyBytes32, mapSlotBytes32]);
    console.log("CONCATENATED", concatenated)
    const storageSlot = ethers.keccak256(concatenated);
    
    // Чтение данных из слота
    const data = await provider.getStorage(proxyAddress, storageSlot);
    console.log("DATA", data)
    const dataBytes = ethers.arrayify(data);
    const lastByte = dataBytes[31];
    
    let content;
    if (lastByte % 2 === 0) {
        // Короткая строка (inline)
        const length = lastByte / 2;
        content = ethers.utils.toUtf8String(dataBytes.slice(0, length));
    } else {
        // Длинная строка (внешние слоты)
        const length = (lastByte - 1) / 2;
        const baseSlot = ethers.utils.keccak256(storageSlot);
        let hexString = '0x';
        const numSlots = Math.ceil(length / 32);
        
        for (let i = 0; i < numSlots; i++) {
            const slot = ethers.BigNumber.from(baseSlot).add(i).toHexString();
            const chunk = await provider.getStorageAt(proxyAddress, slot);
            hexString += chunk.slice(2);
        }
        
        content = ethers.utils.toUtf8String(hexString.substring(0, 2 + length * 2));
    }
    
    return content;
}

async function main() {
  const contract = await ethers.getContractAt('RentalityTaxes','0x2287de614e0CafED95b42c45dd959176F4a9fF14')
  const payments = await ethers.getContractAt("RentalityPaymentService", "0x6080F7A1F4fDaED78e01CDC951Bb15588B04EBF7")
  const carToken = await ethers.getContractAt("IRentalityGateway", "0xB257FE9D206b60882691a24d5dfF8Aa24929cB73")
  // const abiCoder = new ethers.AbiCoder()
  // const encoded = abiCoder.encode(['string'], ["District of Columbia"])
  // console.log("ENCODED", keccak256(encoded).toString('hex'))
  // console.log("CONTRACT", await contract.getTaxesIdByHash('0x' + keccak256(encoded).toString('hex')))

  console.log("CAR:" ,await carToken.getCarDetails(151))
  console.log("PAYMENTS", await payments.defineTaxesType('0xCfd84b30b9fddaa275b38a40E08D8bE990688033',151))

  console.log("TAXES",await contract.calculateTaxesDTO(52,3,294))
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
