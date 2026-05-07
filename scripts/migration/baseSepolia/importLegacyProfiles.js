const {
  readSnapshot,
  requireBaseSepolia,
  requireConfirmedWrite,
  getTargetContract,
  sendAndWait,
} = require('./importHelpers');
const { mapProfile, mapProfileRoles } = require('./importMappers');

async function main() {
  requireConfirmedWrite();
  const chainId = await requireBaseSepolia();
  const snapshot = readSnapshot('legacy-profiles.json');
  const platformUsers = new Set((snapshot.global?.platformUsers || []).map((user) => user.toLowerCase()));
  const { address, contract } = await getTargetContract('UserProfileMain', chainId, 'UserProfileMainMigration');

  console.log(`Importing ${snapshot.profiles.length} profiles into UserProfileMain ${address}`);

  for (let index = 0; index < snapshot.profiles.length; index++) {
    const profile = snapshot.profiles[index];
    const item = mapProfile(profile, platformUsers);
    await sendAndWait(
      `profile ${index + 1}/${snapshot.profiles.length} ${profile.user}`,
      contract.migrationImportProfile(item)
    );

    const roles = mapProfileRoles(profile);
    for (const role of roles) {
      await sendAndWait(
        `profile role ${profile.user} -> ${role}`,
        contract.migrationGrantRole(profile.user, role)
      );
    }
  }

  console.log('Legacy profiles import finished');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
