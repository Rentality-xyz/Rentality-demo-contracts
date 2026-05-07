const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getBatchSize,
  chunk,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapReferralUsers, mapReferralConfig } = require('./importMappers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const batchSize = getBatchSize(50);
  const snapshot = readSnapshot('legacy-referrals.json');
  const { address, contract } = await getTargetContract('ReferralMain', chainId);

  const users = mapReferralUsers(snapshot.userReferrals || []);
  const config = mapReferralConfig(snapshot);

  console.log(`Importing referrals into ReferralMain ${address}`);

  await sendAndWait(
    'referral config',
    contract.migrationImportReferralConfig(
      config.rules,
      config.discounts,
      config.tiers,
      config.passed,
      config.tripDiscounts,
      config.carDaily
    )
  );

  for (const [index, batch] of chunk(users, batchSize).entries()) {
    await sendAndWait(
      `referral users batch ${index + 1}`,
      contract.migrationImportReferralUsers(batch)
    );
  }

  console.log('Legacy referrals import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
