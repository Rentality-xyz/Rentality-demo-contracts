const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getBatchSize,
  chunk,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapInsuranceInfo } = require('./importMappers');

function mapRequirement(item) {
  const info = item.info || [false, item.price || 0];
  return {
    objectId: item.carId,
    requirement: [info[0] === true || info[0] === 'true', item.price || info[1] || 0],
  };
}

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const batchSize = getBatchSize(50);
  const snapshot = readSnapshot('legacy-insurance.json');
  const { address, contract } = await getTargetContract('InsuranceMain', chainId);

  console.log(`Importing insurance into InsuranceMain ${address}`);

  const requirements = (snapshot.carInsurance || []).map(mapRequirement);
  const userInsurances = (snapshot.guestInsurance || []).map((item) => ({
    user: item.user,
    records: (item.insurances || []).map(mapInsuranceInfo),
  }));
  const tripInsurances = (snapshot.tripInsurance || []).map((item) => ({
    tripId: item.tripId,
    records: (item.insurances || []).map(mapInsuranceInfo),
    paidByBooking: item.price || 0,
    paidToInsurance: item.price || 0,
  }));

  for (const [index, batch] of chunk(requirements, batchSize).entries()) {
    await sendAndWait(
      `insurance requirements batch ${index + 1}`,
      contract.migrationImportInsuranceRequirements(batch)
    );
  }

  for (const [index, batch] of chunk(userInsurances, batchSize).entries()) {
    await sendAndWait(
      `guest insurances batch ${index + 1}`,
      contract.migrationImportUserInsurances(batch)
    );
  }

  for (const [index, batch] of chunk(tripInsurances, batchSize).entries()) {
    await sendAndWait(
      `trip insurances batch ${index + 1}`,
      contract.migrationImportTripInsurances(batch)
    );
  }

  console.log('Legacy insurance import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
