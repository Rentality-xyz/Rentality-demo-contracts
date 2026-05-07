# Base Sepolia State Migration Plan

This document describes the safe path for moving existing Base Sepolia data from the legacy Rentality contracts into the
new modular model/gateway architecture.

## Decision

Do not treat the Base Sepolia rollout as a simple proxy upgrade.

The current contracts are not a 1:1 implementation replacement for the legacy Base Sepolia contracts. Several legacy
contracts were split, renamed, merged, or replaced by new model contracts. Because of that, binding the new
implementations to old proxy addresses risks corrupting storage layout or losing access to data.

Use the old Base Sepolia contracts as read-only migration sources, then import the exported state into newly deployed
contracts.

## Sources Of Truth

| Source | Purpose |
| --- | --- |
| `scripts/addressesContractsTestnets.v0_2_0.json` | Current known Base Sepolia legacy addresses, especially `chainId: 84532`. |
| Git commit `7d13cf4^` | Last known source tree before `contracts/rentality_old` was removed. Use it for legacy ABIs and structs. |
| Base Sepolia RPC | Read old on-chain state and event logs. |
| `gateway-84532` subgraph | Secondary source for entity IDs and validation, not the only source of truth. |

## Migration Shape

| Phase | Action | Output |
| --- | --- | --- |
| 1. Inventory | Find every entity that must survive migration. | Entity migration table. |
| 2. Export | Read legacy contracts by old ABI/address and write JSON snapshots. | `migration-data/base-sepolia/*.json`. |
| 3. Deploy | Deploy the new model/gateway contracts on Base Sepolia. | New addresses in address books. |
| 4. Import | Call admin-only migration/import functions on the new contracts. | New contracts populated with legacy state. |
| 5. Validate | Compare old exports, new contract getters, and subgraph results. | Validation report. |
| 6. Finalize | Disable migration functions or upgrade them away. | Migration surface closed. |

## Entity Inventory

| Entity | Legacy Source Candidates | New Target Storage | Export Strategy | Import Requirement |
| --- | --- | --- | --- | --- |
| Cars | `CarGatewayAdapter`, legacy gateway/view functions, events, `gateway-84532` | `AssetBase.assets`, `CarMain.cars`, ERC721 owner/tokenURI, VIN/listing mappings | Prefer `totalSupply()` + `getCarInfoById()`. Use subgraph/events for ID discovery fallback. | Add/import car record preserving `carId`, owner, metadataURI, VIN hash, listing state, location hash. |
| Car delivery prices | `RentalityCarDelivery`, old adapter getters | `CarMain.deliveryPricesByUser`, `defaultDeliveryPrices` | Export default prices and host-specific overrides. | Admin import for default and per-host delivery prices. |
| Trips/bookings | Legacy trip service/query, `RentalityTripsQuery`, events, subgraph | `BookingBase.bookings`, booking indexes, `TripMain.trips`, active booking indexes | Prefer old trip count/getter if available. Use subgraph/events for ID list fallback. | Import booking and trip record preserving IDs, parties, status, dates, payment info, active indexes. |
| Profiles/KYC | `RentalityUserService`, legacy profile runtime | `ProfileBase.profileAccounts`, contacts, consents, roles/KYC state | Export known users from cars/trips/referrals/events, then read profile/KYC data per user. | Import/touch profiles and restore KYC/role flags. |
| Insurance | `RentalityInsurance` | `InsuranceBase.objectIdToInsuranceRequirement`, user/trip insurance info, paid amounts | Export by car IDs, trip IDs, and known user addresses. | Import car requirements, user insurance records, trip insurance records, paid amounts. |
| Pricing/taxes/discounts | `RentalityPaymentService`, `RentalityBaseDiscount`, taxes contracts | `PricingBase` and pricing model state | Export platform fee, default discount, per-host discounts, tax configuration. | Import platform fee, discounts, taxes, and default values. |
| Payments/treasury | `RentalityPaymentService` | `PaymentMain` treasury and payment-related state | Export balances and any persisted payment metadata if needed. | Usually transfer funds separately; import metadata only if persisted. |
| Investments | `RentalityInvestment`, investment pools/NFTs | `InvestmentBase` mappings and related investment contracts | Prefer `getAllInvestments()` and per-investment getters. | Import investment IDs, creator, currency, listed flag, funded amount, car linkage. |
| Referrals | `RentalityReferralProgram` | `ReferralBase` points, hashes, ready-to-claim arrays, history | Export known users from public getters, events, and subgraph-derived user list. | Import points, referral hashes, claim queues, history, daily claim timestamps. |

## Important Constraints

- Solidity mappings are not enumerable. If a legacy contract does not expose all keys, use event logs or the subgraph to
  discover IDs and user addresses.
- Keep old Base Sepolia contracts alive. They are the migration source and the rollback reference.
- Do not wipe or recreate the `gateway-84532` subgraph database as part of state migration.
- Deploying the new subgraph to the same name is allowed only after contract addresses and ABIs are finalized.
- Every import function must be admin-only and must preserve existing IDs where the frontend/subgraph expects stable IDs.
- Migration functions should either be removed in a follow-up upgrade or locked with a one-way `migrationFinalized` flag.

## Next Engineering Tasks

1. Use `docs/BaseSepoliaImportDesign.md` as the phase 2 import contract.
2. Add minimal admin-only import functions to new contracts where normal business methods cannot preserve IDs.
3. Create range-based import scripts for profiles, cars, pricing, insurance, trips, investments, and referrals.
4. Create `scripts/migration/baseSepolia/validateImportedState.js`.
5. Run the import on a fresh Base Sepolia demo deployment.
6. Lock or remove migration functions after validation.

## Recommended Order

1. Cars and host profiles.
2. Pricing, taxes, discounts, and delivery prices.
3. Insurance requirements.
4. Trips/bookings and trip payment metadata.
5. User insurance records.
6. Investments.
7. Referrals.
8. Final validation and subgraph redeploy.

## Base Sepolia Demo Export Status

The demo Base Sepolia export pipeline has been proven with clean validation.

| Snapshot | Result |
| --- | --- |
| `legacy-cars.json` | `204/205` cars exported, `carId=6` skipped because `exists` returned false. |
| `legacy-trips.json` | `648/648` trips exported. |
| `legacy-insurance.json` | `204` cars, `648` trips, `50` users exported. |
| `legacy-investments.json` | `1` investment and `204` car payment-info records exported. |
| `legacy-referrals.json` | `78` users and `204` car daily-claim records exported. |
| `legacy-profiles.json` | `84` users exported. |
| `legacy-pricing-payments.json` | `92` users and `648` trip-tax records exported. |
| `legacy-validation-report.json` | `7/7` snapshots found, `0` unavailable calls. |

Use this as the baseline quality gate before writing import scripts. If a later run produces non-zero unavailable calls,
do not continue to import until the cause is understood.
