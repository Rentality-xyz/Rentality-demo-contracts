const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapCar } = require('./importMappers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const snapshot = readSnapshot('legacy-cars.json');
  const { address, contract } = await getTargetContract('CarMain', chainId);

  console.log(`Importing ${snapshot.cars.length} cars into CarMain ${address}`);

  for (let index = 0; index < snapshot.cars.length; index++) {
    const car = snapshot.cars[index];
    await sendAndWait(
      `car ${index + 1}/${snapshot.cars.length} #${car.carId}`,
      contract.migrationImportCar(mapCar(car))
    );
  }

  console.log('Legacy cars import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
