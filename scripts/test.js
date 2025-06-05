const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')
const { zeroHash } = require('../test/utils')

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
const v = await ethers.getContractAt('RentalityAdminGateway','0xF242A76f700Af65C2D05fB2fa74C99e64e0F299a')

// const userService = await ethers.getContractAt('RentalityUserService', '0x6a8BD84f29D74b2A77C28D23468210Cb1F8494fD')
// await userService.grantPlatformRole('0xF242A76f700Af65C2D05fB2fa74C99e64e0F299a')

// console.log(await v.setDefaultCurrencyType('0x0000000000000000000000000000000000000000'))

console.log(await v.setDefaultPrices(300,250))
// await v.setDefaultDiscount( {
//      threeDaysDiscount: 20_000,
//      sevenDaysDiscount: 100_000,
//      thirtyDaysDiscount:150_000,
//     initialized:true
//   })
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
