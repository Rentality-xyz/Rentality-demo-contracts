[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://vshymanskyy.github.io/StandWithUkraine)

## Rentality | contract

[![Rentality][rentality-image]][rentality-url]

> The first blockchain car rental powered by WEB 3.0

[Learn More](#learn-more) • [Prerequisites](#prerequisites) • [Testing](#testing) • [Deployment](#deployment) • [Update Proxy](#update-proxy) • [Available Scripts](#available-scripts) • [Local Deployment](#local-deployment)

## Learn More <a name="learn-more"></a>

The `RentalityGateway` contract serves as the main gateway for various services within the Rentality platform. Below are the key features and functionalities provided by this contract:

- **Car Operations:**

  - Adds, updates, and retrieves information about cars.
  - Manages car tokens and metadata.
  - Burns (disables) cars.

- **Trip Management:**

  - Creates, approves, and rejects trip requests.
  - Handles check-in and check-out processes for both hosts and guests.
  - Finishes trips.

- **Claim Management:**

  - Creates, pays, rejects, and updates claims.
  - Retrieves detailed information about claims associated with trips.

- **KYC (Know Your Customer) Information:**

  - Sets and retrieves KYC information for users.

- **Chat Information:**

  - Retrieves chat information for hosts and guests.

- **Automation:**
  - Calls outdated automations and takes corresponding actions based on their types.

The `RentalityGateway` contract acts as the central point for coordinating interactions within the Rentality platform, providing robust functionality for managing cars, trips, claims, KYC information, and more.

## Prerequisites <a name="prerequisites"></a>

Before you begin, ensure you have met the following requirements:

- [Node.js](https://nodejs.org/) installed on your system.
- [npm](https://www.npmjs.com/) (Node Package Manager) installed with Node.js.

## Testing <a name="testing"></a>

To test smart contracts, make sure you are using the localhost network in `hardhat.config.js` and run the following
tasks:

```shell
npm install
npx hardhat node
npx hardhat test
```

## Deployment <a name="deployment"></a>

Choose the network in `hardhat.config.js` and run following command:

```shell
npm install
npx hardhat run scripts/deploy_x_Rentality_full.js
```

If necessary, the console will prompt you to install any needed contracts. Respond to the prompt by entering `y` for yes
or `n` for no accordingly.

## Update Proxy <a name="update-proxy"></a>

**Before proceeding**:

with the update in the working directory,
ensure that a `<network_name>.json` file exists in the `.openzeppelin` folder.
If it doesn't exist, you'll need to use one of the scripts from the `recoveryProxy` folder,
depending on the presence of libraries in the smart contract.
Additionally, ensure that the addressesContractsTestnets.json file contains the deployed proxy address.

**Example:**

To recover manifest file for `RentalityTripService`, that use both libs, run:

```shell
npx hardhat run scripts/recoverProxy/recover_withLibs.js
```

Then, enter `RentalityTripService`. This will create the file <network_name>.json or add to the existing RentalityTripService proxy data.

**Notice:**

For best practices, recovering manifest files is better done from the last updated version of the contract.
In the case of updating from v1 to v2, it's recommended to run:

```shell
npx hardhat run scripts/recoverProxy/recover_withLibs.js
```

on smart contract v1.

This steps allows the upgrade mechanism to check the storage compatibility of both versions.
Additional example of [forceImport] [forceImport-example-url] feature usage.

**Main steps:**
of updating proxy contracts:

Choose the network in `hardhat.config.js` and run following command:

```shell
npm install
npx hardhat run scripts/update_RentalityProxy.js
```

After the question `Enter the contract name to update`, enter the corresponding contract name and press Enter.

## Available Scripts <a name="available-scripts"></a>

In the project directory, you can run:

```shell
npx hardhat help
npx hardhat test
npx hardhat compile
npx hardhat docgen
npm run format
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy_x_Rentality_full.js
npx hardhat run scripts/update_RentalityProxy.js
```

## Local Deployment <a name="local-deployment"></a>

1.**Make sure you went through [Prerequisites](#prerequisites)**

2.**Install Ganache (Optional but Recommended):**

- Install Ganache as a local blockchain node from [here][ganache-url].

- Create a blockchain workspace.

  3.**Download repository from `feature/v0_16` branch**

  4.**Configure Environment Variables:**

- In the "demo-rentality-web3-contracts" project, add a file named .env with the following values:
  `URL_LOCALHOST_GANACHE="http://127.0.0.1:7545"`
  `GANACHE_PRIVATE_KEY="Your-Ganache-Private-Key"`

  5.**Run commands:**

```shell
npm install
npx hardhat compile
```

make sure that Ganache is open and Workspace is created and launched.
Run following:

```shell
npx hardhat run scripts/deploy_x_Rentality_full.js
```

If necessary, the console will prompt you to install any needed contracts. Respond to the prompt by entering `y` for yes
or `n` for no accordingly.

<!-- Markdown link & img dfn's -->

[rentality-image]: https://demotest.rentality.xyz/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fred-generic-sport-ca.ac590a69.png&w=1920&q=75
[rentality-url]: https://demotest.rentality.xyz/
[ganache-url]: https://archive.trufflesuite.com/ganache/
[forceImport-example-url]: https://github.com/ericglau/hardhat-deployer/blob/master/scripts/upgrade.js


local development:
run node: npx hardhat node
run tests: npx hardhat test
deploy: npx hardhat run --network network_name scripts/...

update npx hardhat run --network network_name scripts/update_RentalityProxy.js
after question: contractName, 'enter'

To update RentalityGatewat ALWAYS run: npx hardhat run --network network_name scripts/update_RentalityGateway.js
