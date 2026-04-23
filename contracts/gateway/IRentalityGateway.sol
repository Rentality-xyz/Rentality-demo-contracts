// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './admin/IAdminGatewayFacet.sol';
import './car/ICarGatewayFacet.sol';
import './car/ICarViewGatewayFacet.sol';
import './car/ICarViewGatewayFacet1.sol';
import './claim/IClaimGatewayFacet.sol';
import './insurance/IInsuranceGatewayFacet.sol';
import './investment/IInvestmentGatewayFacet.sol';
import './payment/IPaymentGatewayFacet.sol';
import './profile/IProfileGatewayFacet.sol';
import './referral/IReferralGatewayFacet.sol';
import './trip/ITripGatewayFacet.sol';

/// @title IRentalityGateway
/// @notice Unified external Rentality gateway interface composed from gateway facets.
interface IRentalityGateway is
  IAdminGatewayFacet,
  ICarGatewayFacet,
  ICarViewGatewayFacet,
  ICarViewGatewayFacet1,
  IClaimGatewayFacet,
  IInsuranceGatewayFacet,
  IInvestmentGatewayFacet,
  IPaymentGatewayFacet,
  IProfileGatewayFacet,
  IReferralGatewayFacet,
  ITripGatewayFacet
{}
