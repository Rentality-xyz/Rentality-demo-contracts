// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



//deployed 26.05.2023 11:15 to sepolia at 0x12fB29Ed1f0E17605f488F640D49De29050cf855
//deployed 27.06.2023 11:10 to sepolia at 0x18744A3f7D15930446B1dbc5A837562e468B2D8d

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import './features/RentalityClaimService.sol';
import './abstract/IRentalityGateway.sol';
import './RentalityCarToken.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';
import './payments/RentalityPaymentService.sol';
import './Schemas.sol';
import './RentalityAdminGateway.sol';
import {RentalityCurrencyConverter} from './payments/RentalityCurrencyConverter.sol';
import {RentalityPlatform} from './RentalityPlatform.sol';
import {RentalityCarDelivery} from './features/RentalityCarDelivery.sol';
import {RentalityView} from './RentalityView.sol';
import {UUPSOwnable} from './proxy/UUPSOwnable.sol';
import {RentalityQuery} from './libs/RentalityQuery.sol';
import {LibDiamond} from './libs/LibDiamond.sol';

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
contract RentalityGateway is UUPSOwnable /*, IRentalityGateway*/, ReentrancyGuardUpgradeable {
  address private l0Sender;
  using RentalityQuery for RentalityContract;

  fallback(bytes calldata data) external payable nonReentrant returns (bytes memory) {
     bytes memory dataToSend;
      LibDiamond.DiamondStorage storage ds;
      bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
      address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    if(l0Sender == msg.sender) {
      (bytes memory crossChainData, address user, bytes32 eid) = abi.decode(data, (bytes, address, bytes32));
      bytes4 selector;
      assembly {
        selector := mload(add(crossChainData, 32))
      }
      facet = ds.selectorToFacetAndPosition[selector].facetAddress;
      dataToSend = _forward(crossChainData, user);
    }
    else {
      dataToSend = _forward(data, msg.sender);

    }
    if(address(facet) == address(0)) {
      revert("Function does not exist");
    }

    (bool ok, bytes memory res) = address(facet).call{value: msg.value}(dataToSend);
    return _parseResult(ok, res);
  }

  function _parseResult(bool flag, bytes memory result) internal pure returns (bytes memory) {
    if (!flag)
      assembly ('memory-safe') {
        revert(add(32, result), mload(result))
      }
    return result;
  }

  function _forward(bytes memory data, address user) private view returns (bytes memory result) {
    result = abi.encodePacked(data, user);
  }

  function setLayerZeroSender(address _layer0Sender) public onlyOwner {
    l0Sender = _layer0Sender;
  }

  function diamondCut(LibDiamond.FacetCut[] memory _diamondCut) public onlyOwner {
    LibDiamond.diamondCut(_diamondCut);
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
LibDiamond.FacetCut[] memory _diamondCut
  ) public initializer {
  LibDiamond.diamondCut(_diamondCut);
    __Ownable_init();
     __ReentrancyGuard_init();
  }
}
