// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Schemas.sol';
import './RentalityUserService.sol';
import './RentalityCarToken.sol';
import './payments/RentalityInsurance.sol';
import './features/RentalityClaimService.sol';
import './payments/RentalityPaymentService.sol';
import './payments/RentalityCurrencyConverter.sol';
import './libs/RentalityTripsQuery.sol';
import './libs/RentalityQuery.sol';
import './libs/RentalityViewLib.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import './RentalityGateway.sol';
import {RentalityTripsView, FunctionNotFound} from './RentalityTripsView.sol';
import {RentalityReferralProgram} from './features/refferalProgram/RentalityReferralProgram.sol';
import {RentalityPromoService} from './features/RentalityPromo.sol';
import {RentalityDimoService} from './features/RentalityDimoService.sol';

/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityTripsQuery doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityView is UUPSUpgradeable, Initializable {
  RentalityContract private addresses;
  using RentalityQuery for RentalityContract;
  using RentalityTripsQuery for RentalityContract;

  RentalityInsurance private insuranceService;
  RentalityTripsView private tripsView;

  RentalityReferralProgram private refferalService;

  RentalityPromoService private promoService;

    RentalityDimoService private dimoService;

  function updateServiceAddresses(
    RentalityContract memory contracts,
    address insurance,
    address tripsViewAddress,
    address promoServiceAddress,
    address dimoServiceAddress
  ) public {
    require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
    addresses = contracts;
    insuranceService = RentalityInsurance(insurance);
    tripsView = RentalityTripsView(tripsViewAddress);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);
  }

  fallback(bytes calldata data) external returns (bytes memory) {
    (bool ok_view, bytes memory res_view) = address(tripsView).call(data);
    bytes4 errorSign = 0x403e7fa6;
    if (!ok_view && bytes4(res_view) == errorSign) {
      revert FunctionNotFound();
    } else if (!ok_view) {
      assembly {
        revert(add(res_view, 32), mload(res_view))
      }
    }
    return res_view;
  }
  /// @notice Retrieves information about a car by its ID.
  /// @param carId The ID of the car.
  /// @return Car information as a struct.
  function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfoWithInsurance memory) {
    return
      Schemas.CarInfoWithInsurance(
        addresses.carService.getCarInfoById(carId),
        insuranceService.getCarInsuranceInfo(carId),
        addresses.carService.tokenURI(carId)
      );
  }

  /// @notice Retrieves the metadata URI of a car by its ID.
  /// @param carId The ID of the car.
  /// @return The metadata URI of the car.
  function getCarMetadataURI(uint256 carId) public view returns (string memory) {
    return addresses.carService.tokenURI(carId);
  }

  // not using
  /// @notice Retrieves information about all cars.
  /// @return An array of car information.
  // function getAllCars() public view returns (Schemas.CarInfo[] memory) {
  //   return addresses.carService.getAllCars();
  // }

  // not using
  /// @notice Retrieves information about available cars for a specific user.
  /// @param user The address of the user.
  /// @return An array of available car information for the specified user.
  function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
    return addresses.carService.getAvailableCarsForUser(user);
  }

  // /// @notice Searches for available cars based on specified criteria.
  // /// @param startDateTime The start date and time of the search.
  // /// @param endDateTime The end date and time of the search.
  // /// @param searchParams Additional search parameters.
  // /// @return An array of available car information meeting the search criteria.
  // function searchAvailableCars(
  //   uint64 startDateTime,
  //   uint64 endDateTime,
  //   Schemas.SearchCarParams memory searchParams
  // ) public view returns (Schemas.SearchCarWithDistance[] memory) {
  //   return
  //     addresses.searchSortedCars(
  //       tx.origin,
  //       startDateTime,
  //       endDateTime,
  //       searchParams,
  //       IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getLocationInfo(bytes32('')),
  //       IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getLocationInfo(bytes32('')),
  //       RentalityAdminGateway(addresses.adminService).getDeliveryServiceAddress(),
  //       address(insuranceService)
  //     );
  // }

  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) public view returns (Schemas.AvailableCarDTO memory) {
    return
      addresses.checkCarAvailabilityWithDelivery(
        carId,
        tx.origin,
        startDateTime,
        endDateTime,
        searchParams,
        pickUpInfo,
        returnInfo,
        addresses.adminService.getDeliveryServiceAddress(),
        address(insuranceService),
        address(dimoService)
      );
  }
  /// @notice Searches for available cars based on specified criteria.
  /// @param startDateTime The start date and time of the search.
  /// @param endDateTime The end date and time of the search.
  /// @param searchParams Additional search parameters.
  /// @param pickUpInfo Lat and lon of return and pickUp locations
  /// @param returnInfo Lat and lon of return and pickUp locations
  /// @return An array of available car information meeting the search criteria.
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  )
    public
    view
    returns (
      // bool useRefferalPoints
      Schemas.SearchCarWithDistance[] memory
    )
  {
    return
      addresses.searchSortedCars(
        tx.origin,
        startDateTime,
        endDateTime,
        searchParams,
        pickUpInfo,
        returnInfo,
        RentalityAdminGateway(addresses.adminService).getDeliveryServiceAddress(),
        address(insuranceService),
        address(dimoService)
      );
  }

  /// @notice Retrieves information about cars owned by the caller.
  /// @return An array of car information owned by the caller.
  function getMyCars() public view returns (Schemas.CarInfoDTO[] memory) {
    return RentalityUtils.getCarsOwnedByUserWithEditability(addresses, dimoService);
  }
function getDimoVihicles() public view returns(uint[] memory) {
  return dimoService.getDimoVihicles();
}
  /// @notice Retrieves detailed information about a car.
  /// @param carId The ID of the car for which details are requested.
  /// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
  function getCarDetails(uint carId) public view returns (Schemas.CarDetails memory) {
    return RentalityUtils.getCarDetails(addresses, carId, dimoService);
  }

  /// @notice Retrieves information about trips where the caller is the host.
  /// @return An array of trip information.
  // function getTripsAsHost() public view returns (Schemas.TripDTO[] memory) {
  // return RentalityTripsQuery.getTripsByHost(addresses, insuranceService, tx.origin);
  // }

  // not using
  /// @notice Retrieves information about trips for a specific car.
  /// @param carId The ID of the car.
  /// @return An array of trip information for the specified car.
  // function getTripsByCar(uint256 carId) public view returns (Schemas.Trip[] memory) {
  // return addresses.getTripsByCar(carId);
  // }

  /// @notice Retrieves all claims where the caller is the host.
  /// @dev The caller is assumed to be the host of the claims.
  /// @return An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAs(bool host) public view returns (Schemas.FullClaimInfo[] memory) {
    return addresses.getClaimsBy(host, tx.origin);
  }

  // not using
  /// @notice Gets detailed information about a specific claim.
  /// @dev Returns a structure containing information about the claim, associated trip, and car details.
  /// @param claimId ID of the claim.
  /// @return Full information about the claim.
  function getClaim(uint256 claimId) public view returns (Schemas.FullClaimInfo memory) {
    return RentalityUtils.getClaim(addresses, claimId);
  }

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
    return addresses.carService.getCarsOfHost(host);
  }
  /// @notice Get a discount.
  /// @param user The address of user discount.
  function getDiscount(address user) public view returns (Schemas.BaseDiscount memory) {
    return addresses.paymentService.getBaseDiscount(user);
  }

  /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @return calculatePaymentsDTO An object containing payment details.
  // function calculatePayments(
  //   uint carId,
  //   uint64 daysOfTrip,
  //   address currency
  // ) public view returns (Schemas.CalculatePaymentsDTO memory) {
  //   return RentalityUtils.calculatePayments(addresses, carId, daysOfTrip, currency, 0, insuranceService);
  // }

  /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @param pickUpLocation lat and lon of pickUp and return locations.
  /// @param returnLocation lat and lon of pickUp and return locations.
  /// @return calculatePaymentsDTO An object containing payment details.
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation,
    string memory promo
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    return
      RentalityUtils.calculatePaymentsWithDelivery(
        addresses,
        carId,
        daysOfTrip,
        currency,
        pickUpLocation,
        returnLocation,
        insuranceService,
        promo,
        promoService
      );
  }
  /// @notice Get chat information for trips hosted by the caller on the Rentality platform.
  /// @return chatInfo An array of chat information for trips hosted by the caller.
  function getChatInfoFor(bool host) public view returns (Schemas.ChatInfo[] memory) {
    return RentalityTripsQuery.populateChatInfo(addresses, insuranceService, tx.origin, host, promoService, dimoService);
  }

  /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(uint carId) public view returns (Schemas.DeliveryData memory) {
    return RentalityUtils.getDeliveryData(addresses, carId);
  }

  /// @dev Retrieves delivery data for a given user.
  /// @param user The user address for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getUserDeliveryPrices(address user) public view returns (Schemas.DeliveryPrices memory) {
    return RentalityCarDelivery(addresses.adminService.getDeliveryServiceAddress()).getUserDeliveryPrices(user);
  }

  /// @notice Retrieves the KYC commission amount.
  /// @dev Calls the `getKycCommission` function from the `userService` contract.
  /// @return The current KYC commission amount.
  function getKycCommission() public view returns (uint) {
    return addresses.userService.getKycCommission();
  }

  /// @notice Checks if the KYC commission has been paid by a user.
  /// @dev Calls the `isCommissionPaidForUser` function from the `userService` contract.
  /// @param user The address of the user to check.
  /// @return True if the KYC commission has been paid by the user, false otherwise.
  function isKycCommissionPaid(address user) public view returns (bool) {
    return addresses.userService.isCommissionPaidForUser(user);
  }
  function getMyFullKYCInfo() public view returns (Schemas.FullKYCInfoDTO memory) {
    return addresses.userService.getMyFullKYCInfo();
  }
  function getInsurancesBy(bool host) public view returns (Schemas.InsuranceDTO[] memory) {
    return RentalityTripsQuery.getTripInsurancesBy(host, addresses, insuranceService, tx.origin);
  }

  function calculateClaimValue(uint claimdId) public view returns (uint) {
    return RentalityViewLib.calculateClaimValue(addresses, claimdId);
  }

  function getMyInsurancesAsGuest() public view returns (Schemas.InsuranceInfo[] memory) {
    return insuranceService.getMyInsurancesAsGuest(tx.origin);
  }

  function getFilterInfo(uint64 duration) public view returns (Schemas.FilterInfoDTO memory) {
    return RentalityViewLib.getFilterInfo(addresses, duration);
  }
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime) public view returns (Schemas.CheckPromoDTO memory) {
    return promoService.checkPromo(promo, startDateTime, endDateTime);
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
    address tripsViewAddress,
    address refferalProgramAddress,
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
      this
    );
    insuranceService = RentalityInsurance(insuranceAddress);
    tripsView = RentalityTripsView(tripsViewAddress);
    tripsView.updateViewService(this);
    refferalService = RentalityReferralProgram(refferalProgramAddress);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);
  }

  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(addresses.userService.isAdmin(msg.sender), 'Only for Admin.');
  }
}
