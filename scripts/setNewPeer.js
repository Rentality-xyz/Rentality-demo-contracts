const { ethers, upgrades } = require('hardhat')

async function main() {

  const contractAddress = "0x6EDCE65403992e310A62460808c4b910D972f10f";
  const abi = [
    "function setSendLibrary(address _sender, uint32 _dstEid, address _lib)"
  ];
  const contract = new ethers.Contract(contractAddress, abi, (await ethers.getSigners())[0]);

  const data = contract.interface.encodeFunctionData("setSendLibrary", [
    "0xa253A36D6Ca39219d1789ce5F2E5c6D41e99Bc83",
    40245,
    "0xf514191C4a2D3b9A629fB658702015a5bCd570BC",
  ]);

  const provider = ethers.provider;

  try {
    // low-level call — doesn’t estimate gas, so revert data is returned
    const result = await provider.call({
      to: contractAddress,
      data,
    });
    console.log("Call succeeded:", result);
  } catch (err) {
    // show raw revert data
    const data = err.error?.data || err.data;
    console.log("Raw revert data:", data);

    // try decoding if ABI has custom errors
    try {
      const fullAbi = (await hre.artifacts.readArtifact("EndpointV2")).abi;
      const iface = new ethers.Interface(fullAbi);
      const decoded = iface.parseError(data);
      console.log("Decoded custom error:", decoded.name, decoded.args);
    } catch (decodeErr) {
      console.log("Could not decode revert data");
    }
  }
    // let sender = await ethers.getContractAt(
    //   'RentalityReceiver',
    //   '0xbAaE15E3B0688d4a89104caB28c01B2ED3f5373b'
    // )

    // console.log('Encoded data:', await sender.setNewPeer(40202, '0xa253A36D6Ca39219d1789ce5F2E5c6D41e99Bc83'))
    
  

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

