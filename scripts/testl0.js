const { ethers, upgrades } = require('hardhat')

async function main() {
    let sender = await ethers.getContractAt(
      'IRentalitySender',
      '0xF103293cffA7a6998Be917DCC1A0174540B418Fc'
    )

    console.log('Encoded data:', sender.interface.encodeFunctionData('quoteAddUserDeliveryPrices', [100, 20]))
    
    console.log('Attempting to call quoteAddUserDeliveryPrices...')
    try {
        console.log('Attempting to call quoteAddUserDeliveryPrices...')
        const quote = await sender.quoteAddUserDeliveryPrices(100, 20)
        console.log('Quote result:', quote.toString())
      } catch (error) {
        console.error('Transaction failed!')
        
        console.log(error)
        // Get the transaction trace
        if (error.transaction) {
          const trace = await ethers.provider.send('debug_traceTransaction', [
            error.transaction.hash
          ])
          console.log('Trace:', JSON.stringify(trace, null, 2))
        }
      }
    

    sender = await ethers.getContractAt(
      'IRentalityGateway',
      '0xF103293cffA7a6998Be917DCC1A0174540B418Fc'
    )
    
    console.log('Sending transaction with value:', quote.toString())
    const tx = await sender.addUserDeliveryPrices(100, 20, { value: quote })
    console.log('Transaction hash:', tx.hash)
    
    const receipt = await tx.wait()
    console.log('Transaction confirmed in block:', receipt.blockNumber)
    


    
}

async function checkError(error) {
const contract = await ethers.getContractAt("ARentalitySender", '0xF103293cffA7a6998Be917DCC1A0174540B418Fc')

console.log(contract.interface.parseError(error.data))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })