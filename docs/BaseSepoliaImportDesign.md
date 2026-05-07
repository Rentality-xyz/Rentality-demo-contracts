# Base Sepolia Import Design

This document defines phase 2 of the Base Sepolia migration: importing clean legacy snapshots into the new modular
contracts.

The export phase is complete only when `legacy-validation-report.json` has `unavailableTotal: 0`.

## Scope

The import phase must preserve legacy IDs and cross-entity links. Normal business methods such as `createCar`,
`createTrip`, `saveInsurance`, or `claimPoints` are not sufficient because they create new IDs, use current
`block.timestamp`, recalculate values, or require frontend/user-side preconditions.

Use dedicated owner/admin migration functions and remove or lock them after validation.

## Import Principles

| Principle | Requirement |
| --- | --- |
| Preserve IDs | `carId`, `tripId`, `investmentId`, referral hashes, and known user addresses must stay stable. |
| Preserve timestamps | Legacy create/update/status timestamps must be written from snapshots, not replaced with `block.timestamp`. |
| Rebuild indexes | Any enumerable array/index used by getters must be rebuilt during import. |
| Avoid recalculation | Imported taxes, discounts, payments, and insurance data should be copied, not recalculated. |
| Batch safely | Import scripts should support ranges and resume markers, because Base Sepolia transactions can fail or time out. |
| Close surface | Migration functions must be guarded by owner/admin and disabled with `migrationFinalized` or removed by upgrade. |

## Proposed Import Surface

| Snapshot | Target | Proposed Function | Critical State |
| --- | --- | --- | --- |
| `legacy-profiles.json` | `contracts/models/profile/UserProfileMainMigration.sol` | Migration-only implementation, then upgrade back to production | KYC, additional info, contact flags, push tokens, platform user list, roles, user currencies, KYC commission history. |
| `legacy-cars.json` | `CarMain` | `migrationImportCar(CarImport calldata item)` plus delivery helpers | `assets`, `cars`, ERC721 owner/tokenURI, VIN hash, listing moment, `nextAssetId`, delivery prices. |
| `legacy-pricing-payments.json` | `PricingMain` / `PricingMainFacet1` | `migrationImportPricing(PricingImport calldata data)` | Platform fee, default discount, per-user discounts, taxes, trip tax snapshots, default tax. |
| `legacy-insurance.json` | `InsuranceMain` | `migrationImportInsurance(InsuranceImport calldata data)` | Car requirements, user general insurance records, trip insurance records, paid insurance amounts. |
| `legacy-trips.json` | `contracts/models/trip/TripMainMigration.sol` | Migration-only implementation, then upgrade back to production | `bookings`, booking indexes, `trips`, active indexes, transaction info, payment info, completed-by-admin flag, ETH sum. |
| `legacy-investments.json` | `contracts/models/investment/InvestmentMainMigration.sol` | Migration-only implementation, then upgrade back to production | Investment IDs, creator, currency, listed flag, funded amount, car linkage, pool/NFT references. |
| `legacy-referrals.json` | `ReferralMain` | `migrationImportReferrals(ReferralImport calldata data)` | Points, hashes, saved hashes, ready-to-claim queues, histories, passed flags, daily claim timestamps, tiers/program rules. |
| `legacy-pricing-payments.json` | `PaymentMain` | Physical treasury transfer, not storage import | Native/ERC20 treasury balances must be moved by transaction, not by writing mappings. |

## Contract Notes

### `UserProfileMain`

Profiles must be imported before cars and trips so role and KYC checks can be restored for hosts and guests.

Required import state:

- `kycInfos[user]`
- `additionalInfos[user]`
- profile contact flags and push token from profile base storage
- `platformUsers` and `userIsInPlatformList`
- roles exposed through `manageRole`/access control
- `userCurrencies` and `userCurrenciesInitialized`
- `userToKycCommission[user]`

Open design question: if old snapshots include users with only partial profile data, import should still add them to
the platform user list when they are referenced by cars, trips, referrals, insurance, or pricing.

### `CarMain`

`createCar` cannot be used for migration because it increments `nextAssetId`, writes current timestamps, validates
fresh signatures, and creates a new location hash.

Required import state:

- `assets[carId]` with old owner, name, metadata URI, and create time
- ERC721 token minted to the old owner with the old `carId`
- token URI restored
- `cars[carId]`
- `vinHashToAssetId`
- `listingMomentByAssetId`
- `nextAssetId` updated to at least the largest imported car ID
- default and per-host delivery prices

If the old `carId` sequence has holes, keep the holes. In the current demo export, `carId=6` is intentionally absent.

### `TripMain`

`createTrip` cannot be used because it creates a new booking ID and sets status/timestamps from the new flow.

Required import state:

- `bookings[tripId]`
- `nextBookingId` updated to at least the largest imported trip ID
- `resourceIdToBookings`
- `resourceIdToActiveBookings`
- `userToBookings`
- `userToActiveBookings`
- `trips[tripId]`
- `completedByAdmin[tripId]`
- `tripIdToEthSumInTripCreation[tripId]`

Status mapping must be explicit. Do not assume old numeric statuses match the new `TripStatus` enum without a mapping
table and spot checks.

### `PricingMain` And `PricingMainFacet1`

Pricing state is split between `PricingMain` and `PricingMainFacet1`.

Required import state:

- `platformFeeInPPM`
- `defaultDiscount`
- per-user base discounts
- `taxesId`
- `defaultTax`
- tax location hashes and tax values
- `tripIdToTaxes`

Because `tripIdToTaxes` is a private mapping, migration functions should live in `PricingMainFacet1` and be called
through `PricingMain` or directly by an owner script.

### `InsuranceMain`

Insurance migration should copy old records without changing `createdTime` or `createdBy`.

Required import state:

- `objectIdToInsuranceRequirement[carId]`
- `userToInsuranceInfo[user]`
- `bookingIdToInsuranceInfo[tripId]`
- `bookingIdToInsurancePaid[tripId]`
- `tripIdToInsuranceValuePaid[tripId]`, if legacy export proves it is needed

### `InvestmentMain`

This is the riskiest import area.

Required import state:

- `investmentCount`
- `investmentIdToFundedAmount`
- `investmentIdToCreator`
- `investmentIdToCurrency`
- `investmentIdToListed`
- `carIdToInvestmentId`
- `investmentIdToCarInfo`
- `investmentIdToPool`
- `investmentIdToNft`

Open design question: decide whether old pool/NFT addresses are still usable from new contracts. If not, we need a
separate pool/NFT recreation flow and an explicit mapping from legacy investment ID to new pool/NFT address.

### `ReferralMain`

Referral migration should copy points and history directly.

Required import state:

- `addressToPoints`
- `tripIdToDiscount`
- `addressToReadyToClaim`
- `userToReadyToClaimFromHash`
- `userProgramHistory`
- `userToSavedHash`
- `referralHashV2`
- `hashToOwnerV2`
- `selectorToPassedAddress`
- `selectorToPoints`
- `permanentSelectorToPoints`
- `addressToLastDailyClaim`
- `selectorHashToPoints`
- `selectorToDiscounts`
- `tierToPoints`
- `carIdToDailyClaimed`

### `PaymentMain`

`PaymentMain` does not store the exported treasury balance in a mapping. The balance is the actual native/ERC20
balance of the contract address.

Migration requirement:

- verify old treasury balances from `legacy-pricing-payments.json`
- use legacy admin withdrawal or transfer flow to move funds to the new `PaymentMain`
- verify `getTreasuryBalance(currency)` on the new contract after transfer

If old contracts cannot withdraw a balance, this becomes a governance/manual recovery issue rather than a storage
import issue.

## Import Script Shape

Use separate scripts so each phase can be rerun safely. Solidity import functions should import one logical record at a
time when possible; batching belongs in JavaScript to keep implementation bytecode below the EIP-170 contract-size
limit.

For contracts that are already near or above the EIP-170 limit, do not add migration methods to production
implementations. Use a temporary migration-only UUPS implementation with the same storage layout, import state through
that implementation, then upgrade the proxy back to the production implementation.

| Script | Purpose |
| --- | --- |
| `scripts/migration/baseSepolia/importProfiles.js` | Import users, KYC, contacts, roles, currencies. |
| `scripts/migration/baseSepolia/importCars.js` | Import cars and delivery prices. |
| `scripts/migration/baseSepolia/importPricing.js` | Import discounts, taxes, trip tax snapshots. |
| `scripts/migration/baseSepolia/importInsurance.js` | Import car, user, and trip insurance records. |
| `scripts/migration/baseSepolia/importTrips.js` | Import bookings/trips and rebuild indexes. |
| `scripts/migration/baseSepolia/importInvestments.js` | Import investments after cars exist. |
| `scripts/migration/baseSepolia/importReferrals.js` | Import referral points/rules/history. |
| `scripts/migration/baseSepolia/validateImportedState.js` | Compare snapshots with new contract getters. |

Utility scripts already available:

| Script | Purpose |
| --- | --- |
| `npm run migration:import:base-sepolia:plan` | Dry-run inventory of snapshots and target addresses. |
| `$env:MODEL='TripMain'; $env:CONFIRM_BASE_SEPOLIA_MIGRATION='1'; npm run migration:import:base-sepolia:upgrade-to-migration` | Upgrade a supported proxy to its migration-only implementation. |
| `$env:MODEL='TripMain'; $env:CONFIRM_BASE_SEPOLIA_MIGRATION='1'; npm run migration:import:base-sepolia:upgrade-back` | Upgrade a supported proxy back to its production implementation. |

Recommended order:

1. Profiles and roles.
2. Cars and delivery prices.
3. Pricing and trip taxes.
4. Insurance.
5. Trips.
6. Investments.
7. Referrals.
8. Treasury transfer.
9. Subgraph deployment/reindex.
10. Validation and migration lock.

## Phase 2 Next Tasks

1. Add migration structs and guarded import functions to target contracts.
2. Add range-based import scripts that read the existing snapshot JSON files.
3. Add a validator that compares each imported entity against snapshots.
4. Run on a fresh Base Sepolia demo deployment.
5. Lock or remove migration functions after validation.
