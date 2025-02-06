// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Schemas.sol';
import './RentalityUserService.sol';
import './RentalityCarToken.sol';
import './payments/RentalityInsurance.sol';
import './features/RentalityClaimService.sol';
import './payments/RentalityCurrencyConverter.sol';
import './libs/RentalityTripsQuery.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import './libs/RentalityTripsQuery.sol';
import {RentalityView} from './RentalityView.sol';
import {RentalityDimoService} from './features/RentalityDimoService.sol';

error FunctionNotFound();
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityTripsQuery doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityTripsView is UUPSUpgradeable, Initializable {
  RentalityContract private addresses;
  using RentalityTripsQuery for RentalityContract;

  RentalityInsurance private insuranceService;
  RentalityPromoService private promoService;
  RentalityDimoService private dimoService;

  function updateServiceAddresses(
    RentalityContract memory contracts,
     address insurance,
      address promoServiceAddress,
      address dimoServiceAddress
      ) public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = contracts;
    insuranceService = RentalityInsurance(insurance);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);
  }
  fallback(bytes calldata) external returns (bytes memory) {
    revert FunctionNotFound();
  }

  /// @notice Get contact information for a specific trip on the Rentality platform.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  //// Refactoring for getTripContactInfo with RentalityContract
  function getTripContactInfo(
    uint256 tripId
  ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    return
      RentalityTripsQuery.getTripContactInfo(tripId, address(addresses.tripService), address(addresses.userService), tx.origin);
  }

  /// @notice Retrieves information about a trip by ID.
  /// @param tripId The ID of the trip.
  /// @return Trip information.
  function getTrip(uint256 tripId) public view returns (Schemas.TripDTO memory) {
    return RentalityTripsQuery.getTripDTO(addresses, insuranceService, tripId, promoService, dimoService);
  }

  /// @notice Retrieves information about trips where the caller is the guest.
  /// @return An array of trip information.
  function getTripsAs(bool host) public view returns (Schemas.TripDTO[] memory) {
    return RentalityTripsQuery.getTripsAs(addresses, insuranceService, tx.origin, host, promoService, dimoService);
  }

  /// @notice Calculates the KYC commission in a specific currency based on the current exchange rate.
  /// @dev This function uses the currency converter service to calculate the commission in the specified currency.
  /// @param currency The address of the currency in which the commission should be calculated.
  /// @return The KYC commission amount in the specified currency.
  function calculateKycCommission(address currency) public view returns (uint) {
    (uint result, , ) = addresses.currencyConverterService.getFromUsdLatest(
      currency,
      addresses.userService.getKycCommission()
    );

    return result;
  }

  function updateViewService(RentalityView viewService) public {
    require(addresses.userService.isAdmin(tx.origin), 'Only admin');
    addresses.viewService = viewService;
  }

  function initialize(
    address carServiceAddress,
    address currencyConverterServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address paymentServiceAddress,
    address claimServiceAddress,
    address carDeliveryAddress,
    address insuranceAddress,
    address promoServiceAddress,
    address dimoServiceAddress
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(address(0)),
      RentalityPaymentService(payable(paymentServiceAddress)),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(address(0)),
      RentalityCarDelivery(carDeliveryAddress),
      RentalityView(address(0))
    );
    insuranceService = RentalityInsurance(insuranceAddress);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);
  }

  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(addresses.userService.isAdmin(msg.sender), 'Only for Admin.');
  }
}