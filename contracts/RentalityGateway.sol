// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
//deployed 27.06.2023 11:10 to sepolia at 0x18744A3f7D15930446B1dbc5A837562e468B2D8d

import './features/RentalityClaimService.sol';
import './abstract/IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './payments/RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './RentalityPlatform.sol';
import './payments/RentalityPaymentService.sol';
import './Schemas.sol';
import './RentalityAdminGateway.sol';
import './RentalityView.sol';

struct RentalityContract {
  RentalityCarToken carService;
  RentalityCurrencyConverter currencyConverterService;
  RentalityTripService tripService;
  RentalityUserService userService;
  RentalityPlatform rentalityPlatform;
  RentalityPaymentService paymentService;
  RentalityClaimService claimService;
  RentalityAdminGateway adminService;
  RentalityCarDelivery deliveryService;
  RentalityView viewService;
}

/// @title RentalityGateway
/// @notice The main gateway contract that connects various services in the Rentality platform.
/// Users can interact with the car service, trip service, user service, and payment service through this gateway.
/// Admins can update the addresses of connected services.
/// Hosts and guests can perform actions related to car rentals and trips.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityGateway is UUPSOwnable /*, IRentalityGateway*/ {
  RentalityContract private addresses;
  using RentalityQuery for RentalityContract;

  fallback(bytes calldata data) external payable returns (bytes memory) {
    require(msg.sender == tx.origin, 'Smart wallets not allowed now');
    (bool ok_view, bytes memory res_view) = address(addresses.viewService).call(data);
    bytes4 errorSign = 0x403e7fa6;

    if (!ok_view && bytes4(res_view) == errorSign) {
      (bool ok, bytes memory res) = address(addresses.rentalityPlatform).call{value: msg.value}(data);
      return _parseResult(ok, res);
    }
    return _parseResult(ok_view, res_view);
  }

  function _parseResult(bool flag, bytes memory result) internal pure returns (bytes memory) {
    if (!flag)
      assembly ('memory-safe') {
        revert(add(32, result), mload(result))
      }
    return result;
  }

  // @dev Updates the addresses of various services used in the Rentality platform.
  //
  // This function retrieves the actual service addresses from the `adminService` and updates
  // the contract's state variables with these addresses. The services include:
  // - Car Token Service
  // - Currency Converter Service
  // - Trip Service
  // - User Service
  // - Platform Service
  // - Payment Service
  // - Claim Service
  //
  //   This function should be called whenever the addresses of the services change.
  function updateServiceAddresses() public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = addresses.adminService.getRentalityContracts();
  }

  //  @dev Initializes the contract with the provided addresses for various services.
  //  @param carServiceAddress The address of the RentalityCarToken contract.
  //  @param currencyConverterServiceAddress The address of the RentalityCurrencyConverter contract.
  //  @param tripServiceAddress The address of the RentalityTripService contract.
  //  @param userServiceAddress The address of the RentalityUserService contract.
  //  @param rentalityPlatformAddress The address of the RentalityPlatform contract.
  //  @param paymentServiceAddress The address of the RentalityPaymentService contract.
  //  Requirements:
  //  - The contract must not have been initialized before.
  function initialize(
    address carServiceAddress,
    address currencyConverterServiceAddress,
    address tripServiceAddress,
    address userServiceAddress,
    address rentalityPlatformAddress,
    address paymentServiceAddress,
    address claimServiceAddress,
    address rentalityAdminGatewayAddress,
    address deliveryServiceAddress,
    address viewService
  ) public initializer {
    addresses = RentalityContract(
      RentalityCarToken(carServiceAddress),
      RentalityCurrencyConverter(currencyConverterServiceAddress),
      RentalityTripService(tripServiceAddress),
      RentalityUserService(userServiceAddress),
      RentalityPlatform(rentalityPlatformAddress),
      RentalityPaymentService(payable(paymentServiceAddress)),
      RentalityClaimService(claimServiceAddress),
      RentalityAdminGateway(rentalityAdminGatewayAddress),
      RentalityCarDelivery(deliveryServiceAddress),
      RentalityView(viewService)
    );

    __Ownable_init();
  }
}
