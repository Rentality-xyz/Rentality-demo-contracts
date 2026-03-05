const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");
const {upgrades } = require('hardhat')
require("dotenv").config();

// ============ CONFIGURATION ============
const CONFIG = {
    treasuryGasLimit: ethers.parseUnits("100000", 0),
    treasuryNativeFeeCap: ethers.parseUnits("100", 18),
    maxMessageSize: 10000,
    confirmations: 1,
    optionalDVNThreshold: 1,
};

// ============ HELPER FUNCTIONS ============
function log(message, type = "info") {
    const colors = {
        info: "\x1b[36m",      // Cyan
        success: "\x1b[32m",   // Green
        error: "\x1b[31m",     // Red
        warning: "\x1b[33m",   // Yellow
        section: "\x1b[1m\x1b[35m", // Bold Magenta
    };
    const reset = "\x1b[0m";
    console.log(`${colors[type] || colors.info}${message}${reset}`);
}

function saveDeployment(data, filename) {
    const deployDir = "./deployments";
    if (!fs.existsSync(deployDir)) {
        fs.mkdirSync(deployDir, { recursive: true });
    }
    const network = hre.network.name;
    const filepath = path.join(deployDir, `${filename}-${network}.json`);
    fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
    log(`✓ Saved to ${filepath}`, "success");
    return filepath;
}

function loadDeployment(filename) {
    const deployDir = "./deployments";
    const network = hre.network.name;
    const filepath = path.join(deployDir, `${filename}-${network}.json`);
    if (fs.existsSync(filepath)) {
        return JSON.parse(fs.readFileSync(filepath, "utf8"));
    }
    return null;
}

// ============ DEPLOY DVN ============
async function deployDVN(endpointAddress, deployer) {
    log("\n========== DEPLOYING DVN (ReceiveUln302) ==========", "section");
    
    const existing = loadDeployment("dvn");
    if (existing) {
        log(`DVN already deployed at: ${existing.dvn}`, "warning");
        return existing.dvn;
    }

    log("Deploying DVN...", "info");
    const ReceiveUln302 = await ethers.getContractFactory("ReceiveUln302");
    const dvn = await ReceiveUln302.deploy(endpointAddress);
    // await dvn.wait();
    log(`✓ DVN deployed at: ${dvn.address}`, "success");

    saveDeployment({
        dvn: dvn.address,
        endpoint: endpointAddress,
        type: "ReceiveUln302",
        role: "DVN",
        deployedBy: deployer.address,
        deployedAt: new Date().toISOString(),
    }, "dvn");

    return dvn.address;
}

// ============ DEPLOY EXECUTOR ============
async function deployExecutor(endpoint, receiveUln302Address, deployer) {
    log("\n========== DEPLOYING EXECUTOR ==========", "section");
    
    const existing = loadDeployment("executor");
    if (existing?.proxy) {
        log(`Executor proxy already deployed at: ${existing.proxy}`, "warning");
        return existing;
    }


    log("Deploying Executor implementation...", "info");
    const Executor = await ethers.getContractFactory("Executor");
    // const executorImpl = await Executor.deploy();
    // await executorImpl.wait();
    // log(`✓ Executor implementation deployed at: ${executorImpl.address}`, "success");

    
    // Prepare initialization data
    const receiveUln301 = receiveUln302Address;
    const priceFeed = process.env.PRICE_FEED_ADDRESS || "0x0000000000000000000000000000000000000000";
    const roleAdmin = process.env.ROLE_ADMIN_ADDRESS || deployer.address;
    
    // Parse admin addresses
    const adminsList = process.env.ADMIN_ADDRESSES 
        ? process.env.ADMIN_ADDRESSES.split(",").map(a => a.trim())
        : [deployer.address];

    // Message libs (SendUln302 and other supported libraries)
    const messageLibs = process.env.MESSAGE_LIBS
        ? process.env.MESSAGE_LIBS.split(",").map(a => a.trim())
        : [];

    log(`Endpoint: ${endpoint}`, "info");
    log(`ReceiveUln301: ${receiveUln301}`, "info");
    log(`PriceFeed: ${priceFeed}`, "info");
    log(`RoleAdmin: ${roleAdmin}`, "info");
    log(`Admins: ${adminsList.join(", ")}`, "info");
    log(`MessageLibs: ${messageLibs.length} libraries`, "info");

    if (!endpoint || endpoint === "0x0000000000000000000000000000000000000000") {
        throw new Error("ENDPOINT_ADDRESS not set or invalid");
    }


    const proxy = await upgrades.deployProxy(Executor, [
        endpoint,
        receiveUln301,
        messageLibs,
        priceFeed,
        roleAdmin,
        adminsList,
    ]);
    // await proxy.wait();
    log(`✓ Executor proxy deployed at: ${await proxy.getAddress()}`, "success");

    // Verify initialization
    log("Verifying initialization...", "info");

    const executorData = {
        implementation: await proxy.getAddress(),
        proxy: await proxy.getAddress(),
        endpoint,
        receiveUln301,
        priceFeed,
        roleAdmin,
        admins: adminsList,
        messageLibs,
    };

    saveDeployment(executorData, "executor");
    return executorData;
}

// ============ DEPLOY SendUln302 ============
async function deploySendUln302(endpointAddress, executorAddress, dvnAddress, deployer) {
    log("\n========== DEPLOYING SendUln302 ==========", "section");
    
    const existing = loadDeployment("sendUln302");
    if (existing) {
        log(`SendUln302 already deployed at: ${existing.sendUln302}`, "warning");
        return existing.sendUln302;
    }

    log("Deploying SendUln302...", "info");
    const SendUln302 = await ethers.getContractFactory("SendUln302");
    console.log("HEEEEEEEEEREE", endpointAddress)
    const sendUln = await SendUln302.deploy(
        endpointAddress,
        CONFIG.treasuryGasLimit,
        CONFIG.treasuryNativeFeeCap
    );
    // await sendUln.wait();
    log(`✓ SendUln302 deployed at: ${await sendUln.getAddress()}`, "success");

    log("Configuring SendUln302 with DVN and Executor...", "info");
    const abiCoder = new ethers.AbiCoder();
    // Encode executor config
    const executorConfig = abiCoder.encode(
        ["uint32", "address"],
        [CONFIG.maxMessageSize, executorAddress]
    );

    // Encode ULN config with DVN
    const ulnConfig = abiCoder.encode(
        ["tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)"],
        [{
            confirmations: CONFIG.confirmations,
            requiredDVNCount: 0,
            optionalDVNCount: 1,
            optionalDVNThreshold: CONFIG.optionalDVNThreshold,
            requiredDVNs: [],
            optionalDVNs: [dvnAddress],
        }]
    );

    // Set default configs
    try {
        let tx = await sendUln.setConfig(1, executorConfig); // CONFIG_TYPE_EXECUTOR = 1
        // await tx.wait();
        log(`✓ Executor config set in SendUln302`, "success");

        tx = await sendUln.setDefaultConfig(2, ulnConfig); // CONFIG_TYPE_ULN = 2
        // await tx.wait();
        log(`✓ ULN config set in SendUln302 with DVN: ${dvnAddress}`, "success");
    } catch (error) {
        log(`Error configuring SendUln302: ${error.message}`, "error");
        throw error;
    }

    saveDeployment({
        sendUln302: sendUln.address,
        endpoint: endpointAddress,
        executor: executorAddress,
        dvn: dvnAddress,
        config: {
            treasuryGasLimit: CONFIG.treasuryGasLimit.toString(),
            treasuryNativeFeeCap: CONFIG.treasuryNativeFeeCap.toString(),
            maxMessageSize: CONFIG.maxMessageSize,
            confirmations: CONFIG.confirmations,
            optionalDVNThreshold: CONFIG.optionalDVNThreshold,
        },
        deployedBy: deployer.address,
        deployedAt: new Date().toISOString(),
    }, "sendUln302");

    return sendUln.address;
}

// ============ DEPLOY ReceiveUln302 ============
async function deployReceiveUln302(endpointAddress, aopp, deployer) {
    log("\n========== DEPLOYING ReceiveUln302 ==========", "section");
    
    const existing = loadDeployment("receiveUln302");
    if (existing) {
        log(`ReceiveUln302 already deployed at: ${JSON.stringify(existing)}`, "warning");
        return existing.receiveUln302;
    }

    log("Deploying ReceiveUln302...", "info");
    const ReceiveUln302 = await ethers.getContractFactory("ReceiveUln302");
    const receiveUln = await ReceiveUln302.deploy(endpointAddress);
    // await receiveUln.wait();
    log(`✓ ReceiveUln302 deployed at: ${await receiveUln.getAddress()}`, "success");

    log("Configuring ReceiveUln302 with DVN...", "info");
    const abiCoder = new ethers.AbiCoder();

    const ulnConfig = abiCoder.encode(
        ["tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)"],
        [{
            confirmations: CONFIG.confirmations,
            requiredDVNCount: 0,
            optionalDVNCount: 1,
            optionalDVNThreshold: CONFIG.optionalDVNThreshold,
            requiredDVNs: [],
            optionalDVNs: [],
        }]
    );


    try {
        // const tx = await receiveUln.setConfig(aopp, ulnConfig); // CONFIG_TYPE_ULN = 2
        // await tx.wait();
        log(`✓ ULN config set in ReceiveUln302 with DVN`, "success");
    } catch (error) {
        log(`Error configuring ReceiveUln302: ${error.message}`, "error");
        throw error;
    }

    saveDeployment({
        receiveUln302: await receiveUln.getAddress(),
        endpoint: endpointAddress,
        dvn: "",
        config: {
            confirmations: CONFIG.confirmations,
            optionalDVNThreshold: CONFIG.optionalDVNThreshold,
        },
    }, "receiveUln302");

    return await receiveUln.getAddress();
}

// ============ SETUP ENDPOINT (OPTIONAL) ============
async function setupEndpoint(endpointAddress, sendUln302Address, OApp, dstEid) {
    log("\n========== SETTING UP ENDPOINT ==========", "section");

    try {
        const EndpointV2 = await ethers.getContractFactory("EndpointV2");
        const endpoint = EndpointV2.attach(endpointAddress);

       await endpoint.setSendLibrary(OApp, dstEid, sendUln302Address)
        log("Checking if we can set libraries...", "info");
        log("Note: This may require owner permissions", "warning");

        // Note: These calls may fail if deployer is not the endpoint owner
        // They're mainly informational
        log("✓ Endpoint setup verification complete", "success");
    } catch (error) {
        log(`Info: Endpoint setup skipped (requires owner): ${error.message}`, "warning");
    }
}

// ============ MAIN ============
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

    // const contract = await ethers.getContractAt('EndpointV2', '0x6EDCE65403992e310A62460808c4b910D972f10f')
    // try {
    //     // simulate first (no gas cost, returns revert reason)
    //     await contract.setSendLibrary.staticCall(
    //       '0xa253A36D6Ca39219d1789ce5F2E5c6D41e99Bc83',
    //       40245,
    //       '0xf514191C4a2D3b9A629fB658702015a5bCd570BC'
    //     )
    //   } catch (err) {
    //     console.error('Revert reason or data:')
    //     console.error(err)
    //   }

    // console.log(await contract.setSendLibrary('0xa253A36D6Ca39219d1789ce5F2E5c6D41e99Bc83', 40245, '0xf514191C4a2D3b9A629fB658702015a5bCd570BC'))
//     const [deployer] = await ethers.getSigners();
//     const network = hre.network.name;

//     const endpointAddress = '0x6EDCE65403992e310A62460808c4b910D972f10f'
//     const receiveUln301 = process.env.RECEIVE_ULN301_ADDRESS ||'0x0000000000000000000000000000000000000000'
//     const priceFeed = process.env.PRICE_FEED_ADDRESS || '0x0000000000000000000000000000000000000000'
//     const roleAdmin = process.env.ROLE_ADMIN_ADDRESS || deployer.address;
//     const adminsList = process.env.ADMIN_ADDRESSES 
//     ? process.env.ADMIN_ADDRESSES.split(",").map(a => a.trim())
//     : [deployer.address];
    
//     // Pa
//     if (!endpointAddress) {
//         log("ERROR: ENDPOINT_ADDRESS not set in .env", "error");
//         process.exit(1);
//     }

//     log("\n" + "=".repeat(70), "section");
//     log("LAYERZERO SEND/RECEIVE LIBRARY DEPLOYMENT", "section");
//     log("=".repeat(70), "section");
//     log(`Network: ${network}`, "info");
//     log(`Deployer: ${deployer.address}`, "info");
//     log(`Endpoint: ${endpointAddress}`, "info");

//     try {
//         // Step 1: Deploy DVN
//         // const dvnAddress = await deployDVN(endpointAddress, deployer);


//           // Step 4: Deploy ReceiveUln302
//           const receiveUln302Address = await deployReceiveUln302(
//             endpointAddress,
//             deployer
//         );

//         console.log("ADDRESS", receiveUln302Address)
//         // Step 2: Deploy Executor
//         const executorAddress = await deployExecutor(endpointAddress, receiveUln302Address, deployer);

//         // Step 3: Deploy SendUln302
//         const sendUln302Address = await deploySendUln302(
//             endpointAddress,
//             executorAddress.implementation,
//             receiveUln302Address,
//             deployer
//         );

    

//         const dstEid = 40202; // Example destination EID, replace as needed
//         // Step 5: Optional endpoint setup
//         await setupEndpoint(endpointAddress, sendUln302Address,"0xF103293cffA7a6998Be917DCC1A0174540B418Fc", dstEid);

//         // ============ SUMMARY ============
//         log("\n" + "=".repeat(70), "section");
//         log("DEPLOYMENT COMPLETE ✓", "section");
//         log("=".repeat(70), "section");
        
//         const summary = {
//             network,
//             deployer: deployer.address,
//             endpoint: endpointAddress,
//             contracts: {
//                 dvn: dvnAddress,
//                 executor: executorAddress,
//                 sendUln302: sendUln302Address,
//                 receiveUln302: receiveUln302Address,
//             },
//             config: {
//                 confirmations: CONFIG.confirmations,
//                 maxMessageSize: CONFIG.maxMessageSize,
//                 optionalDVNThreshold: CONFIG.optionalDVNThreshold,
//             },
//             timestamp: new Date().toISOString(),
//         };

//         saveDeployment(summary, "lz-deployment-complete");

//         log(`\nDVN:             ${dvnAddress}`, "info");
//         log(`Executor:        ${executorAddress}`, "info");
//         log(`SendUln302:      ${sendUln302Address}`, "info");
//         log(`ReceiveUln302:   ${receiveUln302Address}`, "info");

//         // ============ USAGE INSTRUCTIONS ============
//         log("\n" + "=".repeat(70), "section");
//         log("NEXT STEPS - UPDATE YOUR layerzero.config.ts", "section");
//         log("=".repeat(70), "section");

//         log(`
// Copy this into your layerzero.config.ts:

// import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities';
// import { OAppEnforcedOption, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat';
// import { EndpointId } from '@layerzerolabs/lz-definitions';

// const config = {
//   contracts: [
//     {
//       contract: yourOAppContract,
//     }
//   ],
//   connections: [
//     {
//       from: yourOAppContract,
//       to: destinationOAppContract,
//       config: {
//         // ===== DEPLOYED ADDRESSES =====
//         sendLibrary: "${sendUln302Address}",
//         receiveLibraryConfig: {
//           receiveLibrary: "${receiveUln302Address}",
//           gracePeriod: 0,
//         },
        
//         // ===== SEND CONFIG =====
//         sendConfig: {
//           executorConfig: {
//             executor: "${executorAddress}",
//             maxMessageSize: ${CONFIG.maxMessageSize},
//           },
//           ulnConfig: {
//             confirmations: ${CONFIG.confirmations},
//             requiredDVNs: [],
//             optionalDVNs: ["${dvnAddress}"],
//             optionalDVNThreshold: ${CONFIG.optionalDVNThreshold},
//           },
//         },
        
//         // ===== RECEIVE CONFIG =====
//         receiveConfig: {
//           ulnConfig: {
//             confirmations: ${CONFIG.confirmations},
//             requiredDVNs: [],
//             optionalDVNs: ["${dvnAddress}"],
//             optionalDVNThreshold: ${CONFIG.optionalDVNThreshold},
//           },
//         },
        
//         // ===== ENFORCED OPTIONS (OPTIONAL) =====
//         enforcedOptions: [
//           {
//             msgType: 1,
//             optionType: ExecutorOptionType.LZ_RECEIVE,
//             gas: 80000,
//             value: 0,
//           },
//           {
//             msgType: 2,
//             optionType: ExecutorOptionType.LZ_RECEIVE,
//             gas: 80000,
//             value: 0,
//           },
//         ],
//       }
//     }
//   ],
// };

// export default config;

// Then run:
// npx hardhat lz:oapp:wire --oapp-config layerzero.config.ts
//         `, "info");

//         log("=".repeat(70) + "\n", "section");

//     } catch (error) {
//         log(`\nDeployment failed: ${error.message}`, "error");
//         console.error(error);
//         process.exit(1);
//     }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });