const {
  readSnapshot,
  requireBaseSepolia,
  getTargetContract,
} = require('./importHelpers');
const {
  mapInvestment,
  mapReferralUsers,
} = require('./importMappers');

function assertEqual(label, actual, expected) {
  const actualText = actual?.toString?.() ?? String(actual);
  const expectedText = expected?.toString?.() ?? String(expected);
  if (actualText !== expectedText) {
    throw new Error(`${label}: expected ${expectedText}, got ${actualText}`);
  }
}

function assertAddress(label, actual, expected) {
  if (actual.toLowerCase() !== expected.toLowerCase()) {
    throw new Error(`${label}: expected ${expected}, got ${actual}`);
  }
}

function valueAt(value, index, fallback = undefined) {
  return Array.isArray(value) && value[index] !== undefined ? value[index] : fallback;
}

function field(value, name, index, fallback = undefined) {
  if (value && value[name] !== undefined) {
    return value[name];
  }
  return valueAt(value, index, fallback);
}

async function validateProfiles(chainId) {
  const snapshot = readSnapshot('legacy-profiles.json');
  const { contract } = await getTargetContract('UserProfileMain', chainId);
  const profiles = snapshot.profiles || [];

  for (const profile of profiles) {
    const user = profile.user;
    const expectedKyc = profile.kycInfo || valueAt(profile.myFullKYCInfo, 0, []);
    const kyc = await contract.getKYCProfile(user);
    assertEqual(`profile ${user} name`, field(kyc, 'name', 0), valueAt(expectedKyc, 0, ''));
    assertEqual(`profile ${user} surname`, field(kyc, 'surname', 1), valueAt(expectedKyc, 1, ''));
  }

  console.log(`profiles ok: ${profiles.length}`);
}

async function validateCars(chainId) {
  const snapshot = readSnapshot('legacy-cars.json');
  const { contract } = await getTargetContract('CarMain', chainId);
  const cars = snapshot.cars || [];
  const maxCarId = cars.reduce((max, car) => Math.max(max, Number(car.carId)), 0);

  assertEqual('CarMain totalSupply/max imported id', await contract.totalSupply(), maxCarId);

  for (const car of cars) {
    const carId = Number(car.carId);
    const carInfo = car.carInfo;
    const data = await contract.getCarData(carId);
    assertEqual(`car ${carId} vin`, field(data, 'carVinNumber', 0), valueAt(carInfo, 1, ''));
    assertEqual(`car ${carId} brand`, field(data, 'brand', 2), valueAt(carInfo, 4, ''));
    assertEqual(`car ${carId} model`, field(data, 'model', 3), valueAt(carInfo, 5, ''));
  }

  console.log(`cars ok: ${cars.length}, max id ${maxCarId}`);
}

async function validateTrips(chainId) {
  const snapshot = readSnapshot('legacy-trips.json');
  const { contract } = await getTargetContract('TripMain', chainId);
  const trips = snapshot.trips || [];

  assertEqual('TripMain totalSupply', await contract.totalSupply(), trips.length);

  for (const tripRecord of trips) {
    const expected = tripRecord.trip;
    const tripId = Number(valueAt(expected, 0, 0));
    const trip = await contract.getTrip(tripId);
    const booking = field(trip, 'booking', 0, []);
    assertEqual(`trip ${tripId} id`, field(booking, 'id', 0), tripId);
    assertEqual(`trip ${tripId} carId`, field(booking, 'resourceId', 1), valueAt(expected, 1, 0));
    assertAddress(`trip ${tripId} guest`, field(booking, 'customer', 2), valueAt(expected, 3));
    assertAddress(`trip ${tripId} host`, field(booking, 'provider', 3), valueAt(expected, 4));
  }

  console.log(`trips ok: ${trips.length}`);
}

async function validateInvestments(chainId) {
  const snapshot = readSnapshot('legacy-investments.json');
  const carsSnapshot = readSnapshot('legacy-cars.json');
  const { contract } = await getTargetContract('InvestmentMain', chainId);
  const vinToCarId = new Map(carsSnapshot.cars.map((car) => [car.carInfo[1], car.carId]));
  const carPaymentInfoByCarId = new Map(
    (snapshot.carPaymentInfo || []).map((item) => [Number(item.carId), item.paymentInfo])
  );
  const investments = Array.isArray(snapshot.investments?.[0])
    ? snapshot.investments[0]
    : snapshot.investments || [];

  assertEqual('InvestmentMain count', await contract.getInvestmentCount(), investments.length);

  for (const legacy of investments) {
    const mapped = mapInvestment(legacy, vinToCarId, carPaymentInfoByCarId);
    const funding = await contract.getFundingInfo(mapped.investmentId);
    assertEqual(`investment ${mapped.investmentId} target`, field(funding, 'targetAmount', 0), mapped.investment[1]);
    assertEqual(`investment ${mapped.investmentId} funded`, field(funding, 'fundedAmount', 1), mapped.fundedAmount);
    assertAddress(`investment ${mapped.investmentId} currency`, field(funding, 'currency', 2), mapped.currency);
    assertEqual(`investment ${mapped.investmentId} listed`, field(funding, 'listed', 3), mapped.listed);
  }

  console.log(`investments ok: ${investments.length}`);
}

async function validateReferrals(chainId) {
  const snapshot = readSnapshot('legacy-referrals.json');
  const { contract } = await getTargetContract('ReferralMain', chainId);
  const users = mapReferralUsers(snapshot.userReferrals || []);

  for (const user of users) {
    assertEqual(`referral ${user.user} points`, await contract.getPointsBalance(user.user), user.points);
    const info = await contract.getMyReferralInfo(user.user);
    assertEqual(`referral ${user.user} hash`, field(info, 'myHash', 0), user.referralHash);
    assertEqual(`referral ${user.user} saved hash`, field(info, 'savedHash', 1), user.savedHash);
  }

  console.log(`referrals ok: ${users.length}`);
}

async function main() {
  const chainId = await requireBaseSepolia();

  console.log('Validating imported Base Sepolia data...');
  await validateProfiles(chainId);
  await validateCars(chainId);
  await validateTrips(chainId);
  await validateInvestments(chainId);
  await validateReferrals(chainId);
  console.log('Imported data validation finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
