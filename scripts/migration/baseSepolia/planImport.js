const fs = require('fs');
const { requireBaseSepolia, readCurrentAddress, readSnapshot, snapshotPath } = require('./importHelpers');

const SNAPSHOTS = [
  ['legacy-profiles.json', (data) => `${data.totals?.profiles ?? data.profiles?.length ?? 0} profiles`],
  ['legacy-cars.json', (data) => `${data.exportedCars ?? data.cars?.length ?? 0} cars`],
  [
    'legacy-pricing-payments.json',
    (data) => `${data.totals?.knownUsers ?? 0} pricing users, ${data.totals?.tripTaxes ?? 0} trip taxes`,
  ],
  [
    'legacy-insurance.json',
    (data) =>
      `${data.totals?.carInsurance ?? 0} cars, ${data.totals?.tripInsurance ?? 0} trips, ${data.totals?.knownUsers ?? 0} users`,
  ],
  ['legacy-trips.json', (data) => `${data.exportedTrips ?? data.trips?.length ?? 0} trips`],
  [
    'legacy-investments.json',
    (data) => {
      const investments = Array.isArray(data.investments?.[0]) ? data.investments[0] : data.investments || [];
      return `${investments.length} investments`;
    },
  ],
  [
    'legacy-referrals.json',
    (data) => `${data.totals?.knownUsers ?? 0} users, ${data.totals?.carDailyClaimed ?? 0} car daily claims`,
  ],
  ['legacy-validation-report.json', (data) => `status=${data.status}, unavailable=${data.unavailableTotal}`],
];

const TARGET_CONTRACTS = [
  'UserProfileMain',
  'CarMain',
  'PricingMain',
  'PricingMainFacet1',
  'InsuranceMain',
  'TripMain',
  'InvestmentMain',
  'ReferralMain',
  'PaymentMain',
];

async function main() {
  const chainId = await requireBaseSepolia();

  console.log(`Base Sepolia migration import plan for chainId ${chainId}`);
  console.log('');
  console.log('Snapshots:');
  for (const [fileName, describe] of SNAPSHOTS) {
    const filePath = snapshotPath(fileName);
    if (!fs.existsSync(filePath)) {
      console.log(`- ${fileName}: missing`);
      continue;
    }
    const data = readSnapshot(fileName);
    console.log(`- ${fileName}: ${describe(data)}`);
  }

  console.log('');
  console.log('Current target addresses:');
  for (const contractName of TARGET_CONTRACTS) {
    try {
      console.log(`- ${contractName}: ${readCurrentAddress(contractName, chainId)}`);
    } catch (error) {
      console.log(`- ${contractName}: missing (${error.message})`);
    }
  }

  console.log('');
  console.log('Write guard: set CONFIRM_BASE_SEPOLIA_MIGRATION=1 only when running transaction scripts intentionally.');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
