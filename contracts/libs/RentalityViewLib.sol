// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Schemas} from '../Schemas.sol';
import {RentalityCarToken} from '../RentalityCarToken.sol';
import {RentalityContract} from '../RentalityGateway.sol';
import {RentalityPromoService} from '../features/RentalityPromo.sol';
import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
import {RentalityUtils} from './RentalityUtils.sol';

library RentalityViewLib {

  function getFilterInfo(
    RentalityContract memory contracts,
    uint64 duration
  ) public view returns (Schemas.FilterInfoDTO memory) {
    uint64 maxCarPrice = 0;
    RentalityCarToken carService = contracts.carService;
    uint minCarYearOfProduction = carService.getCarInfoById(1).yearOfProduction;

    for (uint i = 2; i <= carService.totalSupply(); i++) {
      Schemas.CarInfo memory car = carService.getCarInfoById(i);

      uint64 sumWithDiscount = contracts.paymentService.calculateSumWithDiscount(
        carService.ownerOf(i),
        duration,
        car.pricePerDayInUsdCents
      );
      if (sumWithDiscount > maxCarPrice) maxCarPrice = sumWithDiscount;
      if (car.yearOfProduction < minCarYearOfProduction) minCarYearOfProduction = car.yearOfProduction;
    }
    return Schemas.FilterInfoDTO(maxCarPrice, minCarYearOfProduction);
  }
  function calculateClaimValue(RentalityContract memory addresses, uint claimId) public view returns (uint) {
    Schemas.Claim memory claim = addresses.claimService.getClaim(claimId);
    if (claim.status == Schemas.ClaimStatus.Paid || claim.status == Schemas.ClaimStatus.Cancel) return 0;

    uint commission = addresses.claimService.getPlatformFeeFrom(claim.amountInUsdCents);
    (uint result, , ) = addresses.currencyConverterService.getFromUsdLatest(
      addresses.tripService.getTrip(claim.tripId).paymentInfo.currencyType,
      claim.amountInUsdCents + commission
    );

    return result;
  }

 function validatePayClaim(Schemas.Trip memory trip, Schemas.Claim memory claim) public view {
 require((claim.isHostClaims && tx.origin == trip.guest) || tx.origin == trip.host, 'Guest or host.');
    require(claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel, 'Wrong Status.');
 }
 
}