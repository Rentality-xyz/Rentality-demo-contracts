const fs = require("fs");
const path = require("path");
const { ethers } = require("hardhat");
const { spawn } = require("child_process");

const CONFIG_PATH = path.join(__dirname, "deploy.json");

function loadConfig() {
  return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
}

function saveConfig(data) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(data, null, 2));
}


function runScript(script, args) {
    return new Promise((resolve, reject) => {
      const env = { ...process.env };
  
      if (args.length > 0) {
        env.CONTRACT_ARG = args.join(" ");
      }
  
      const network = process.env.HARDHAT_NETWORK;
      const procArgs = ["hardhat", "run", script];
  
      if (network) {
        procArgs.push("--network", network);
      }
  
      const proc = spawn("npx", procArgs, { stdio: "inherit", shell: true, env });
  
      proc.on("close", (code) => {
        if (process.env.CONTRACT_ARG) delete process.env.CONTRACT_ARG;
  
        if (code === 0) resolve();
        else reject(new Error(`Exit code ${code}`));
      });
    });
  }
  
async function main() {
  console.log("🚀 Start update runner\n");

  const [deployer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(deployer.address);
  const chainId = (await deployer.provider.getNetwork()).chainId;

  console.log(`Deployer: ${deployer.address}`);
  console.log(`Balance : ${balance}`);
  console.log(`ChainId : ${chainId}\n`);

  const config = loadConfig();
  const target = config.find(b => Number(b.chainId) === Number(chainId));

  if (!target) throw new Error(`No config for chainId ${chainId}`);

  console.log(`Using config: ${target.name}\n`);

  while (target.updateScripts.length) {
    const raw = target.updateScripts[0];
    const parts = raw.split(" ");
    let script = parts[0];
    const args = parts.slice(1);

    script = path.normalize(script);

    console.log(`▶ Running: ${raw}`);

    try {
      await runScript(script, args);

      console.log(`✅ Success: ${raw}\n`);

      target.updateScripts.shift();
      saveConfig(config);
    } catch (err) {
        console.log(`\x1b[31m❌ Failed: ${raw}\x1b[0m`);
        console.log(`\x1b[31m${err}\x1b[0m\n`);
      break;
    }
  }

  if (!target.updateScripts.length) {
    console.log("🎉 All scripts executed");
  } else {
    console.log("⚠ Remaining scripts:");
    console.log(target.updateScripts);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
