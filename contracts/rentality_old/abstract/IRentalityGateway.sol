// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import '../../gateway/car/ICarGatewayFacet.sol';
import '../../gateway/car/ICarViewGatewayFacet.sol';
import '../../gateway/admin/IAdminGatewayFacet.sol';
import '../../gateway/claim/IClaimGatewayFacet.sol';
import '../../gateway/insurance/IInsuranceGatewayFacet.sol';
import '../../gateway/investment/IInvestmentGatewayFacet.sol';
import '../../gateway/payment/IPaymentGatewayFacet.sol';
import '../../gateway/profile/IProfileGatewayFacet.sol';
import '../../gateway/referral/IReferralGatewayFacet.sol';
import '../../gateway/trip/ITripGatewayFacet.sol';
/// @title RentalityGateway
/// @notice This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Gateway contract.
interface IRentalityGateway is
IAdminGatewayFacet,
ICarGatewayFacet,
ICarViewGatewayFacet,
IClaimGatewayFacet,
IInsuranceGatewayFacet,
IInvestmentGatewayFacet,
IPaymentGatewayFacet,
IProfileGatewayFacet,
IReferralGatewayFacet,
ITripGatewayFacet
  {

 
}






