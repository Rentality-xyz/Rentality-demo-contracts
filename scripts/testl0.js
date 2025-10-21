const { ethers, upgrades } = require('hardhat')

async function main() {
    let sender = await ethers.getContractAt(
      'IRentalitySender',
      '0xF103293cffA7a6998Be917DCC1A0174540B418Fc'
    )

    const provider = new ethers.JsonRpcProvider(
      "https://api-opbnb-testnet.n.dwellir.com/79e509c1-b94b-4146-ac66-efdc56786415"
    );

    console.log('Encoded data:', sender.interface.encodeFunctionData('quoteAddUserDeliveryPrices', [100, 20]))
    
    const trace = await provider.send("debug_traceCall", [
      {
        from: "0x03BeA6708d02da771ca60121E2aABa11B375de38", // your address
        to: "0xF103293cffA7a6998Be917DCC1A0174540B418Fc",
        gas: "0x30d40", // ~200,000 gas
        gasPrice: "0x3b9aca00", // 1 gwei
        value: "0x0",
        data: sender.interface.encodeFunctionData('quoteAddUserDeliveryPrices', [100, 20])
      },
      "latest",
      {
        tracer: "callTracer",
        tracerConfig: {
          withLog: true
        }
      }
    ]);

    console.log("Trace:", trace);

        const quote = await sender.quoteAddUserDeliveryPrices(100, 20)
        console.log('Quote result:', quote)
  
    

    sender = await ethers.getContractAt(
      'IRentalityGateway',
      '0xF103293cffA7a6998Be917DCC1A0174540B418Fc'
    )
    

    const data = sender.interface.encodeFunctionData(
      'addUserDeliveryPrices',
      [100, 20]
    );
    
    // Manually send transaction (no simulation)
    const txResponse = await signer.sendTransaction({
      to: sender.target, // or sender.address depending on ethers version
      data,
      value: quote
    });
    
    console.log("TX sent:", txResponse.hash);
    


    
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