const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapInvestment } = require('./importMappers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const investmentsSnapshot = readSnapshot('legacy-investments.json');
  const carsSnapshot = readSnapshot('legacy-cars.json');
  const { address, contract } = await getTargetContract('InvestmentMain', chainId, 'InvestmentMainMigration');

  const vinToCarId = new Map(carsSnapshot.cars.map((car) => [car.carInfo[1], car.carId]));
  const carPaymentInfoByCarId = new Map(
    (investmentsSnapshot.carPaymentInfo || []).map((item) => [Number(item.carId), item.paymentInfo])
  );
  const investments = Array.isArray(investmentsSnapshot.investments?.[0])
    ? investmentsSnapshot.investments[0]
    : investmentsSnapshot.investments || [];

  console.log(`Importing ${investments.length} investments into InvestmentMain ${address}`);

  for (let index = 0; index < investments.length; index++) {
    const investment = mapInvestment(investments[index], vinToCarId, carPaymentInfoByCarId);
    await sendAndWait(
      `investment ${index + 1}/${investments.length} #${investment.investmentId}`,
      contract.migrationImportInvestment(investment)
    );
  }

  console.log('Legacy investments import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
