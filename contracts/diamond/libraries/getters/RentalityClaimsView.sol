// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// library RentalityClaimsView {

// TODO: update after adding claims
//   function calculateClaimValue( uint claimId) public view returns (uint) {
//     Schemas.ClaimV2 memory claim = addresses.claimService.getClaim(claimId);
//     if (claim.status == Schemas.ClaimStatus.Paid || claim.status == Schemas.ClaimStatus.Cancel) return 0;

//     uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);
//     (uint result, , ) = addresses.currencyConverterService.getFromUsdLatest(
//       addresses.tripService.getTrip(claim.tripId).paymentInfo.currencyType,
//       claim.amountInUsdCents + commission
//     );

//     return result;
//   }

//   function validatePayClaim(Schemas.Trip memory trip, Schemas.Claim memory claim, address user) public pure {
//     require((claim.isHostClaims && user == trip.guest) || user == trip.host, 'Guest or host.');
//     require(claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel, 'Wrong Status.');
//   }

  /// @notice Retrieves detailed claim information for a specific claim ID.
  /// @dev This function fetches all relevant data for a claim including trip, car, and user information.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param claimId The ID of the claim to retrieve.
  /// @return A FullClaimInfo structure containing all relevant information about the claim.
//   function getClaim(
//     RentalityContract memory contracts,
//     uint256 claimId
//   ) public view returns (Schemas.FullClaimInfo memory) {
//     RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

//     Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(claimId);
//     Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);
//     Schemas.CarInfo memory car = contracts.carService.getCarInfoById(trip.carId);

//     string memory guestPhoneNumber = contracts.userService.getKYCInfo(trip.guest).mobilePhoneNumber;
//     string memory hostPhoneNumber = contracts.userService.getKYCInfo(trip.host).mobilePhoneNumber;

//     uint valueInCurrency = currencyConverterService.getFromUsd(
//       trip.paymentInfo.currencyType,
//       claim.amountInUsdCents,
//       trip.paymentInfo.currencyRate,
//       trip.paymentInfo.currencyDecimals
//     );

//     return
//       Schemas.FullClaimInfo(
//         claim,
//         trip.host,
//         trip.guest,
//         guestPhoneNumber,
//         hostPhoneNumber,
//         car,
//         valueInCurrency,
//         IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getCarTimeZoneId(car.locationHash),
//          contracts.claimService.getClaimTypeInfo(claim.claimType),
//         contracts.currencyConverterService.getUserCurrency(trip.host).currency
//       );
//   }


    //TODO: update after adding claims

//   function getClaimsBy(
//     RentalityContract memory contracts,
//     bool host,
//     address user
//   ) public view returns (Schemas.FullClaimInfo[] memory) {
//     return host ? getClaimsByHost(contracts, user) : getClaimsByGuest(contracts, user);
//   }

//   /// @notice Retrieves all claims associated with a specific host.
//   /// @dev This function fetches detailed claim information for a given host address.
//   /// @param contracts The Rentality contract instance containing service addresses.
//   /// @param host The address of the host for which to retrieve claims.
//   /// @return An array of FullClaimInfo structures containing detailed information about each claim.
//   function getClaimsByHost(
//     RentalityContract memory contracts,
//     address host
//   ) private view returns (Schemas.FullClaimInfo[] memory) {
//     RentalityUserService userService = UserServiceStorage;
//     RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

//     uint256 arraySize = 0;

//     for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
//       Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);
//       Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);

//       if (trip.host == host) {
//         arraySize++;
//       }
//     }

//     Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
//     uint256 counter = 0;

//     for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
//       Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);
//       Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);

//       if (trip.host == host) {
//         uint valueInEth = _getClaimValueInCurrency(
//           trip.paymentInfo.currencyType,
//           claim.amountInUsdCents,
//           claim,
//           contracts.claimService,
//           currencyConverterService
//         );
//         claimInfos[counter++] = Schemas.FullClaimInfo(
//           claim,
//           host,
//           trip.guest,
//           userService.getKYCInfo(trip.guest).mobilePhoneNumber,
//           userService.getKYCInfo(host).mobilePhoneNumber,
//           contracts.CarTokenStorage.getCarInfoById(trip.carId),
//           valueInEth,
//           IRentalityGeoService(contracts.CarTokenStorage.getGeoServiceAddress()).getCarTimeZoneId(
//             contracts.CarTokenStorage.getCarInfoById(trip.carId).locationHash
//           ),
//           contracts.claimService.getClaimTypeInfo(claim.claimType),
//           contracts.currencyConverterService.getUserCurrency(trip.host).currency
//         );
//       }
//     }

//     return claimInfos;
//   }

//   /// @notice Retrieves all claims associated with a specific guest.
//   /// @dev This function fetches detailed claim information for a given guest address.
//   /// @param contracts The Rentality contract instance containing service addresses.
//   /// @param guest The address of the guest for which to retrieve claims.
//   /// @return An array of FullClaimInfo structures containing detailed information about each claim.
//   function getClaimsByGuest(
//     RentalityContract memory contracts,
//     address guest
//   ) private view returns (Schemas.FullClaimInfo[] memory) {
//     RentalityCarToken CarTokenStorage = contracts.CarTokenStorage;
//     RentalityUserService userService = UserServiceStorage;
//     RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

//     uint256 arraySize = 0;

//     for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
//       Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);

//       if (contracts.tripService.getTrip(claim.tripId).guest == guest) {
//         arraySize++;
//       }
//     }

//     Schemas.FullClaimInfo[] memory claimInfos = new Schemas.FullClaimInfo[](arraySize);
//     uint256 counter = 0;
//     for (uint256 i = 1; i <= contracts.claimService.getClaimsAmount(); i++) {
//       Schemas.ClaimV2 memory claim = contracts.claimService.getClaim(i);
//       Schemas.Trip memory trip = contracts.tripService.getTrip(claim.tripId);
//       if (trip.guest == guest) {

//         claimInfos[counter++] = Schemas.FullClaimInfo(
//           claim,
//           trip.host,
//           guest,
//           userService.getKYCInfo(guest).mobilePhoneNumber,
//           userService.getKYCInfo(trip.host).mobilePhoneNumber,
//           CarTokenStorage.getCarInfoById(trip.carId),
//           _getClaimValueInCurrency(
//           trip.paymentInfo.currencyType,
//           claim.amountInUsdCents,
//           claim,
//           contracts.claimService,
//           currencyConverterService
//         ),
//           IRentalityGeoService(contracts.CarTokenStorage.getGeoServiceAddress()).getCarTimeZoneId(
//             CarTokenStorage.getCarInfoById(trip.carId).locationHash
//           ),
//           contracts.claimService.getClaimTypeInfo(claim.claimType),
//           contracts.currencyConverterService.getUserCurrency(trip.host).currency
//         );
//       }
//     }

//     return claimInfos;
//   }

//   function _getClaimValueInCurrency(
//     address currency,
//     uint amount,
//     Schemas.ClaimV2 memory claim,
//     RentalityClaimService claimService,
//     RentalityCurrencyConverter currencyConverterService
//   ) private view returns (uint) {
//     uint valueInEth = 0;
//     if (claim.status == Schemas.ClaimStatus.Paid) {
//       (int rate, uint8 dec) = claimService.claimIdToCurrencyRate(claim.claimId);
//       if (rate > 0) valueInEth = currencyConverterService.getFromUsd(currency, amount, rate, dec);
//     } else (valueInEth, , ) = currencyConverterService.getFromUsdLatest(currency, amount);
//     return valueInEth;
//   }



//     }