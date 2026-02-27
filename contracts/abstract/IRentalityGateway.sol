// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '../RentalityCarToken.sol';
import '../RentalityTripService.sol';
import '../Schemas.sol';
import {IRentalityInvestmentFacet} from './facets/IRentalityInvestmentFacet.sol';
import {IRentalityPlatformFacet} from './facets/IRentalityPlatformFacet.sol';
import {IRentalityPlatformHelperFacet} from './facets/IRentalityPlatformHelperFacet.sol';
import {IRentalityReferralProgramFacet} from './facets/IRentalityReferralProgramFacet.sol';
import {IRentalityTripsViewFacet} from './facets/IRentalityTripsViewFacet.sol';
import {IRentalityViewFacet} from './facets/IRentalityViewFacet.sol';
/// @title RentalityGateway
/// @notice This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Gateway contract.
interface IRentalityGateway is
 IRentalityViewFacet,
IRentalityInvestmentFacet,
IRentalityPlatformFacet,
IRentalityPlatformHelperFacet,
IRentalityReferralProgramFacet,
IRentalityTripsViewFacet
  {

 
}

