// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';
import '../insurance/RentalInsuranceTypes.sol';

interface IRentalClaimMainClaimService {
  function createClaim(Schemas.CreateClaimRequest memory request, address host, address guest, address user) external returns (uint256);
  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory);
  function rejectClaim(uint256 claimId, address rejectedBy, address host, address guest) external;
  function payClaim(uint256 claimId, address host, address guest, int256 rate, uint8 decimals) external;
  function getPlatformFeeFrom(uint256 value) external view returns (uint256);
  function claimTypeExists(uint8 claimType, bool forHost) external view returns (bool);
}

interface IRentalClaimMainTripService {
  function getTrip(uint256 tripId) external view returns (Schemas.Trip memory);
}

interface IRentalClaimMainCurrencyConverter {
  function calculateLatestValueWithFee(address currencyType, uint256 valueInUsdCents, uint256 feeInUsdCents)
    external
    view
    returns (uint256 valueToPay, uint256 feeInCurrency, int256 rate, uint8 decimals);
}

interface IRentalClaimMainPaymentService {
  function payClaim(
    Schemas.Trip memory trip,
    uint256 valueToPay,
    uint256 feeInCurrency,
    uint256 commission,
    address user
  ) external payable;
}

interface IRentalClaimMainInsuranceMain {
  function createInsuranceClaim(uint256 claimId, address sender) external;
  function isInsuranceClaim(uint256 claimId) external view returns (bool);
  function payHostInsuranceClaim(uint256 amountToPay, RentalHostInsurancePayoutContext memory context) external payable;
}

contract RentalClaimMain {
  IRentalClaimMainClaimService public immutable claimService;
  IRentalClaimMainTripService public immutable tripService;
  IRentalClaimMainCurrencyConverter public immutable currencyConverter;
  IRentalClaimMainPaymentService public immutable paymentService;
  IRentalClaimMainInsuranceMain public immutable insuranceMain;

  constructor(
    address claimServiceAddress,
    address tripServiceAddress,
    address currencyConverterAddress,
    address paymentServiceAddress,
    address insuranceMainAddress
  ) {
    claimService = IRentalClaimMainClaimService(claimServiceAddress);
    tripService = IRentalClaimMainTripService(tripServiceAddress);
    currencyConverter = IRentalClaimMainCurrencyConverter(currencyConverterAddress);
    paymentService = IRentalClaimMainPaymentService(paymentServiceAddress);
    insuranceMain = IRentalClaimMainInsuranceMain(insuranceMainAddress);
  }

  function createClaim(Schemas.CreateClaimRequest memory request, bool isInsuranceClaim, address sender)
    external
    returns (uint256 claimId)
  {
    Schemas.Trip memory trip = tripService.getTrip(request.tripId);
    require(!isInsuranceClaim || trip.host == sender, 'RentalClaimMain: insurance claim only for hosts');
    require(
      (trip.host == sender && claimService.claimTypeExists(request.claimType, true)) ||
        (trip.guest == sender && claimService.claimTypeExists(request.claimType, false)),
      'Only for trip host or guest, or wrong claim type.'
    );
    require(
      trip.status != Schemas.TripStatus.Canceled && trip.status != Schemas.TripStatus.Created,
      'Wrong trip status.'
    );

    claimId = claimService.createClaim(request, trip.host, trip.guest, sender);
    if (isInsuranceClaim) {
      insuranceMain.createInsuranceClaim(claimId, sender);
    }
  }

  function rejectClaim(uint256 claimId, address sender) external {
    Schemas.ClaimV2 memory claim = claimService.getClaim(claimId);
    Schemas.Trip memory trip = tripService.getTrip(claim.tripId);
    require(trip.host == sender || trip.guest == sender, 'For trip guest or host.');

    claimService.rejectClaim(claimId, sender, trip.host, trip.guest);
  }

  function payClaim(uint256 claimId, address sender) external payable {
    Schemas.ClaimV2 memory claim = claimService.getClaim(claimId);
    Schemas.Trip memory trip = tripService.getTrip(claim.tripId);
    uint256 commission = claimService.getPlatformFeeFrom(claim.amountInUsdCents);

    (uint256 valueToPay, uint256 feeInCurrency, int256 rate, uint8 decimals) = currencyConverter.calculateLatestValueWithFee(
      trip.paymentInfo.currencyType,
      claim.amountInUsdCents,
      commission
    );

    claimService.payClaim(claimId, trip.host, trip.guest, rate, decimals);

    if (!insuranceMain.isInsuranceClaim(claimId) || trip.guest == sender) {
      paymentService.payClaim{value: msg.value}(trip, valueToPay, feeInCurrency, commission, sender);
      return;
    }

    insuranceMain.payHostInsuranceClaim{value: msg.value}(
      valueToPay,
      RentalHostInsurancePayoutContext({host: trip.host, currencyType: trip.paymentInfo.currencyType, tripId: trip.tripId})
    );
  }
}
