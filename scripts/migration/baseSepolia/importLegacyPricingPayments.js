const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getBatchSize,
  chunk,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapTaxValue } = require('./importMappers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const batchSize = getBatchSize(50);
  const snapshot = readSnapshot('legacy-pricing-payments.json');
  const { address: pricingAddress, contract: pricing } = await getTargetContract('PricingMainFacet1', chainId);
  const { address: carAddress, contract: carMain } = await getTargetContract('CarMain', chainId);

  const currentTaxesId = await pricing.taxesId();
  const currentDefaultTax = await pricing.defaultTax();
  const defaultDiscount = snapshot.baseDefaultDiscount || [0, 0, 0, false];
  const userDiscounts = (snapshot.userDiscounts || []).map((item) => ({
    user: item.user,
    discount: item.parsedDiscount || item.paymentDiscount || [0, 0, 0, false],
  }));
  const tripTaxes = (snapshot.tripTaxes || []).map((item) => ({
    tripId: item.tripId,
    taxes: (item.tripTaxesDTO || item.tripTaxesFromPayment || []).map(mapTaxValue),
  }));

  console.log(`Importing pricing into PricingMainFacet1 ${pricingAddress}`);
  console.log(`Importing delivery prices into CarMain ${carAddress}`);

  await sendAndWait(
    'pricing default discount/current tax ids',
    pricing.migrationImportPricing(defaultDiscount, currentTaxesId, currentDefaultTax, [], [], [])
  );

  for (const [index, batch] of chunk(userDiscounts, batchSize).entries()) {
    await sendAndWait(
      `pricing user discounts batch ${index + 1}`,
      pricing.migrationImportPricing(defaultDiscount, currentTaxesId, currentDefaultTax, batch, [], [])
    );
  }

  for (const [index, batch] of chunk(tripTaxes, batchSize).entries()) {
    await sendAndWait(
      `pricing trip taxes batch ${index + 1}`,
      pricing.migrationImportPricing(defaultDiscount, currentTaxesId, currentDefaultTax, [], [], batch)
    );
  }

  for (let index = 0; index < (snapshot.deliveryPrices || []).length; index++) {
    const item = snapshot.deliveryPrices[index];
    await sendAndWait(
      `delivery prices ${index + 1}/${snapshot.deliveryPrices.length} ${item.user}`,
      carMain.migrationSetUserDeliveryPrices(item.user, item.deliveryPrices)
    );
  }

  console.log('Legacy pricing/payments import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
