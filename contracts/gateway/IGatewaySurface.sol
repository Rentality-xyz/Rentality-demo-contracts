// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './car/ICarGatewayFacet.sol';
import './car/ICarViewGatewayFacet.sol';
import './car/ICarViewGatewayFacet1.sol';
import './insurance/IInsuranceGatewayFacet.sol';
import './investment/IInvestmentGatewayFacet.sol';
import './payment/IPaymentGatewayFacet.sol';
import './pricing/IPricingGatewayFacet.sol';
import './profile/IProfileGatewayFacet.sol';
import './referral/IReferralGatewayFacet.sol';
import './trip/ITripGatewayFacet.sol';

/// @title IGatewaySurface
/// @notice Unified external Rentality gateway interface composed from gateway facets.
interface IGatewaySurface is
  ICarGatewayFacet,
  ICarViewGatewayFacet,
  ICarViewGatewayFacet1,
  IInsuranceGatewayFacet,
  IInvestmentGatewayFacet,
  IPaymentGatewayFacet,
  IPricingGatewayFacet,
  IProfileGatewayFacet,
  IReferralGatewayFacet,
  ITripGatewayFacet
{}
