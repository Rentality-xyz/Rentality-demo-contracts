// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './payments/RentalityPaymentService.sol';
import './RentalityPlatform.sol';
import './abstract/IRentalityAdminGateway.sol';
import {RentalityContract, RentalityGateway} from './RentalityGateway.sol';
import './Schemas.sol';
import {RentalityInvestment} from './investment/RentalityInvestment.sol';
import './features/refferalProgram/RentalityReferralProgram.sol';
import {RentalityReferralProgram} from './features/refferalProgram/RentalityReferralProgram.sol';
import {RentalityPromoService} from './features/RentalityPromo.sol';
import {RentalityViewLib} from './libs/RentalityViewLib.sol';
import {RentalityDimoService} from './features/RentalityDimoService.sol';

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityAdminGateway is UUPSOwnable, IRentalityAdminGateway {
  RentalityCarToken private carService;
  RentalityCurrencyConverter private currencyConverterService;
  RentalityTripService private tripService;
  RentalityUserService private userService;
  RentalityPlatform private rentalityPlatform;
  RentalityPaymentService private paymentService;
  RentalityClaimService private claimService;
  RentalityCarDelivery private deliveryService;
  RentalityView private viewService;
  RentalityInsurance private insuranceService;
  RentalityReferralProgram private refferalProgram;
  RentalityPromoService private promoService;
  RentalityDimoService private dimoService;
  RentalityInvestment private investment;

  /// @notice Ensures that the caller is either an admin, the contract owner, or an admin from the origin transaction.
  modifier onlyAdmin() {
    require(
      userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) || (tx.origin == owner()),
      'User is not an admin'
    );
    _;
  }
  function getRentalityContracts() public view returns (RentalityContract memory) {
    return
      RentalityContract(
        carService,
        currencyConverterService,
        tripService,
        userService,
        rentalityPlatform,
        paymentService,
        claimService,
        RentalityAdminGateway(this),
        deliveryService,
        viewService
      );
  }
  function getPromoService() public view returns (RentalityPromoService) {
    return promoService;
  }
  function setPromoService(address promoServiceAddress) public onlyAdmin {
    promoService = RentalityPromoService(promoServiceAddress);
  }

function updateDimoService(address dimoServiceAddress) public onlyAdmin {
    dimoService = RentalityDimoService(dimoServiceAddress);
}
  function getDimoService() public view returns (RentalityDimoService) {
    return dimoService;
  }
  function getInsuranceService() public view returns (RentalityInsurance) {
    return insuranceService;
  }

  function setInsuranceService(address insurance) public onlyAdmin {
    insuranceService = RentalityInsurance(insurance);
  }

  function updateInvestmentAddress(address investmentAddress) public onlyAdmin {
    investment = RentalityInvestment(investmentAddress);
  }

  function getInvestmentAddress() public view returns (address) {
    return address(investment);
  }
  /// @notice Retrieves the address of the RentalityCarToken contract.
  /// @return The address of the RentalityCarToken contract.
  function getCarServiceAddress() public view returns (address) {
    return address(carService);
  }

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCarToken contract.
  function updateCarService(address contractAddress) public onlyAdmin {
    carService = RentalityCarToken(contractAddress);
  }
  /// @notice Retrieves the address of the RentalityPayment contract.
  /// @return The address of the RentalityPayment contract.
  function getPaymentService() public view returns (address) {
    return address(paymentService);
  }

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPayment contract.
  function updatePaymentService(address contractAddress) public onlyAdmin {
    paymentService = RentalityPaymentService(payable(contractAddress));
  }
  /// @notice Retrieves the address of the RentalityClaim contract.
  /// @return The address of the RentalityClaim contract.
  function getClaimServiceAddress() public view returns (address) {
    return address(claimService);
  }

  /// @notice Updates the address of the RentalityClaim contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityClaim contract.
  function updateClaimService(address contractAddress) public onlyAdmin {
    claimService = RentalityClaimService(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityPlatform contract.
  /// @return The address of the RentalityPlatform contract.
  function getRentalityPlatformAddress() public view returns (address) {
    return address(rentalityPlatform);
  }

  /// @notice Updates the address of the RentalityPlatform contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPlatform contract.
  function updateRentalityPlatform(address contractAddress) public onlyAdmin {
    rentalityPlatform = RentalityPlatform(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityCurrencyConverter contract.
  /// @return The address of the RentalityCurrencyConverter contract.
  function getCurrencyConverterServiceAddress() public view returns (address) {
    return address(currencyConverterService);
  }

  /// @notice Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCurrencyConverter contract.
  function updateCurrencyConverterService(address contractAddress) public onlyAdmin {
    currencyConverterService = RentalityCurrencyConverter(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityTripService contract.
  /// @return The address of the RentalityTripService contract.
  function getTripServiceAddress() public view returns (address) {
    return address(tripService);
  }

  /// @notice Updates the address of the RentalityTripService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityTripService contract.
  function updateTripService(address contractAddress) public onlyAdmin {
    tripService = RentalityTripService(contractAddress);
  }

  /// @notice Retrieves the address of the RentalityUserService contract.
  /// @return The address of the RentalityUserService contract.
  function getUserServiceAddress() public view returns (address) {
    return address(userService);
  }

  /// @notice Updates the address of the RentalityUserService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityUserService contract.
  function updateUserService(address contractAddress) public onlyAdmin {
    userService = RentalityUserService(contractAddress);
  }

  /// @notice Updates the address of the GeoService contract.
  /// @param newGeoServiceAddress The new address of the GeoService contract.
  function updateGeoServiceAddress(address newGeoServiceAddress) public onlyAdmin {
    carService.updateGeoServiceAddress(newGeoServiceAddress);
  }

  /// @notice Retrieves the address of the RentalityCarDelivery contract.
  /// @return The address of the RentalityCarDelivery contract.
  function getDeliveryServiceAddress() public view returns (address) {
    return address(deliveryService);
  }

  /// @notice Updates the address of the RentalityCarDelivery contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCarDeliveryn contract.
  function updateDeliveryService(address contractAddress) public onlyAdmin {
    deliveryService = RentalityCarDelivery(contractAddress);
  }
  /// @notice Retrieves the address of the RentalityRefferalProgram contract.
  /// @return The address of the RentalityRefferalProgram contract.
  function getRefferalServiceAddress() public view returns (RentalityReferralProgram) {
    return RentalityReferralProgram(refferalProgram);
  }
  /// @notice Updates the address of the RentalityReferralProgram contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityReferralProgram contract.
  function updateRefferalProgramService(address contractAddress) public onlyAdmin {
    refferalProgram = RentalityReferralProgram(contractAddress);
  }

  /// @notice Withdraws the specified amount from the RentalityPlatform contract.
  /// @param amount The amount to withdraw.
  /// @param tokenAddress one of available on Rentality currency
  function withdrawFromPlatform(uint256 amount, address tokenAddress) public {
    paymentService.withdrawFromPlatform(amount, tokenAddress);
  }

  /// @notice Withdraws the entire balance from the RentalityPlatform contract.
  /// @param tokenAddress one of available on Rentality currency
  function withdrawAllFromPlatform(address tokenAddress) public {
    uint balance = currencyConverterService.isETH(tokenAddress)
      ? address(paymentService).balance
      : IERC20(tokenAddress).balanceOf(address(paymentService));

    paymentService.withdrawFromPlatform(balance, tokenAddress);
  }
  /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
  /// @param valueInPPM The new platform fee value in PPM.
  function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
    paymentService.setPlatformFeeInPPM(valueInPPM);
  }

  function updatePromoData(string memory prefix, uint discount) public {
    promoService.addPrefix(prefix, discount);
  }

  /// @dev Sets the waiting time, only callable by administrators.
  /// @param timeInSec, set old value to this
  function setClaimsWaitingTime(uint timeInSec) public {
    claimService.setWaitingTime(timeInSec);
  }

  /// @dev get waiting time to approval
  /// @return waiting time to approval in sec
  function getClaimWaitingTime() public view returns (uint) {
    return claimService.getWaitingTime();
  }

  /// @notice Retrieves the platform fee in parts per million (PPM).
  /// @return The platform fee in PPM.
  function getPlatformFeeInPPM() public view returns (uint32) {
    return paymentService.getPlatformFeeInPPM();
  }

  /// @notice Retrieves the platform fee calculated from the given value.
  /// @param value The value from which to calculate the platform fee.
  /// @return The calculated platform fee.
  function getPlatformFeeFrom(uint256 value) private view returns (uint256) {
    return paymentService.getPlatformFeeFrom(value);
  }

  /// @notice Calculates the total cost with applied discount for a trip.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The original value of the trip.
  /// @param user the address of discount provider
  /// @return The total cost after applying the discount.
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return paymentService.calculateSumWithDiscount(user, daysOfTrip, value);
  }

  /// @notice Calculates the taxes for a trip based on the specified tax ID.
  /// @param taxesId The ID of the taxes contract.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The original value of the trip.
  /// @return The total taxes for the trip.
  function calculateTaxes(uint taxesId, uint64 daysOfTrip, uint64 value) public view returns (uint64, uint64) {
    return paymentService.calculateTaxes(taxesId, daysOfTrip, value);
  }

  /// @notice Confirms check-out for a trip.
  /// @param tripId The ID of the trip.
  function payToHost(uint256 tripId) public {
    rentalityPlatform.confirmCheckOut(tripId);
  }

  /// @notice Rejects a trip request. Only callable by hosts.
  /// @param tripId The ID of the trip to reject.
  function refundToGuest(uint256 tripId) public {
    return rentalityPlatform.rejectTripRequest(tripId);
  }
  /// @dev Sets the Civic verifier and gatekeeper network for identity verification.
  /// @param _civicVerifier The address of the Civic verifier contract.
  /// @param _civicGatekeeperNetwork The identifier of the Civic gatekeeper network.
  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) public {
    userService.setCivicData(_civicVerifier, _civicGatekeeperNetwork);
  }

  // @notice Sets the platform fee that will be charged for each transaction.
  /// @dev This function can only be called by an admin.
  /// @param value The new platform fee value.
  function setPlatformFee(uint value) public {
    claimService.setPlatformFee(value);
  }

  // @notice Sets the commission for the KYC (Know Your Customer) process.
  /// @dev This function can only be called by an admin.
  /// @param value The new KYC commission value.
  function setKycCommission(uint value) public {
    userService.setKycCommission(value);
  }

  // @notice Retrieves the current KYC commission value.
  /// @return The current KYC commission as a uint.
  function getKycCommission() public view returns (uint) {
    return userService.getKycCommission();
  }

  // @notice Retrieves all trips based on the provided filter and pagination.
  /// @param filter The filter to apply to the trips.
  /// @param page The current page number.
  /// @param itemsPerPage The number of items per page.
  /// @return A structure containing the filtered trips and total page count.
  function getAllTrips(
    Schemas.TripFilter memory filter,
    uint page,
    uint itemsPerPage
  ) public view returns (Schemas.AllTripsDTO memory) {
    return RentalityViewLib.getAllTrips(getRentalityContracts(), filter,promoService, page, itemsPerPage);
  }

  // @notice Manages user roles by granting or revoking specific roles.
  /// @dev This function can only be called by an admin.
  /// @param role The role to manage.
  /// @param user The address of the user whose role is being managed.
  /// @param grant If true, the role is granted; if false, the role is revoked.
  function manageRole(Schemas.Role role, address user, bool grant /*revoke if false*/) public {
    userService.manageRole(role, user, grant);
  }

  // @notice Retrieves all cars based on the pagination parameters.
  /// @param page The current page number.
  /// @param itemsPerPage The number of items per page.
  /// @return A structure containing the cars on the current page and total page count.
  function getAllCars(uint page, uint itemsPerPage) public view returns (Schemas.AllCarsDTO memory) {
    uint totalCarsAmount = carService.totalSupply();

    uint totalPageCount = (totalCarsAmount + itemsPerPage - 1) / itemsPerPage;

    if (page > totalPageCount) {
      page = totalPageCount;
    }

    uint startIndex = (page - 1) * itemsPerPage + 1;
    uint endIndex = startIndex + itemsPerPage - 1;

    if (endIndex > totalCarsAmount) {
      endIndex = totalCarsAmount;
    }
    RentalityContract memory contracts = getRentalityContracts();

    Schemas.AdminCarDTO[] memory cars = new Schemas.AdminCarDTO[](endIndex - startIndex + 1);
    for (uint i = startIndex; i <= endIndex; i++) {
      cars[i - startIndex].car = RentalityUtils.getCarDetails(contracts, i, dimoService);
      cars[i - startIndex].carMetadataURI = contracts.carService.tokenURI(i);
    }
    return Schemas.AllCarsDTO(cars, totalPageCount);
  }

  function manageRefferalBonusAccrual(
    Schemas.RefferalAccrualType accrualType,
    Schemas.RefferalProgram program,
    int points,
    int pointsWithReffHash
  ) public {
    require(userService.isAdmin(msg.sender), 'only Admin');
    if (Schemas.RefferalAccrualType.OneTime == accrualType)
      refferalProgram.addOneTimeProgram(program, points, pointsWithReffHash, bytes4(''));
    else refferalProgram.addPermanentProgram(program, points, bytes4(''));
  }
  function manageRefferalHashPoints(Schemas.RefferalProgram program, uint points) public {
    require(userService.isAdmin(msg.sender), 'only Admin');
    refferalProgram.manageRefHashesProgram(program, points);
  }

  function manageRefferalDiscount(
    Schemas.RefferalProgram program,
    Schemas.Tear tear,
    uint points,
    uint percents
  ) public {
    require(userService.isAdmin(msg.sender), 'only Admin');
    refferalProgram.manageRefferalDiscount(program, tear, points, percents);
  }

  function manageTearInfo(Schemas.Tear tear, uint from, uint to) public {
    require(userService.isAdmin(msg.sender), 'only Admin');
    refferalProgram.manageTearInfo(tear, from, to);
  }
  function getRefferalPointsInfo() public view returns (Schemas.AllRefferalInfoDTO memory) {
    return refferalProgram.getRefferalPointsInfo();
  }
  function getPlatformUsersInfo() public view returns(Schemas.AdminKYCInfoDTO[] memory result) {
    return userService.getPlatformUsersKYCInfos();
  }

  ///------------------------------------
  /// NOT USING IN FRONT
  ///------------------------------------
  // @notice Sets a new message for the Terms and Conditions (TC) and updates the corresponding hashed message.
  /// @dev This function can only be called by an admin.
  /// @param message The new message for the TC.
  // function setNewTCMessage(string memory message) public {
  //   userService.setNewTCMessage(message);
  // }

  /// @notice Adds currency to list of available on Rentality,
  /// by providing ERC20 token address, and corresponding Rentality service for calculation.
  // function addCurrency(address tokenAddress, address rentalityTokenService) public onlyAdmin {
  //   currencyConverterService.addCurrencyType(tokenAddress, rentalityTokenService);
  // }

  /// @notice Adds a new taxes contract to the payment service.
  /// param taxesContactAddress The address of the taxes contract to add.
  // function addTaxesContract(address taxesContactAddress) public {
  //   paymentService.addTaxesContract(taxesContactAddress);
  // }

  /// @notice Adds a new discount contract to the payment service.
  /// param discountContactAddress The address of the discount contract to add.
  // function addDiscountContract(address discountContactAddress) public {
  //   paymentService.addDiscountContract(discountContactAddress);
  // }
  /// @notice Changes the current discount contract used by the payment service.
  /// param discountContract The address of the new discount contract.
  // function changeCurrentDiscountType(address discountContract) public {
  // paymentService.changeCurrentDiscountType(discountContract);
  // }

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
    address carDeliveryAddress,
    address viewServiceAddress,
    address insuranceServiceAddress,
    address rentalityTripsViewAddress,
    address refferalProgramAddress,
    address promoServiceAddress,
    address dimoServiceAddress,
    address investmentAddress
  ) public initializer {
    carService = RentalityCarToken(carServiceAddress);
    currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
    tripService = RentalityTripService(tripServiceAddress);
    userService = RentalityUserService(userServiceAddress);
    rentalityPlatform = RentalityPlatform(rentalityPlatformAddress);
    paymentService = RentalityPaymentService(payable(paymentServiceAddress));
    claimService = RentalityClaimService(claimServiceAddress);
    deliveryService = RentalityCarDelivery(carDeliveryAddress);
    viewService = RentalityView(viewServiceAddress);
    promoService = RentalityPromoService(promoServiceAddress);
    dimoService = RentalityDimoService(dimoServiceAddress);

    viewService.updateServiceAddresses(
      getRentalityContracts(),
      insuranceServiceAddress,
      rentalityTripsViewAddress,
      promoServiceAddress,
      address(dimoService)
);
    refferalProgram = RentalityReferralProgram(refferalProgramAddress);
    insuranceService = RentalityInsurance(insuranceServiceAddress);
    investment = RentalityInvestment(investmentAddress);
    __Ownable_init();
  }
}
