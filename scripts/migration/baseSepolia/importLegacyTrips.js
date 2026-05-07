const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapTrip } = require('./importMappers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const snapshot = readSnapshot('legacy-trips.json');
  const { address, contract } = await getTargetContract('TripMain', chainId, 'TripMainMigration');

  console.log(`Importing ${snapshot.trips.length} trips into TripMain ${address}`);

  for (let index = 0; index < snapshot.trips.length; index++) {
    const trip = snapshot.trips[index];
    await sendAndWait(
      `trip ${index + 1}/${snapshot.trips.length} #${trip.tripId}`,
      contract.migrationImportTrip(mapTrip(trip))
    );
  }

  console.log('Legacy trips import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
