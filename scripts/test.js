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
const v = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

console.log(await v.getTrip(185))
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
