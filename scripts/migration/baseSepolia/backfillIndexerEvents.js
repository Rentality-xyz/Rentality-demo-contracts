const { ethers } = require('hardhat');
const {
  chunk,
  getBatchSize,
  getTargetContract,
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  sendAndWait,
} = require('./importHelpers');

const EventType = Object.freeze({
  Car: 0,
  Trip: 2,
  User: 3,
  Insurance: 4,
  Taxes: 5,
  Discount: 6,
  Delivery: 7,
  Currency: 8,
});

const ObjectStatus = Object.freeze({
  Created: 0,
  AdminDefault: 1,
});

const ZERO_ADDRESS = ethers.ZeroAddress;

function uniqueAddresses(addresses) {
  const seen = new Set();
  const result = [];

  for (const address of addresses.filter(Boolean)) {
    const key = address.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      result.push(address);
    }
  }

  return result;
}

function toEvent(eType, id, objectStatus, from = ZERO_ADDRESS, to = from) {
  return { eType, id, objectStatus, from, to };
}

async function discoverTaxIds(gateway) {
  const maxTaxId = Number(process.env.INDEXER_BACKFILL_MAX_TAX_ID || 100);
  const taxIds = [];

  for (let id = 0; id <= maxTaxId; id += 1) {
    try {
      const taxesInfo = await gateway.getTaxesInfoById(id);
      if (taxesInfo.location && taxesInfo.location.length > 0) {
        taxIds.push(id);
      }
    } catch (_) {
      // Missing tax ids are expected because ids are assigned by the pricing model.
    }
  }

  return taxIds;
}

async function emitInBatches(notificationService, label, events, defaultBatchSize = 25) {
  if (events.length === 0) {
    console.log(`${label}: no events`);
    return;
  }

  const batches = chunk(events, getBatchSize(defaultBatchSize));
  for (let index = 0; index < batches.length; index += 1) {
    await sendAndWait(`${label} batch ${index + 1}/${batches.length}`, notificationService.emitAll(batches[index]));
  }
}

async function main() {
  const chainId = await requireBaseSepolia();
  requireConfirmedWrite();

  if (process.env.CONFIRM_INDEXER_BACKFILL !== '1') {
    throw new Error('Refusing to emit indexer backfill events. Set CONFIRM_INDEXER_BACKFILL=1.');
  }

  const { address: notificationAddress, contract: notificationService } = await getTargetContract(
    'RentalityNotificationService',
    chainId
  );
  const { contract: gateway } = await getTargetContract('RentalityGateway', chainId, 'IGatewaySurface');

  const profiles = readSnapshot('legacy-profiles.json').profiles || [];
  const cars = readSnapshot('legacy-cars.json').cars || [];
  const trips = readSnapshot('legacy-trips.json').trips || [];
  const pricingPayments = readSnapshot('legacy-pricing-payments.json');
  const insurance = readSnapshot('legacy-insurance.json');

  const profileUsers = uniqueAddresses(profiles.map((profile) => profile.user));
  const discountUsers = uniqueAddresses((pricingPayments.userDiscounts || []).map((item) => item.user));
  const deliveryUsers = uniqueAddresses((pricingPayments.deliveryPrices || []).map((item) => item.user));
  const insuranceUsers = uniqueAddresses((insurance.guestInsurance || []).map((item) => item.user));

  console.log(`Backfilling indexer events through RentalityNotificationService ${notificationAddress}`);
  console.log(
    [
      `profiles=${profileUsers.length}`,
      `cars=${cars.length}`,
      `trips=${trips.length}`,
      `discountUsers=${discountUsers.length}`,
      `deliveryUsers=${deliveryUsers.length}`,
      `insuranceUsers=${insuranceUsers.length}`,
    ].join(', ')
  );

  const defaultEvents = [
    toEvent(EventType.Currency, 0, ObjectStatus.AdminDefault),
    toEvent(EventType.Delivery, 0, ObjectStatus.AdminDefault),
    toEvent(EventType.Discount, 0, ObjectStatus.AdminDefault),
  ];

  const taxIds = await discoverTaxIds(gateway);
  console.log(`Discovered ${taxIds.length} tax ids: ${taxIds.join(', ')}`);
  const taxEvents = taxIds.map((id) => toEvent(EventType.Taxes, id, ObjectStatus.Created));

  const userEvents = profileUsers.map((user) => toEvent(EventType.User, 0, ObjectStatus.Created, user));
  const discountEvents = discountUsers.map((user) => toEvent(EventType.Discount, 0, ObjectStatus.Created, user));
  const deliveryEvents = deliveryUsers.map((user) => toEvent(EventType.Delivery, 0, ObjectStatus.Created, user));
  const insuranceEvents = insuranceUsers.map((user) => toEvent(EventType.Insurance, 0, ObjectStatus.Created, user));
  const carEvents = cars.map((car) => toEvent(EventType.Car, car.carId, ObjectStatus.Created));
  const tripEvents = trips.map((tripRecord) => toEvent(EventType.Trip, tripRecord.trip?.[0] ?? tripRecord.tripId, ObjectStatus.Created));

  await emitInBatches(notificationService, 'defaults', defaultEvents, 25);
  await emitInBatches(notificationService, 'taxes', taxEvents, 25);
  await emitInBatches(notificationService, 'users', userEvents, 25);
  await emitInBatches(notificationService, 'discounts', discountEvents, 25);
  await emitInBatches(notificationService, 'delivery prices', deliveryEvents, 25);
  await emitInBatches(notificationService, 'guest insurances', insuranceEvents, 25);
  await emitInBatches(notificationService, 'cars', carEvents, 25);
  await emitInBatches(notificationService, 'trips', tripEvents, 25);

  console.log('Indexer backfill events emitted.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
