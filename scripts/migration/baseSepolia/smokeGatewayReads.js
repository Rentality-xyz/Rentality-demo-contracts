const {
  readSnapshot,
  requireBaseSepolia,
  readCurrentAddress,
} = require('./importHelpers');
const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');

function assertTruthy(label, value) {
  if (!value) {
    throw new Error(`${label}: expected truthy value`);
  }
}

function assertEqual(label, actual, expected) {
  const actualText = actual?.toString?.() ?? String(actual);
  const expectedText = expected?.toString?.() ?? String(expected);
  if (actualText !== expectedText) {
    throw new Error(`${label}: expected ${expectedText}, got ${actualText}`);
  }
}

function field(value, name, index, fallback = undefined) {
  if (value && value[name] !== undefined) {
    return value[name];
  }
  return Array.isArray(value) && value[index] !== undefined ? value[index] : fallback;
}

async function main() {
  const chainId = await requireBaseSepolia();
  const [signer] = await ethers.getSigners();
  const address = readCurrentAddress('RentalityGateway', chainId);
  const featureName = process.env.FEATURE_NAME;
  const abiDir = featureName
    ? path.join(process.cwd(), 'src', 'abis', featureName)
    : path.join(process.cwd(), 'src', 'abis');
  const gatewayAbiJson = JSON.parse(fs.readFileSync(path.join(abiDir, 'RentalityGateway.v0_2_0.abi.json'), 'utf8'));
  const contract = new ethers.Contract(address, gatewayAbiJson.abi || gatewayAbiJson, signer);
  const profiles = readSnapshot('legacy-profiles.json').profiles || [];
  const cars = readSnapshot('legacy-cars.json').cars || [];
  const trips = readSnapshot('legacy-trips.json').trips || [];
  const investmentsSnapshot = readSnapshot('legacy-investments.json');
  const investments = Array.isArray(investmentsSnapshot.investments?.[0])
    ? investmentsSnapshot.investments[0]
    : investmentsSnapshot.investments || [];

  console.log(`Gateway smoke reads on ${address}`);

  const maxCarId = cars.reduce((max, car) => Math.max(max, Number(car.carId)), 0);
  const totalCarsAmount = await contract.getTotalCarsAmount();
  assertEqual('gateway total cars amount', totalCarsAmount, maxCarId);
  console.log(`gateway cars amount ok: ${totalCarsAmount}`);

  const firstCar = cars[0];
  const firstCarInfo = await contract.getCarInfoById(firstCar.carId);
  const carInfo = field(firstCarInfo, 'carInfo', 0, firstCarInfo);
  const asset = field(carInfo, 'asset', 0, []);
  const gatewayCar = field(carInfo, 'car', 1, []);
  assertEqual(`gateway car ${firstCar.carId} id`, field(asset, 'id', 0), firstCar.carId);
  assertEqual(`gateway car ${firstCar.carId} brand`, field(gatewayCar, 'brand', 2), firstCar.carInfo[4]);
  console.log(`gateway car read ok: #${firstCar.carId}`);

  const firstTrip = trips[0].trip;
  const firstTripId = firstTrip[0];
  const gatewayTrip = await contract.getTrip(firstTripId);
  const trip = field(gatewayTrip, 'trip', 0, gatewayTrip);
  const booking = field(trip, 'booking', 0, []);
  assertEqual(`gateway trip ${firstTripId} id`, field(booking, 'id', 0), firstTripId);
  assertEqual(`gateway trip ${firstTripId} carId`, field(booking, 'resourceId', 1), firstTrip[1]);
  console.log(`gateway trip read ok: #${firstTripId}`);

  const gatewayInvestments = await contract.getAllInvestments();
  const listedInvestments = investments.filter((investment) => investment[21] === true || investment[21] === 'true');
  assertEqual('gateway listed investments count', gatewayInvestments.length, listedInvestments.length);
  console.log(`gateway investments read ok: ${gatewayInvestments.length}`);

  const firstProfile = profiles[0];
  const fullKyc = await contract.getUserFullKYCInfo(firstProfile.user);
  const kyc = field(fullKyc, 'kyc', 0, []);
  const expectedKyc = firstProfile.kycInfo || field(firstProfile.myFullKYCInfo, undefined, 0, []);
  assertEqual(`gateway profile ${firstProfile.user} name`, field(kyc, 'name', 0), expectedKyc[0]);
  assertTruthy(`gateway profile ${firstProfile.user}`, kyc);
  console.log(`gateway profile read ok: ${firstProfile.user}`);

  console.log('Gateway smoke reads finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
